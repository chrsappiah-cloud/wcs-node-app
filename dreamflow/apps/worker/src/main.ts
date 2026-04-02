import { Logger } from '@nestjs/common';
import { Queue, Worker } from 'bullmq';
import { GeofenceProcessor, GeofenceEvaluationJob } from './jobs/geofence.processor';
import { PresenceProcessor, PresenceBroadcastJob } from './jobs/presence.processor';
import { NotificationProcessor, AlertNotificationJob } from './jobs/notification.processor';
import { WorkerMetricsExporter } from './observability/worker-metrics';

export const redisConnection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379', 10)
};

const logger = new Logger('DreamFlowWorker');
const isRedisDisabled = () => process.env.DISABLE_REDIS === 'true';

async function routeToDeadLetterQueue(
  deadLetterQueue: Queue,
  sourceQueue: 'geofence' | 'presence' | 'notification',
  job: { id?: string; name?: string; data?: unknown; attemptsMade?: number; opts?: { attempts?: number } },
  err: Error
) {
  await deadLetterQueue.add(
    `dead-letter-${sourceQueue}`,
    {
      sourceQueue,
      originalJobId: job.id,
      originalJobName: job.name,
      payload: job.data,
      attemptsMade: job.attemptsMade ?? 0,
      maxAttempts: job.opts?.attempts ?? 1,
      failedReason: err.message,
      deadLetteredAt: new Date().toISOString()
    },
    {
      removeOnComplete: false,
      removeOnFail: false
    }
  );
}

function stopProcessResource(resource: { close: () => Promise<void> } | null | undefined): Promise<void> {
  if (!resource) {
    return Promise.resolve();
  }

  return resource.close();
}

export async function setupWorkers() {
  if (isRedisDisabled()) {
    logger.warn('Redis disabled; worker is running in local smoke-test mode without queue consumers.');
    return null;
  }

  const geofenceProcessor = new GeofenceProcessor();
  const presenceProcessor = new PresenceProcessor();
  const notificationProcessor = new NotificationProcessor();
  const deadLetterQueue = new Queue('dead-letter', { connection: redisConnection });
  const metrics = new WorkerMetricsExporter(logger);

  // Geofence Worker
  const geofenceWorker = new Worker<GeofenceEvaluationJob>(
    'geofence',
    async job => {
      const startedAtMs = Date.now();
      logger.debug(`Processing geofence evaluation for job ${job.id}`);
      const result = await geofenceProcessor.processGeofenceEvaluation(job.data);
      logger.log(`Geofence job ${job.id} complete: ${result.alertsTriggered} alerts`);
      metrics.recordCompleted('geofence', Date.now() - startedAtMs);
      return result;
    },
    { connection: redisConnection, concurrency: 10 }
  );

  geofenceWorker.on('completed', job => {
    logger.log(`✓ Geofence job ${job.id} completed`);
  });

  geofenceWorker.on('failed', async (job, err) => {
    logger.error(`✗ Geofence job ${job?.id} failed: ${err.message}`);
    metrics.recordFailed('geofence', job?.attemptsMade ?? 0, job?.opts.attempts ?? 1);

    if (job && (job.attemptsMade ?? 0) >= (job.opts.attempts ?? 1)) {
      await routeToDeadLetterQueue(deadLetterQueue, 'geofence', job, err);
      metrics.recordDeadLettered('geofence');
    }
  });

  geofenceWorker.on('error', err => {
    logger.error(`✗ Geofence worker error: ${err.message}`);
    metrics.recordWorkerError('geofence', err as Error);
  });

  // Presence Worker
  const presenceWorker = new Worker<PresenceBroadcastJob>(
    'presence',
    async job => {
      const startedAtMs = Date.now();
      logger.debug(`Processing presence broadcast for job ${job.id}`);
      const result = await presenceProcessor.processBroadcast(job.data);
      logger.log(`Presence job ${job.id} complete`);
      metrics.recordCompleted('presence', Date.now() - startedAtMs);
      return result;
    },
    { connection: redisConnection, concurrency: 20 }
  );

  presenceWorker.on('completed', job => {
    logger.log(`✓ Presence job ${job.id} completed`);
  });

  presenceWorker.on('failed', async (job, err) => {
    logger.error(`✗ Presence job ${job?.id} failed: ${err.message}`);
    metrics.recordFailed('presence', job?.attemptsMade ?? 0, job?.opts.attempts ?? 1);

    if (job && (job.attemptsMade ?? 0) >= (job.opts.attempts ?? 1)) {
      await routeToDeadLetterQueue(deadLetterQueue, 'presence', job, err);
      metrics.recordDeadLettered('presence');
    }
  });

  presenceWorker.on('error', err => {
    logger.error(`✗ Presence worker error: ${err.message}`);
    metrics.recordWorkerError('presence', err as Error);
  });

  // Notification Worker
  const notificationWorker = new Worker<AlertNotificationJob>(
    'notification',
    async job => {
      const startedAtMs = Date.now();
      logger.debug(`Processing notification for job ${job.id}`);
      const result = await notificationProcessor.sendAlertNotification(job.data);
      logger.log(`Notification job ${job.id} complete: sent to ${result.recipients} recipients`);
      metrics.recordCompleted('notification', Date.now() - startedAtMs);
      return result;
    },
    { connection: redisConnection, concurrency: 15 }
  );

  notificationWorker.on('completed', job => {
    logger.log(`✓ Notification job ${job.id} completed`);
  });

  notificationWorker.on('failed', async (job, err) => {
    logger.error(`✗ Notification job ${job?.id} failed: ${err.message}`);
    metrics.recordFailed('notification', job?.attemptsMade ?? 0, job?.opts.attempts ?? 1);

    if (job && (job.attemptsMade ?? 0) >= (job.opts.attempts ?? 1)) {
      await routeToDeadLetterQueue(deadLetterQueue, 'notification', job, err);
      metrics.recordDeadLettered('notification');
    }
  });

  notificationWorker.on('error', err => {
    logger.error(`✗ Notification worker error: ${err.message}`);
    metrics.recordWorkerError('notification', err as Error);
  });

  logger.log(
    '✓ Worker started: geofence, presence, notification job handlers registered and ready.'
  );

  const shutdown = async () => {
    await Promise.all([
      stopProcessResource(geofenceWorker),
      stopProcessResource(presenceWorker),
      stopProcessResource(notificationWorker),
      stopProcessResource(deadLetterQueue)
    ]);
    metrics.stop();
  };

  process.once('SIGINT', () => {
    void shutdown().finally(() => process.exit(0));
  });

  process.once('SIGTERM', () => {
    void shutdown().finally(() => process.exit(0));
  });

  return { geofenceWorker, presenceWorker, notificationWorker, deadLetterQueue, metrics, shutdown };
}

async function bootstrap() {
  try {
    await setupWorkers();
    logger.log('DreamFlow Worker is running...');
    if (isRedisDisabled()) {
      logger.log('Redis connection: disabled');
    } else {
      logger.log(`Redis connection: ${redisConnection.host}:${redisConnection.port}`);
    }
  } catch (error) {
    logger.error('Failed to start worker:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  bootstrap();
}

