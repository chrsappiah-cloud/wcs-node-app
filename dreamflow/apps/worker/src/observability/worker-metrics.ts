import { Logger } from '@nestjs/common';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

type QueueName = 'geofence' | 'presence' | 'notification';

type QueueMetrics = {
  completed: number;
  failed: number;
  errored: number;
  retried: number;
  deadLettered: number;
  averageProcessingLatencyMs: number;
  maxProcessingLatencyMs: number;
};

type WorkerMetricsSnapshot = {
  startedAt: string;
  lastUpdatedAt: string;
  totals: {
    completed: number;
    failed: number;
    errored: number;
    retried: number;
    deadLettered: number;
  };
  queues: Record<QueueName, QueueMetrics>;
  reconnect: {
    activeOutageSince: string | null;
    totalRecoveries: number;
    lastRecoveryLatencyMs: number | null;
    maxRecoveryLatencyMs: number;
  };
  alerts: {
    dlqGrowthThreshold: {
      threshold: number;
      windowMs: number;
      breaches: number;
    };
    reconnectLatencyThreshold: {
      thresholdMs: number;
      breaches: number;
    };
  };
};

function newQueueMetrics(): QueueMetrics {
  return {
    completed: 0,
    failed: 0,
    errored: 0,
    retried: 0,
    deadLettered: 0,
    averageProcessingLatencyMs: 0,
    maxProcessingLatencyMs: 0
  };
}

export class WorkerMetricsExporter {
  private readonly logger: Logger;
  private readonly metricsPath: string;
  private readonly reconnectLatencyThresholdMs: number;
  private readonly dlqGrowthThreshold: number;
  private readonly dlqGrowthWindowMs: number;
  private writeTimer: ReturnType<typeof setTimeout> | null = null;
  private outageStartedAtMs: number | null = null;
  private deadLetterEventsMs: number[] = [];
  private snapshot: WorkerMetricsSnapshot;

  constructor(logger: Logger) {
    this.logger = logger;
    this.metricsPath = resolve(
      process.env.WORKER_METRICS_PATH || resolve(process.cwd(), '.runtime/worker-metrics.json')
    );
    this.reconnectLatencyThresholdMs = parseInt(
      process.env.WORKER_ALERT_RECONNECT_LATENCY_MS || '5000',
      10
    );
    this.dlqGrowthThreshold = parseInt(process.env.WORKER_ALERT_DLQ_GROWTH_COUNT || '5', 10);
    this.dlqGrowthWindowMs = parseInt(process.env.WORKER_ALERT_DLQ_GROWTH_WINDOW_MS || '60000', 10);

    const now = new Date().toISOString();
    this.snapshot = {
      startedAt: now,
      lastUpdatedAt: now,
      totals: {
        completed: 0,
        failed: 0,
        errored: 0,
        retried: 0,
        deadLettered: 0
      },
      queues: {
        geofence: newQueueMetrics(),
        presence: newQueueMetrics(),
        notification: newQueueMetrics()
      },
      reconnect: {
        activeOutageSince: null,
        totalRecoveries: 0,
        lastRecoveryLatencyMs: null,
        maxRecoveryLatencyMs: 0
      },
      alerts: {
        dlqGrowthThreshold: {
          threshold: this.dlqGrowthThreshold,
          windowMs: this.dlqGrowthWindowMs,
          breaches: 0
        },
        reconnectLatencyThreshold: {
          thresholdMs: this.reconnectLatencyThresholdMs,
          breaches: 0
        }
      }
    };

    this.persistSnapshot();
  }

  recordCompleted(queue: QueueName, processingLatencyMs: number): void {
    const queueMetrics = this.snapshot.queues[queue];
    queueMetrics.completed += 1;
    this.snapshot.totals.completed += 1;

    const n = queueMetrics.completed;
    const prevAverage = queueMetrics.averageProcessingLatencyMs;
    queueMetrics.averageProcessingLatencyMs = prevAverage + (processingLatencyMs - prevAverage) / n;
    queueMetrics.maxProcessingLatencyMs = Math.max(
      queueMetrics.maxProcessingLatencyMs,
      processingLatencyMs
    );

    this.recordRecoveryIfNeeded();
    this.bumpUpdatedAtAndPersistSoon();
  }

