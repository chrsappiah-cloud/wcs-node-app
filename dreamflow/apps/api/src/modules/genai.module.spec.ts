import { Test, TestingModule } from '@nestjs/testing';
import { GenAIModule } from './genai.module';

describe('GenAIModule', () => {
  const envBackup = { ...process.env };

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetModules();
    process.env = { ...envBackup };

    delete process.env.OPENAI_API_KEY;
    delete process.env.ANTHROPIC_API_KEY;
    delete process.env.GOOGLE_AI_API_KEY;
    delete process.env.HUGGINGFACE_API_KEY;
  });

  afterAll(() => {
    process.env = envBackup;
  });

  async function createTestingApp() {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [GenAIModule]
    }).compile();

    const app = moduleRef.createNestApplication();
    await app.init();
    return app;
  }

  it('returns provider status for configured providers', async () => {
    process.env.OPENAI_API_KEY = 'test-openai-key';
    process.env.GOOGLE_AI_API_KEY = 'test-gemini-key';

    const app = await createTestingApp();
    const server = app.getHttpServer();

    const response = await import('supertest').then(({ default: request }) =>
      request(server).get('/genai/providers').expect(200)
    );

    expect(response.body.configuredProviders).toEqual(['openai', 'gemini']);
    expect(response.body.defaults.openai).toBeDefined();
    expect(response.body.defaults.gemini).toBeDefined();

    await app.close();
  });

  it('uses fallback provider when first configured provider fails', async () => {
    process.env.OPENAI_API_KEY = 'test-openai-key';
    process.env.ANTHROPIC_API_KEY = 'test-anthropic-key';

    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        status: 500,
        text: async () => JSON.stringify({ error: 'upstream failure' })
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        text: async () => JSON.stringify({
          content: [{ type: 'text', text: 'Fallback response from Anthropic' }]
        })
      });

    (globalThis as any).fetch = fetchMock;

    const app = await createTestingApp();
    const server = app.getHttpServer();

    const response = await import('supertest').then(({ default: request }) =>
      request(server)
        .post('/genai/generate')
        .send({
          prompt: 'Write a concise summary.',
          provider: 'auto',
          maxTokens: 120,
          temperature: 0.2
        })
        .expect(201)
    );

    expect(response.body.provider).toBe('anthropic');
    expect(response.body.text).toContain('Fallback response from Anthropic');
    expect(response.body.fallbackAttempts).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ provider: 'openai' })
      ])
    );
    expect(fetchMock).toHaveBeenCalledTimes(2);

    await app.close();
  });
});