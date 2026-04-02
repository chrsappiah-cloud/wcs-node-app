import { spawn } from 'node:child_process';

const modeArg = process.argv.find(arg => arg.startsWith('--mode='));
const smokeMode = modeArg?.split('=')[1] || 'local';
const useRedis = smokeMode === 'redis';

const API_URL = process.env.API_URL || 'http://localhost:3000/v1';

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function runCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: process.env,
      cwd: process.cwd(),
      ...options
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

async function ensureRedisForSmoke() {
  try {
    await runCommand('docker', ['info']);
  } catch {
    throw new Error('Redis smoke mode requires Docker Desktop to be running');
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
      env: {
        ...process.env,
        DISABLE_REDIS: process.env.DISABLE_REDIS || String(!useRedis)
      },
      cwd: process.cwd()
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

async function jsonFetch(url, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      'content-type': 'application/json',
      ...(options.headers || {})
    }
  });

  const body = await res.json();
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${JSON.stringify(body)}`);
  }
  return body;
}

async function run() {
  const children = [];
  try {
    if (useRedis) {
      await ensureRedisForSmoke();
    }

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

    const createdCircle = await jsonFetch(`${API_URL}/circles`, {
      method: 'POST',
      body: JSON.stringify({
        name: 'Smoke Circle',
        type: 'family',
        userId: 'smoke-user-1'
      })
    });

    await jsonFetch(`${API_URL}/presence/location`, {
      method: 'POST',
      body: JSON.stringify({
        userId: 'smoke-user-1',
        lat: 37.7749,
        lng: -122.4194,
        accuracy: 8.1,
        speed: 2.5
      })
    });

    await jsonFetch(`${API_URL}/alerts/sos`, {
      method: 'POST',
      body: JSON.stringify({
        userId: 'smoke-user-1',
        circleId: createdCircle.id,
        lat: 37.7749,
        lng: -122.4194
      })
    });

    // Allow workers a moment to drain queued jobs.
    await wait(3000);

    const alerts = await jsonFetch(`${API_URL}/alerts/circle/${createdCircle.id}`);
    if (!alerts.count || alerts.count < 1) {
      throw new Error('Expected at least one alert in smoke test');
    }

    console.log(`\nE2E smoke test passed (${smokeMode} mode).`);
    process.exitCode = 0;
  } catch (error) {
    console.error('\nE2E smoke test failed:', error.message);
    process.exitCode = 1;
  } finally {
    for (const child of children) {
      if (!child.killed) {
        child.kill('SIGTERM');
      }
    }
  }
}

run();
