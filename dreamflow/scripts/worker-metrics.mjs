import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const explicitPath = process.env.WORKER_METRICS_PATH;
const candidatePaths = explicitPath
  ? [resolve(explicitPath)]
  : [
      resolve(process.cwd(), '.runtime/worker-metrics.json'),
      resolve(process.cwd(), 'apps/worker/.runtime/worker-metrics.json'),
      resolve(process.cwd(), '../.runtime/worker-metrics.json')
    ];

const metricsPath = candidatePaths.find(path => existsSync(path));

if (!metricsPath) {
  console.error('Worker metrics file not found. Checked paths:');
  for (const path of candidatePaths) {
    console.error(`- ${path}`);
  }
  process.exitCode = 1;
} else {
  const raw = readFileSync(metricsPath, 'utf8');
  const parsed = JSON.parse(raw);
  console.log(JSON.stringify(parsed, null, 2));
}