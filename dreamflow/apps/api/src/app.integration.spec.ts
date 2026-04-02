import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from './app.module';

describe('API integration', () => {
  let app: INestApplication;
  const originalDisableRedis = process.env.DISABLE_REDIS;

  beforeAll(async () => {
    process.env.DISABLE_REDIS = 'true';

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('v1');
    await app.init();
  });

  afterAll(async () => {
    await app.close();

    if (originalDisableRedis === undefined) {
      delete process.env.DISABLE_REDIS;
      return;
    }

    process.env.DISABLE_REDIS = originalDisableRedis;
  });

  it('serves the health endpoint', async () => {
    await request(app.getHttpServer())
      .get('/v1/health')
      .expect(200)
      .expect({ status: 'ok', service: 'dreamflow-api' });
  });

  it('rejects invalid circle creation payloads', async () => {
    await request(app.getHttpServer())
      .post('/v1/circles')
      .send({ name: 'Incomplete Circle', type: 'family' })
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('name, type, and userId are required');
      });
  });

  it('creates circles and returns user circle state', async () => {
    const createResponse = await request(app.getHttpServer())
      .post('/v1/circles')
      .send({ name: 'Integration Circle', type: 'family', userId: 'user-a' })
      .expect(201);

    expect(createResponse.body).toMatchObject({
      name: 'Integration Circle',
      type: 'family',
      members: ['user-a']
    });

    const circleId = createResponse.body.id;

    await request(app.getHttpServer())
      .post(`/v1/circles/${circleId}/members`)
      .send({ userId: 'user-b' })
      .expect(201)
      .expect(response => {
        expect(response.body.members).toEqual(['user-a', 'user-b']);
      });

    await request(app.getHttpServer())
      .get('/v1/circles/user/user-b')
      .expect(200)
      .expect(response => {
        expect(response.body).toHaveLength(1);
        expect(response.body[0].id).toBe(circleId);
      });

    await request(app.getHttpServer())
      .get(`/v1/circles/${circleId}/member-count`)
      .expect(200)
      .expect({ circleId, memberCount: 2 });
  });

  it('ingests presence and exposes user presence and history', async () => {
    await request(app.getHttpServer())
      .post('/v1/presence/location')
      .send({
        userId: 'presence-user',
        lat: 37.7749,
        lng: -122.4194,
        accuracy: 6.5,
        speed: 2.3
      })
      .expect(201)
      .expect(response => {
        expect(response.body.accepted).toBe(true);
        expect(response.body.event).toMatchObject({
          userId: 'presence-user',
          lat: 37.7749,
          lng: -122.4194,
          accuracy: 6.5,
          speed: 2.3
        });
      });

    await request(app.getHttpServer())
      .get('/v1/presence/user/presence-user')
      .expect(200)
      .expect(response => {
        expect(response.body).toMatchObject({
          userId: 'presence-user',
          isActive: true,
          lastLocation: expect.objectContaining({ lat: 37.7749, lng: -122.4194 })
        });
      });

    await request(app.getHttpServer())
      .get('/v1/presence/user/presence-user/history?limit=10')
      .expect(200)
      .expect(response => {
        expect(response.body.count).toBe(1);
        expect(response.body.history[0]).toMatchObject({ userId: 'presence-user' });
      });
  });

  it('rejects invalid presence batch payloads', async () => {
    await request(app.getHttpServer())
      .post('/v1/presence/batch')
      .send({ userIds: 'presence-user' })
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('userIds must be an array');
      });
  });

  it('creates and manages alerts over HTTP', async () => {
    const circleResponse = await request(app.getHttpServer())
      .post('/v1/circles')
      .send({ name: 'Alert Circle', type: 'care', userId: 'alert-user' })
      .expect(201);

    const circleId = circleResponse.body.id;

    const alertResponse = await request(app.getHttpServer())
      .post('/v1/alerts/sos')
      .send({
        userId: 'alert-user',
        circleId,
        lat: 37.7749,
        lng: -122.4194
      })
      .expect(201);

    expect(alertResponse.body.accepted).toBe(true);
    expect(alertResponse.body.alert).toMatchObject({
      circleId,
      userId: 'alert-user',
      type: 'sos',
      acknowledged: false
    });

    const alertId = alertResponse.body.alert.id;

    await request(app.getHttpServer())
      .get(`/v1/alerts/circle/${circleId}`)
      .expect(200)
      .expect(response => {
        expect(response.body.count).toBe(1);
        expect(response.body.alerts[0].id).toBe(alertId);
      });

    await request(app.getHttpServer())
      .post(`/v1/alerts/${alertId}/acknowledge`)
      .expect(201)
      .expect(response => {
        expect(response.body.acknowledged).toBe(true);
      });

    await request(app.getHttpServer())
      .post(`/v1/alerts/${alertId}/resolve`)
      .expect(201)
      .expect(response => {
        expect(response.body.resolvedAt).toBeDefined();
      });
  });

  it('returns not-found style bad requests for missing circle and alert resources', async () => {
    await request(app.getHttpServer())
      .get('/v1/circles/circle-missing')
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('Circle circle-missing not found');
      });

    await request(app.getHttpServer())
      .get('/v1/alerts/alert-missing')
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('Alert alert-missing not found');
      });
  });

  it('rejects invalid SOS requests', async () => {
    await request(app.getHttpServer())
      .post('/v1/alerts/sos')
      .send({ userId: 'alert-user' })
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('userId and circleId are required');
      });
  });
});