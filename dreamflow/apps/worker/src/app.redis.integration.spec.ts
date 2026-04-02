import { Job, Queue, QueueEvents } from 'bullmq';
import { redisConnection, setupWorkers } from './main';

const runRedisIntegration = process.env.RUN_REDIS_INTEGRATION === 'true';
const describeRedis = runRedisIntegration ? describe : describe.skip;

describeRedis('Worker Redis integration', () => {
  let geofenceQueue: Queue;
  let presenceQueue: Queue;
  let notificationQueue: Queue;
  let deadLetterQueue: Queue;
  let geofenceEvents: QueueEvents;
  let presenceEvents: QueueEvents;
  let notificationEvents: QueueEvents;
  let workers: Awaited<ReturnType<typeof setupWorkers>>;
  const originalDisableRedis = process.env.DISABLE_REDIS;

  async function clearQueues() {
    await Promise.all([
      geofenceQueue.obliterate({ force: true }),
      presenceQueue.obliterate({ force: true }),
      notificationQueue.obliterate({ force: true }),
      deadLetterQueue.obliterate({ force: true })
    ]);
  }

  beforeAll(async () => {
    delete process.env.DISABLE_REDIS;
    jest.spyOn(Math, 'random').mockReturnValue(0.9);

    geofenceQueue = new Queue('geofence', { connection: redisConnection });
    presenceQueue = new Queue('presence', { connection: redisConnection });
    notificationQueue = new Queue('notification', { connection: redisConnection });
    deadLetterQueue = new Queue('dead-letter', { connection: redisConnection });
    geofenceEvents = new QueueEvents('geofence', { connection: redisConnection });
    presenceEvents = new QueueEvents('presence', { connection: redisConnection });
    notificationEvents = new QueueEvents('notification', { connection: redisConnection });

    await Promise.all([
      geofenceEvents.waitUntilReady(),
      presenceEvents.waitUntilReady(),
      notificationEvents.waitUntilReady()
    ]);

    await clearQueues();
    workers = await setupWorkers();
  });

  afterAll(async () => {
    await Promise.all([
      workers?.geofenceWorker.close(),
      workers?.presenceWorker.close(),
      workers?.notificationWorker.close()
    ]);
    await clearQueues();
    await Promise.all([
      geofenceEvents.close(),
      presenceEvents.close(),
      notificationEvents.close(),
      deadLetterQueue.close(),
      geofenceQueue.close(),
      presenceQueue.close(),
      notificationQueue.close()
    ]);
    jest.restoreAllMocks();

    if (originalDisableRedis === undefined) {
      delete process.env.DISABLE_REDIS;
      return;
    }

    process.env.DISABLE_REDIS = originalDisableRedis;
  });

  beforeEach(async () => {
    await clearQueues();
  });

  it('consumes a geofence job and records arrival output', async () => {
    const job = await geofenceQueue.add('evaluate-geofence', {
      userId: 'worker-user',
      lat: 37.7749,
      lng: -122.4194,
      recordedAt: '2026-04-02T00:00:00.000Z'
    });

    const result = await job.waitUntilFinished(geofenceEvents);
    const completedJob = await Job.fromId(geofenceQueue, job.id!);

    expect(result).toMatchObject({ processed: true, alertsTriggered: 1 });
    expect(result.alerts[0]).toMatchObject({
      type: 'arrival',
      geofenceId: 'geo-home',
      userId: 'worker-user'
    });
    expect(completedJob?.returnvalue).toEqual(result);
  });

  it('consumes a presence job and reports anomalous movement output', async () => {
    const firstJob = await presenceQueue.add('broadcast-location', {
      userId: 'worker-user',
      lat: 37.7749,
      lng: -122.4194,
      accuracy: 5,
      recordedAt: '2026-04-02T00:00:00.000Z'
    });
    await firstJob.waitUntilFinished(presenceEvents);

    const secondJob = await presenceQueue.add('broadcast-location', {
      userId: 'worker-user',
      lat: 40.7128,
      lng: -74.006,
      accuracy: 5,
      recordedAt: '2026-04-02T00:00:01.000Z'
    });

    const result = await secondJob.waitUntilFinished(presenceEvents);

    expect(result).toEqual(
      expect.objectContaining({
        processed: true,
        anomaly: true,
        message: 'Suspiciously fast movement detected'
      })
    );
  });

  it('consumes a notification job and persists sent delivery output', async () => {
    const job = await notificationQueue.add('send-alert-notification', {
      alertId: 'alert-1',
      circleId: 'circle-1',
      userId: 'worker-user',
      type: 'sos',
      message: 'SOS triggered',
      recipients: ['recipient-1', 'recipient-2']
    });

    const result = await job.waitUntilFinished(notificationEvents);
    const completedJob = await Job.fromId(notificationQueue, job.id!);

    expect(result).toMatchObject({
      alertId: 'alert-1',
      type: 'sos',
      recipients: 2
    });
    expect(result.deliveries).toEqual([
      { recipient: 'recipient-1', channel: 'push', status: 'sent' },
      { recipient: 'recipient-2', channel: 'push', status: 'sent' }
    ]);
    expect(completedJob?.returnvalue).toEqual(result);
  });

  it('retries repeated notification worker failures and retains the exhausted job in failed state', async () => {
    process.env.DREAMFLOW_THROW_NOTIFICATION_FAILURE = 'true';
    const startedAt = Date.now();

    const job = await notificationQueue.add(
      'send-alert-notification',
      {
        alertId: 'alert-retry',
        circleId: 'circle-1',
        userId: 'worker-user',
        type: 'sos',
        message: 'SOS triggered',
        recipients: ['recipient-1']
      },
      {
        attempts: 3,
        backoff: { type: 'fixed', delay: 50 },
        removeOnFail: false,
        removeOnComplete: true
      }
    );

    await expect(job.waitUntilFinished(notificationEvents)).rejects.toThrow(
      'Forced notification delivery failure'
    );

    const failedJob = await Job.fromId(notificationQueue, job.id!);
    const deadLetterJobs = await deadLetterQueue.getJobs(['wait']);
    const elapsedMs = Date.now() - startedAt;

    expect(failedJob?.attemptsMade).toBe(3);
    expect(failedJob?.failedReason).toBe('Forced notification delivery failure');
    expect(await notificationQueue.getFailedCount()).toBe(1);
    expect(elapsedMs).toBeGreaterThanOrEqual(100);
    expect(elapsedMs).toBeLessThan(5000);
    expect(deadLetterJobs).toHaveLength(1);
    expect(deadLetterJobs[0].data).toMatchObject({
      sourceQueue: 'notification',
      originalJobId: job.id,
      attemptsMade: 3,
      maxAttempts: 3,
      failedReason: 'Forced notification delivery failure'
    });

    delete process.env.DREAMFLOW_THROW_NOTIFICATION_FAILURE;
  });
});