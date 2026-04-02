import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { QueueEvents } from 'bullmq';

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
    throw new Error('Full-system Redis test requires Docker Desktop to be running');
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

function startProcess(name, command, args, readyPattern) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: process.cwd(),
      detached: true,
      env: {
        ...process.env,
        DISABLE_REDIS: 'false'
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

async function waitForCompleted(queueEvents) {
  const [event] = await once(queueEvents, 'completed');
  return normalizeReturnValue(event.returnvalue);
}

async function main() {
  const children = [];
  const geofenceEvents = new QueueEvents('geofence', { connection: redisConnection });
  const presenceEvents = new QueueEvents('presence', { connection: redisConnection });
  const notificationEvents = new QueueEvents('notification', { connection: redisConnection });

  try {
    await ensureRedis();
    await Promise.all([
      geofenceEvents.waitUntilReady(),
      presenceEvents.waitUntilReady(),
      notificationEvents.waitUntilReady()
    ]);

    const worker = await startProcess(
      'worker',
      'npm',
      ['run', 'dev:worker'],
      /Worker started|DreamFlow Worker is running/
    );
    children.push(worker);

    const api = await startProcess(
      'api',
      'npm',
      ['run', 'dev:api'],
      /Nest application successfully started/
    );
    children.push(api);

    await jsonFetch(`${API_URL}/health`);

    const circle = await jsonFetch(`${API_URL}/circles`, {
      method: 'POST',
      body: JSON.stringify({ name: 'System Circle', type: 'family', userId: 'system-user' })
    });

    const geofenceCompleted = waitForCompleted(geofenceEvents);
    const presenceCompleted = waitForCompleted(presenceEvents);

    await jsonFetch(`${API_URL}/presence/location`, {
      method: 'POST',
      body: JSON.stringify({
        userId: 'system-user',
        lat: 37.7749,
        lng: -122.4194,
        accuracy: 4.5,
        speed: 1.8
      })
    });

    const [geofenceResult, presenceResult] = await Promise.all([
      geofenceCompleted,
      presenceCompleted
    ]);

    assert.equal(geofenceResult.processed, true);
    assert.equal(geofenceResult.alertsTriggered, 1);
    assert.equal(geofenceResult.alerts[0].type, 'arrival');
    assert.equal(geofenceResult.alerts[0].userId, 'system-user');
    assert.equal(geofenceResult.alerts[0].geofenceId, 'geo-home');

    assert.equal(presenceResult.processed, true);
    assert.equal(presenceResult.anomaly, false);
    assert.equal(presenceResult.message, 'Location broadcast successful');

    const notificationCompleted = waitForCompleted(notificationEvents);

    const alertResponse = await jsonFetch(`${API_URL}/alerts/sos`, {
      method: 'POST',
      body: JSON.stringify({
        userId: 'system-user',
        circleId: circle.id,
        lat: 37.7749,
        lng: -122.4194
      })
    });

    const notificationResult = await notificationCompleted;

    assert.equal(notificationResult.alertId, alertResponse.alert.id);
    assert.equal(notificationResult.type, 'sos');
    assert.equal(notificationResult.recipients, 1);
    assert.deepEqual(notificationResult.deliveries, [
      { recipient: 'system-user', channel: 'push', status: 'sent' }
    ]);

    console.log('\nFull-system Redis integration test passed.');
    process.exitCode = 0;
  } catch (error) {
    console.error('\nFull-system Redis integration test failed:', error.message);
    process.exitCode = 1;
  } finally {
    await Promise.allSettled([
      geofenceEvents.close(),
      presenceEvents.close(),
      notificationEvents.close()
    ]);

    for (const child of children) {
      stopProcess(child);
    }
  }
}

main();