import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { Queue, QueueEvents } from 'bullmq';

const API_URL = process.env.API_URL || 'http://localhost:3000/v1';
const redisConnection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379', 10)
};

function normalizeReturnValue(value) {
  if (typeof value !== 'string') {
    return value;
  }

  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function runCommand(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: process.cwd(),
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
    throw new Error('Full-system Redis failure test requires Docker Desktop to be running');
  }

  await runCommand('docker', [
    'compose',
    '-f',
    'infrastructure/docker/docker-compose.yml',
    'up',
    '-d',
    'redis'
  ]);
}

function startProcess(name, command, args, readyPattern, extraEnv = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: process.cwd(),
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

async function jsonFetch(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      'content-type': 'application/json',
      ...(options.headers || {})
    }
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${JSON.stringify(body)}`);
  }
  return body;
}

async function waitForEvent(queueEvents, eventName) {
  const [event] = await once(queueEvents, eventName);
  return {
    ...event,
    returnvalue: normalizeReturnValue(event.returnvalue)
  };
}

async function main() {
  const children = [];
  const geofenceQueue = new Queue('geofence', { connection: redisConnection });
  const notificationEvents = new QueueEvents('notification', { connection: redisConnection });
  const geofenceEvents = new QueueEvents('geofence', { connection: redisConnection });

  try {
    await ensureRedis();
    await Promise.all([
      geofenceQueue.waitUntilReady(),
      notificationEvents.waitUntilReady(),
      geofenceEvents.waitUntilReady()
    ]);
    await geofenceQueue.obliterate({ force: true });

    const worker = await startProcess(
      'worker',
      'npm',
      ['run', 'dev:worker'],
      /Worker started|DreamFlow Worker is running/,
      { DREAMFLOW_FORCE_NOTIFICATION_FAILURE: 'true' }
    );
    children.push(worker);

    const api = await startProcess(
      'api',
      'npm',
      ['run', 'dev:api'],
      /Nest application successfully started/
    );
    children.push(api);

    const circle = await jsonFetch(`${API_URL}/circles`, {
      method: 'POST',
      body: JSON.stringify({ name: 'Failure Circle', type: 'family', userId: 'failure-user' })
    });

    const notificationCompleted = waitForEvent(notificationEvents, 'completed');

    const alertResponse = await jsonFetch(`${API_URL}/alerts/sos`, {
      method: 'POST',
      body: JSON.stringify({
        userId: 'failure-user',
        circleId: circle.id,
        lat: 37.7749,
        lng: -122.4194
      })
    });

    const notificationResult = await notificationCompleted;

    assert.equal(notificationResult.returnvalue.alertId, alertResponse.alert.id);
    assert.deepEqual(notificationResult.returnvalue.deliveries, [
      { recipient: 'failure-user', channel: 'push', status: 'failed' }
    ]);

    const failedJob = waitForEvent(geofenceEvents, 'failed');

    await geofenceQueue.add('evaluate-geofence', {
      userId: 'failure-user',
      recordedAt: new Date().toISOString()
    });

    const geofenceFailure = await failedJob;
    assert.equal(geofenceFailure.failedReason, 'Invalid geofence job payload');

    const geofenceRecovered = waitForEvent(geofenceEvents, 'completed');

    await geofenceQueue.add('evaluate-geofence', {
      userId: 'failure-user',
      lat: 37.7749,
      lng: -122.4194,
      recordedAt: new Date().toISOString()
    });

    const recoveredResult = await geofenceRecovered;
    assert.equal(recoveredResult.returnvalue.processed, true);
    assert.equal(recoveredResult.returnvalue.alertsTriggered, 1);

    console.log('\nFull-system Redis failure-path test passed.');
    process.exitCode = 0;
  } catch (error) {
    console.error('\nFull-system Redis failure-path test failed:', error.message);
    process.exitCode = 1;
  } finally {
    await Promise.allSettled([
      geofenceQueue.close(),
      notificationEvents.close(),
      geofenceEvents.close()
    ]);

    for (const child of children) {
      stopProcess(child);
    }
  }
}

main();