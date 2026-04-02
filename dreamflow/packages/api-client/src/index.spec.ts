describe('api-client', () => {
  const originalFetch = global.fetch;
  const originalApiUrl = process.env.DREAMFLOW_API_URL;

  beforeEach(() => {
    jest.resetModules();
  });

  afterEach(() => {
    global.fetch = originalFetch;
    process.env.DREAMFLOW_API_URL = originalApiUrl;
  });

  it('uses the configured base URL for health requests', async () => {
    process.env.DREAMFLOW_API_URL = 'http://example.test/v1';
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ status: 'ok', service: 'dreamflow-api' })
    });
    global.fetch = fetchMock as typeof fetch;

    const { getHealth } = await import('./index');
    const health = await getHealth();

    expect(fetchMock).toHaveBeenCalledWith('http://example.test/v1/health');
    expect(health).toEqual({ status: 'ok', service: 'dreamflow-api' });
  });

  it('throws when the health check fails', async () => {
    const fetchMock = jest.fn().mockResolvedValue({ ok: false, json: async () => ({}) });
    global.fetch = fetchMock as typeof fetch;

    const { getHealth } = await import('./index');

    await expect(getHealth()).rejects.toThrow('Health check failed');
  });
});