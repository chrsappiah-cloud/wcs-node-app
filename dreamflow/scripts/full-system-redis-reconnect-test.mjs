import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';
import { Queue, QueueEvents } from 'bullmq';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const redisConnection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379', 10)
};
const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const dockerComposePath = resolve(projectRoot, 'infrastructure/docker/docker-compose.yml');

function runCommand(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: projectRoot,
      env: process.env
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', data => {
      stdout += data.toString();
    });

    child.stderr.on('data', data => {
      stderr += data.toString();
    });

    child.on('exit', code => {
      if (code === 0) {
        resolve({ stdout, stderr });
        return;
      }

      reject(new Error((stderr || stdout || `${command} exited with code ${code}`).trim()));
    });
  });
}

async function ensureRedis() {
  try {
    await runCommand('docker', ['info']);
  } catch {
    throw new Error('Redis reconnect test requires Docker Desktop to be running');
  }

  await runCommand('docker', [
    'compose',
    '-f',
    dockerComposePath,
    'up',
    '-d',
    'redis'
  ]);
}

function startProcess(name, command, args, readyPattern, extraEnv = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: projectRoot,
      detached: true,
      env: {
        ...process.env,
        DISABLE_REDIS: 'false',
        ...extraEnv
      }
    });

    let settled = false;

    const onData = data => {
      const text = data.toString();
      process.stdout.write(`[${name}] ${text}`);
      if (!settled && readyPattern.test(text)) {
        settled = true;
        resolve(child);
      }
    };

    child.stdout.on('data', onData);
    child.stderr.on('data', onData);

    child.on('exit', code => {
      if (!settled) {
        reject(new Error(`${name} exited before ready with code ${code}`));
      }
    });

    setTimeout(() => {
      if (!settled) {
        settled = true;
        reject(new Error(`${name} readiness timeout`));
      }
    }, 30000);
  });
}

function stopProcess(child) {
  if (!child || child.killed) {
    return;
  }

  try {
    process.kill(-child.pid, 'SIGTERM');
  } catch {
    child.kill('SIGTERM');
  }
}

async function waitForCompletion(job, queueEvents, timeoutMs = 30000) {
  return await Promise.race([
    job.waitUntilFinished(queueEvents),
    new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Timed out waiting for geofence completion after Redis reconnect')), timeoutMs);
    })
  ]);
}

async function sleep(ms) {
  await new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  const children = [];
  const geofenceQueue = new Queue('geofence', { connection: redisConnection });
  const geofenceEvents = new QueueEvents('geofence', { connection: redisConnection });

  try {
    await ensureRedis();
    await Promise.all([geofenceQueue.waitUntilReady(), geofenceEvents.waitUntilReady()]);
    await geofenceQueue.obliterate({ force: true });

    const worker = await startProcess(
      'worker',
      'npm',
      ['run', 'dev:worker'],
      /Worker started|DreamFlow Worker is running/,
      { DREAMFLOW_GEOFENCE_PROCESSING_DELAY_MS: '3000' }
    );
    children.push(worker);

    const job = await geofenceQueue.add(
      'evaluate-geofence',
      {
        userId: 'reconnect-user',
        lat: 37.7749,
        lng: -122.4194,
        recordedAt: new Date().toISOString()
      },
      { attempts: 1, removeOnComplete: false, removeOnFail: false }
    );

    await sleep(500);
    await runCommand('docker', ['compose', '-f', dockerComposePath, 'stop', 'redis']);
    await sleep(1000);
    await runCommand('docker', ['compose', '-f', dockerComposePath, 'up', '-d', 'redis']);

    const result = await waitForCompletion(job, geofenceEvents);
    assert.equal(result.processed, true);
    assert.equal(result.alertsTriggered, 1);
    assert.equal(result.alerts[0].type, 'arrival');

    const recoveryJob = await geofenceQueue.add(
      'evaluate-geofence',
      {
        userId: 'reconnect-user-2',
        lat: 37.7749,
        lng: -122.4194,
        recordedAt: new Date().toISOString()
      },
      { attempts: 1, removeOnComplete: false, removeOnFail: false }
    );

    const recoveryResult = await waitForCompletion(recoveryJob, geofenceEvents);
    assert.equal(recoveryResult.processed, true);
    assert.equal(recoveryResult.alertsTriggered, 1);

    console.log('\nFull-system Redis reconnect test passed.');
    process.exitCode = 0;
  } catch (error) {
    console.error('\nFull-system Redis reconnect test failed:', error.message);
    process.exitCode = 1;
  } finally {
    await Promise.allSettled([geofenceEvents.close(), geofenceQueue.close()]);

    for (const child of children) {
      stopProcess(child);
    }

    await Promise.allSettled([
      runCommand('docker', ['compose', '-f', dockerComposePath, 'up', '-d', 'redis'])
    ]);
  }
}

main();