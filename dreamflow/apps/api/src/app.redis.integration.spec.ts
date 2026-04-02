import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Queue } from 'bullmq';
import request from 'supertest';
import { AppModule } from './app.module';

const runRedisIntegration = process.env.RUN_REDIS_INTEGRATION === 'true';
const describeRedis = runRedisIntegration ? describe : describe.skip;

describeRedis('API Redis integration', () => {
  let app: INestApplication;
  let geofenceQueue: Queue;
  let presenceQueue: Queue;
  let notificationQueue: Queue;
  const originalDisableRedis = process.env.DISABLE_REDIS;

  const connection = {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10)
  };

  async function clearQueues() {
    await Promise.all([
      geofenceQueue.obliterate({ force: true }),
      presenceQueue.obliterate({ force: true }),
      notificationQueue.obliterate({ force: true })
    ]);
  }

  async function getQueueCounts() {
    const [geofenceCounts, presenceCounts, notificationCounts] = await Promise.all([
      geofenceQueue.getJobCounts('wait', 'active', 'delayed', 'failed', 'completed', 'paused', 'prioritized'),
      presenceQueue.getJobCounts('wait', 'active', 'delayed', 'failed', 'completed', 'paused', 'prioritized'),
      notificationQueue.getJobCounts('wait', 'active', 'delayed', 'failed', 'completed', 'paused', 'prioritized')
    ]);

    return { geofenceCounts, presenceCounts, notificationCounts };
  }

  beforeAll(async () => {
    delete process.env.DISABLE_REDIS;

    geofenceQueue = new Queue('geofence', { connection });
    presenceQueue = new Queue('presence', { connection });
    notificationQueue = new Queue('notification', { connection });

    await clearQueues();

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('v1');
    await app.init();
  });

  afterAll(async () => {
    await clearQueues();
    await Promise.all([geofenceQueue.close(), presenceQueue.close(), notificationQueue.close()]);
    await app.close();

    if (originalDisableRedis === undefined) {
      delete process.env.DISABLE_REDIS;
      return;
    }

    process.env.DISABLE_REDIS = originalDisableRedis;
  });

  beforeEach(async () => {
    await clearQueues();
  });

  it('enqueues geofence and presence jobs when a location ping is accepted', async () => {
    await request(app.getHttpServer())
      .post('/v1/presence/location')
      .send({
        userId: 'redis-user',
        lat: 37.7749,
        lng: -122.4194,
        accuracy: 5.1,
        speed: 2.4
      })
      .expect(201);

    const geofenceJobs = await geofenceQueue.getJobs(['wait']);
    const presenceJobs = await presenceQueue.getJobs(['wait']);

    expect(geofenceJobs).toHaveLength(1);
    expect(geofenceJobs[0].name).toBe('evaluate-geofence');
    expect(geofenceJobs[0].data).toMatchObject({
      userId: 'redis-user',
      lat: 37.7749,
      lng: -122.4194
    });

    expect(presenceJobs).toHaveLength(1);
    expect(presenceJobs[0].name).toBe('broadcast-location');
    expect(presenceJobs[0].data).toMatchObject({
      userId: 'redis-user',
      lat: 37.7749,
      lng: -122.4194,
      accuracy: 5.1
    });

    expect(geofenceJobs[0].opts.attempts).toBe(3);
    expect(geofenceJobs[0].opts.removeOnFail).toBe(false);
    expect(presenceJobs[0].opts.attempts).toBe(3);
    expect(presenceJobs[0].opts.removeOnFail).toBe(false);
  });

  it('enqueues notification jobs when an alert is created', async () => {
    const circleResponse = await request(app.getHttpServer())
      .post('/v1/circles')
      .send({ name: 'Redis Alert Circle', type: 'family', userId: 'redis-alert-user' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/v1/alerts/sos')
      .send({
        userId: 'redis-alert-user',
        circleId: circleResponse.body.id,
        lat: 37.7749,
        lng: -122.4194
      })
      .expect(201);

    const notificationJobs = await notificationQueue.getJobs(['wait']);

    expect(notificationJobs).toHaveLength(1);
    expect(notificationJobs[0].name).toBe('send-alert-notification');
    expect(notificationJobs[0].data).toMatchObject({
      circleId: circleResponse.body.id,
      userId: 'redis-alert-user',
      type: 'sos',
      message: 'SOS triggered at (37.7749, -122.4194)'
    });
    expect(notificationJobs[0].opts.attempts).toBe(3);
    expect(notificationJobs[0].opts.removeOnFail).toBe(false);
  });

  it('rejects malformed location pings without enqueuing any jobs', async () => {
    await request(app.getHttpServer())
      .post('/v1/presence/location')
      .send({
        userId: 'redis-user',
        lat: 'bad-lat',
        lng: -122.4194,
        accuracy: 5.1
      })
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('userId, lat, and lng are required');
      });

    expect(await getQueueCounts()).toEqual({
      geofenceCounts: {
        wait: 0,
        active: 0,
        delayed: 0,
        failed: 0,
        completed: 0,
        paused: 0,
        prioritized: 0
      },
      presenceCounts: {
        wait: 0,
        active: 0,
        delayed: 0,
        failed: 0,
        completed: 0,
        paused: 0,
        prioritized: 0
      },
      notificationCounts: {
        wait: 0,
        active: 0,
        delayed: 0,
        failed: 0,
        completed: 0,
        paused: 0,
        prioritized: 0
      }
    });
  });

  it('rejects malformed sos payloads without enqueuing notification jobs', async () => {
    const circleResponse = await request(app.getHttpServer())
      .post('/v1/circles')
      .send({ name: 'Redis Alert Circle', type: 'family', userId: 'redis-alert-user' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/v1/alerts/sos')
      .send({
        userId: 'redis-alert-user',
        circleId: circleResponse.body.id,
        lat: 'bad-lat',
        lng: -122.4194
      })
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('lat and lng must be finite numbers');
      });

    const notificationJobs = await notificationQueue.getJobs(['wait', 'active', 'delayed', 'failed', 'completed']);
    expect(notificationJobs).toHaveLength(0);
  });
});