  recordFailed(queue: QueueName, attemptsMade: number, maxAttempts: number): void {
    this.snapshot.queues[queue].failed += 1;
    this.snapshot.totals.failed += 1;

    if (attemptsMade < maxAttempts) {
      this.snapshot.queues[queue].retried += 1;
      this.snapshot.totals.retried += 1;
    }

    this.bumpUpdatedAtAndPersistSoon();
  }

  recordWorkerError(queue: QueueName, err: Error): void {
    this.snapshot.queues[queue].errored += 1;
    this.snapshot.totals.errored += 1;

    if (/(ECONNREFUSED|ETIMEDOUT|EAI_AGAIN|connection\s+is\s+closed)/i.test(err.message)) {
      this.markConnectionOutage();
    }

    this.bumpUpdatedAtAndPersistSoon();
  }

  recordDeadLettered(queue: QueueName): void {
    this.snapshot.queues[queue].deadLettered += 1;
    this.snapshot.totals.deadLettered += 1;

    const now = Date.now();
    this.deadLetterEventsMs = this.deadLetterEventsMs.filter(ts => now - ts <= this.dlqGrowthWindowMs);
    this.deadLetterEventsMs.push(now);

    if (this.deadLetterEventsMs.length >= this.dlqGrowthThreshold) {
      this.snapshot.alerts.dlqGrowthThreshold.breaches += 1;
      this.logger.error(
        `ALERT DLQ growth threshold breached: ${this.deadLetterEventsMs.length} dead-letter events in ${this.dlqGrowthWindowMs}ms (threshold ${this.dlqGrowthThreshold})`
      );
      this.deadLetterEventsMs = [];
    }

    this.bumpUpdatedAtAndPersistSoon();
  }

  stop(): void {
    if (this.writeTimer) {
      clearTimeout(this.writeTimer);
      this.writeTimer = null;
    }

    this.persistSnapshot();
  }

  private markConnectionOutage(): void {
    if (this.outageStartedAtMs !== null) {
      return;
    }

    this.outageStartedAtMs = Date.now();
    this.snapshot.reconnect.activeOutageSince = new Date(this.outageStartedAtMs).toISOString();
  }

  private recordRecoveryIfNeeded(): void {
    if (this.outageStartedAtMs === null) {
      return;
    }

    const latencyMs = Date.now() - this.outageStartedAtMs;
    this.snapshot.reconnect.totalRecoveries += 1;
    this.snapshot.reconnect.lastRecoveryLatencyMs = latencyMs;
    this.snapshot.reconnect.maxRecoveryLatencyMs = Math.max(
      this.snapshot.reconnect.maxRecoveryLatencyMs,
      latencyMs
    );
    this.snapshot.reconnect.activeOutageSince = null;
    this.outageStartedAtMs = null;

    if (latencyMs > this.reconnectLatencyThresholdMs) {
      this.snapshot.alerts.reconnectLatencyThreshold.breaches += 1;
      this.logger.error(
        `ALERT reconnect latency threshold breached: ${latencyMs}ms (threshold ${this.reconnectLatencyThresholdMs}ms)`
      );
    }
  }

  private bumpUpdatedAtAndPersistSoon(): void {
    this.snapshot.lastUpdatedAt = new Date().toISOString();

    if (this.writeTimer) {
      return;
    }

    this.writeTimer = setTimeout(() => {
      this.writeTimer = null;
      this.persistSnapshot();
    }, 150);
  }

  private persistSnapshot(): void {
    mkdirSync(dirname(this.metricsPath), { recursive: true });
    writeFileSync(this.metricsPath, JSON.stringify(this.snapshot, null, 2));
  }
}