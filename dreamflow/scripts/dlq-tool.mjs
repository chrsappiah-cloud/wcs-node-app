import { Queue, Job } from 'bullmq';
import { appendFileSync, mkdirSync, realpathSync } from 'node:fs';
import { basename, dirname, relative, resolve } from 'node:path';

const redisConnection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379', 10)
};

function canonicalizePath(pathValue) {
  const absolutePath = resolve(pathValue);
  const directory = dirname(absolutePath);

  try {
    const canonicalDir = realpathSync.native(directory);
    return resolve(canonicalDir, basename(absolutePath));
  } catch {
    return absolutePath;
  }
}

function displayPath(pathValue) {
  const rel = relative(process.cwd(), pathValue);
  if (!rel || rel === '') {
    return '.';
  }
  if (rel.startsWith('..')) {
    return pathValue;
  }
  return rel;
}

function parseArgs(argv) {
  const args = {
    command: 'list',
    id: null,
    limit: 25,
    remove: false,
    archive: false,
    archivePath: canonicalizePath(resolve(process.cwd(), '.runtime/dlq-archive.ndjson')),
    olderThanMinutes: 60
  };

  let startIndex = 0;
  if (argv[0] && !argv[0].startsWith('--')) {
    args.command = argv[0];
    startIndex = 1;
  }

  for (let i = startIndex; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--id') {
      args.id = argv[i + 1];
      i += 1;
      continue;
    }
    if (token === '--limit') {
      args.limit = parseInt(argv[i + 1], 10);
      i += 1;
      continue;
    }
    if (token === '--remove') {
      args.remove = true;
      continue;
    }
    if (token === '--archive') {
      args.archive = true;
      continue;
    }
    if (token === '--archive-path') {
      args.archivePath = canonicalizePath(argv[i + 1]);
      i += 1;
      continue;
    }
    if (token === '--older-than-minutes') {
      args.olderThanMinutes = parseInt(argv[i + 1], 10);
      i += 1;
    }
  }

  return args;
}

function printUsage() {
  console.log('DLQ tool usage:');
  console.log('  node scripts/dlq-tool.mjs list --limit 25');
  console.log('  node scripts/dlq-tool.mjs inspect --id <jobId>');
  console.log('  node scripts/dlq-tool.mjs replay --id <jobId> [--remove] [--archive] [--archive-path <path>]');
  console.log('  node scripts/dlq-tool.mjs replay-all --limit 10 [--remove] [--archive] [--archive-path <path>]');
  console.log('  node scripts/dlq-tool.mjs purge --limit 100 [--archive] [--archive-path <path>]');
  console.log('  node scripts/dlq-tool.mjs retain --older-than-minutes 60 --limit 100 [--remove] [--archive-path <path>]');
}

function summarize(job) {
  return {
    id: job.id,
    name: job.name,
    sourceQueue: job.data?.sourceQueue,
    originalJobId: job.data?.originalJobId,
    attemptsMade: job.data?.attemptsMade,
    maxAttempts: job.data?.maxAttempts,
    failedReason: job.data?.failedReason,
    deadLetteredAt: job.data?.deadLetteredAt
  };
}

async function replayJob(job, removeAfterReplay) {
  const sourceQueueName = job.data?.sourceQueue;
  if (!sourceQueueName) {
    throw new Error(`DLQ job ${job.id} is missing sourceQueue`);
  }

  const sourceQueue = new Queue(sourceQueueName, { connection: redisConnection });
  try {
    const replayedJob = await sourceQueue.add(
      job.data.originalJobName || `replayed-${sourceQueueName}`,
      job.data.payload,
      {
        attempts: job.data.maxAttempts || 3,
        backoff: { type: 'exponential', delay: 500 },
        removeOnComplete: true,
        removeOnFail: false
      }
    );

    if (removeAfterReplay) {
      await job.remove();
    }

    return replayedJob;
  } finally {
    await sourceQueue.close();
  }
}

function parseDeadLetteredAtMs(job) {
  const timestamp = job.data?.deadLetteredAt || job.timestamp;
  const ms = new Date(timestamp).getTime();
  return Number.isNaN(ms) ? 0 : ms;
}

function archiveJobs(jobs, archivePath, reason) {
  if (!jobs.length) {
    return;
  }

  mkdirSync(dirname(archivePath), { recursive: true });

  const archivedAt = new Date().toISOString();
  for (const job of jobs) {
    const line = JSON.stringify({
      archivedAt,
      reason,
      dlq: summarize(job),
      payload: job.data?.payload,
      rawData: job.data
    });
    appendFileSync(archivePath, `${line}\n`);
  }
}

