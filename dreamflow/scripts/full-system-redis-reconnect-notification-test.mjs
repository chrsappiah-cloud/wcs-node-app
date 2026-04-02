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
  await runCommand('docker', ['info']);
  await runCommand('docker', ['compose', '-f', dockerComposePath, 'up', '-d', 'redis']);
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

async function sleep(ms) {
  await new Promise(resolve => setTimeout(resolve, ms));
}

async function waitForCompletion(job, queueEvents, timeoutMs = 30000) {
  return await Promise.race([
    job.waitUntilFinished(queueEvents),
    new Promise((_, reject) => setTimeout(() => reject(new Error('Timed out waiting for notification completion after Redis reconnect')), timeoutMs))
  ]);
}

async function main() {
  const children = [];
  const notificationQueue = new Queue('notification', { connection: redisConnection });
  const notificationEvents = new QueueEvents('notification', { connection: redisConnection });

  try {
    await ensureRedis();
    await Promise.all([notificationQueue.waitUntilReady(), notificationEvents.waitUntilReady()]);
    await notificationQueue.obliterate({ force: true });

    const worker = await startProcess(
      'worker',
      'npm',
      ['run', 'dev:worker'],
      /Worker started|DreamFlow Worker is running/,
      { DREAMFLOW_NOTIFICATION_PROCESSING_DELAY_MS: '3000' }
    );
    children.push(worker);

    const startedAt = Date.now();
    const job = await notificationQueue.add(
      'send-alert-notification',
      {
        alertId: 'notification-reconnect-alert',
        circleId: 'circle-1',
        userId: 'notification-reconnect-user',
        type: 'sos',
        message: 'SOS reconnect check',
        recipients: ['notification-reconnect-user']
      },
      { attempts: 1, removeOnComplete: false, removeOnFail: false }
    );

    await sleep(500);
    await runCommand('docker', ['compose', '-f', dockerComposePath, 'stop', 'redis']);
    await sleep(1000);
    await runCommand('docker', ['compose', '-f', dockerComposePath, 'up', '-d', 'redis']);

    const result = await waitForCompletion(job, notificationEvents);
    const recoveryLatencyMs = Date.now() - startedAt;

    assert.equal(result.alertId, 'notification-reconnect-alert');
    assert.equal(result.recipients, 1);
    assert.deepEqual(result.deliveries, [
      { recipient: 'notification-reconnect-user', channel: 'push', status: 'sent' }
    ]);
    assert.equal(job.attemptsMade, 0);
    assert.ok(recoveryLatencyMs >= 2500, `expected reconnect latency >= 2500ms, got ${recoveryLatencyMs}`);
    assert.ok(recoveryLatencyMs < 15000, `expected reconnect latency < 15000ms, got ${recoveryLatencyMs}`);

    console.log(`\nNotification reconnect latency: ${recoveryLatencyMs}ms`);
    console.log('Full-system Redis notification reconnect test passed.');
    process.exitCode = 0;
  } catch (error) {
    console.error('\nFull-system Redis notification reconnect test failed:', error.message);
    process.exitCode = 1;
  } finally {
    await Promise.allSettled([notificationEvents.close(), notificationQueue.close()]);
    for (const child of children) {
      stopProcess(child);
    }
    await Promise.allSettled([
      runCommand('docker', ['compose', '-f', dockerComposePath, 'up', '-d', 'redis'])
    ]);
  }
}

main();