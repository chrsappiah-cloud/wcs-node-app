import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from './app.module';
import { USER_ROLES } from './common/auth/roles.constants';

describe('API security contracts', () => {
  let app: INestApplication;
  const originalDisableRedis = process.env.DISABLE_REDIS;
  const originalApiAuthRequired = process.env.API_AUTH_REQUIRED;
  const originalApiAuthKey = process.env.API_AUTH_KEY;
  const originalApiAuthToken = process.env.API_AUTH_TOKEN;

  beforeAll(async () => {
    process.env.DISABLE_REDIS = 'true';

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: {
          enableImplicitConversion: true
        }
      })
    );
    app.setGlobalPrefix('v1');
    await app.init();
  });

  afterAll(async () => {
    await app.close();

    if (originalDisableRedis === undefined) {
      delete process.env.DISABLE_REDIS;
    } else {
      process.env.DISABLE_REDIS = originalDisableRedis;
    }

    if (originalApiAuthRequired === undefined) {
      delete process.env.API_AUTH_REQUIRED;
    } else {
      process.env.API_AUTH_REQUIRED = originalApiAuthRequired;
    }

    if (originalApiAuthKey === undefined) {
      delete process.env.API_AUTH_KEY;
    } else {
      process.env.API_AUTH_KEY = originalApiAuthKey;
    }

    if (originalApiAuthToken === undefined) {
      delete process.env.API_AUTH_TOKEN;
    } else {
      process.env.API_AUTH_TOKEN = originalApiAuthToken;
    }
  });

  it('rejects unknown payload fields when whitelist is enforced', async () => {
    await request(app.getHttpServer())
      .post('/v1/circles')
      .send({
        name: 'Contract Circle',
        type: 'family',
        userId: 'contract-user',
        unexpected: 'blocked'
      })
      .expect(400)
      .expect(response => {
        expect(response.body.message).toContain('property unexpected should not exist');
      });
  });

  it('enforces alert query bounds for limit', async () => {
    await request(app.getHttpServer())
      .get('/v1/alerts/circle/circle-any?limit=0')
      .expect(400)
      .expect(response => {
        expect(response.body.message).toBe('limit must be between 1 and 100');
      });
  });

  it('enforces auth when API_AUTH_REQUIRED is enabled', async () => {
    process.env.API_AUTH_REQUIRED = 'true';
    process.env.API_AUTH_KEY = 'contract-secret';

    await request(app.getHttpServer()).get('/v1/circles/user/contract-user').expect(401);

    await request(app.getHttpServer())
      .get('/v1/circles/user/contract-user')
      .set('x-api-key', 'contract-secret')
      .expect(403);

    await request(app.getHttpServer())
      .get('/v1/circles/user/contract-user')
      .set('x-api-key', 'contract-secret')
      .set('x-user-role', USER_ROLES.VIEWER)
      .expect(200);

    process.env.API_AUTH_REQUIRED = 'false';
    delete process.env.API_AUTH_KEY;
  });

  it('returns 503 when auth is required but credentials are not configured', async () => {
    process.env.API_AUTH_REQUIRED = 'true';
    delete process.env.API_AUTH_KEY;
    delete process.env.API_AUTH_TOKEN;

    await request(app.getHttpServer())
      .get('/v1/circles/user/contract-user')
      .expect(503)
      .expect(response => {
        expect(response.body.message).toBe('Authentication is required but not configured');
      });

    process.env.API_AUTH_REQUIRED = 'false';
  });

  it('includes requestId in error response envelopes', async () => {
    const customId = 'test-envelope-id';
    await request(app.getHttpServer())
      .post('/v1/circles')
      .set('x-request-id', customId)
      .send({ name: 'Test', type: 'family', userId: 'u1', badField: 'x' })
      .expect(400)
      .expect(response => {
        expect(response.body.requestId).toBe(customId);
      });
  });

  it('echoes x-request-id as response header', async () => {
    const customId = 'echo-header-id';
    const response = await request(app.getHttpServer())
      .get('/v1/health')
      .set('x-request-id', customId);
    expect(response.headers['x-request-id']).toBe(customId);
  });
});