async function run() {
  const args = parseArgs(process.argv.slice(2));
  const dlq = new Queue('dead-letter', { connection: redisConnection });

  try {
    await dlq.waitUntilReady();

    if (args.command === 'list') {
      const jobs = await dlq.getJobs(['wait', 'delayed', 'active', 'failed', 'completed'], 0, args.limit - 1);
      console.log(JSON.stringify(jobs.map(summarize), null, 2));
      return;
    }

    if (args.command === 'inspect') {
      if (!args.id) {
        throw new Error('Missing --id for inspect command');
      }

      const job = await Job.fromId(dlq, args.id);
      if (!job) {
        throw new Error(`DLQ job ${args.id} not found`);
      }

      console.log(
        JSON.stringify(
          {
            ...summarize(job),
            payload: job.data?.payload
          },
          null,
          2
        )
      );
      return;
    }

    if (args.command === 'replay') {
      if (!args.id) {
        throw new Error('Missing --id for replay command');
      }

      const job = await Job.fromId(dlq, args.id);
      if (!job) {
        throw new Error(`DLQ job ${args.id} not found`);
      }

      const archiveBeforeMutation = args.archive || args.remove;
      if (archiveBeforeMutation) {
        archiveJobs([job], args.archivePath, 'replay');
      }

      const replayedJob = await replayJob(job, args.remove);
      console.log(
        JSON.stringify(
          {
            replayed: summarize(job),
            replayedAs: {
              id: replayedJob.id,
              queue: job.data.sourceQueue,
              name: replayedJob.name
            },
            archived: archiveBeforeMutation,
            archivePath: archiveBeforeMutation ? displayPath(args.archivePath) : null,
            removedFromDlq: args.remove
          },
          null,
          2
        )
      );
      return;
    }

    if (args.command === 'replay-all') {
      const jobs = await dlq.getJobs(['wait', 'delayed'], 0, args.limit - 1);
      const archiveBeforeMutation = args.archive || args.remove;
      if (archiveBeforeMutation) {
        archiveJobs(jobs, args.archivePath, 'replay-all');
      }

      const replayed = [];
      for (const job of jobs) {
        const replayedJob = await replayJob(job, args.remove);
        replayed.push({
          dlqJobId: job.id,
          sourceQueue: job.data?.sourceQueue,
          replayedJobId: replayedJob.id,
          archived: archiveBeforeMutation,
          removedFromDlq: args.remove
        });
      }
      console.log(
        JSON.stringify(
          {
            count: replayed.length,
            archived: archiveBeforeMutation,
            archivePath: archiveBeforeMutation ? displayPath(args.archivePath) : null,
            replayed
          },
          null,
          2
        )
      );
      return;
    }

    if (args.command === 'purge') {
      const jobs = await dlq.getJobs(['wait', 'delayed', 'failed', 'completed'], 0, args.limit - 1);
      const shouldArchive = args.archive || true;

      if (shouldArchive) {
        archiveJobs(jobs, args.archivePath, 'purge');
      }

      for (const job of jobs) {
        await job.remove();
      }

      console.log(
        JSON.stringify(
          {
            purged: jobs.length,
            archived: shouldArchive,
            archivePath: shouldArchive ? displayPath(args.archivePath) : null
          },
          null,
          2
        )
      );
      return;
    }

    if (args.command === 'retain') {
      const jobs = await dlq.getJobs(['wait', 'delayed', 'failed', 'completed'], 0, args.limit - 1);
      const olderThanMs = Date.now() - args.olderThanMinutes * 60 * 1000;
      const matched = jobs.filter(job => parseDeadLetteredAtMs(job) <= olderThanMs);

      archiveJobs(matched, args.archivePath, 'retain');

      if (args.remove) {
        for (const job of matched) {
          await job.remove();
        }
      }

      console.log(
        JSON.stringify(
          {
            scanned: jobs.length,
            matched: matched.length,
            olderThanMinutes: args.olderThanMinutes,
            archived: matched.length > 0,
            archivePath: matched.length > 0 ? displayPath(args.archivePath) : null,
            removed: args.remove ? matched.length : 0
          },
          null,
          2
        )
      );
      return;
    }

    printUsage();
    process.exitCode = 1;
  } finally {
    await dlq.close();
  }
}

run().catch(error => {
  console.error(`DLQ tool failed: ${error.message}`);
  process.exitCode = 1;
});