const API_URL = (process.env.API_URL || 'http://localhost:3000/v1').replace(/\/+$/, '');
const AUTH_KEY = process.env.API_AUTH_KEY;
const AUTH_TOKEN = process.env.API_AUTH_TOKEN;

function authHeaders() {
  const headers = {};
  if (AUTH_KEY) {
    headers['x-api-key'] = AUTH_KEY;
  }
  if (AUTH_TOKEN) {
    headers.authorization = `Bearer ${AUTH_TOKEN}`;
  }
  return headers;
}

async function requestJson(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'content-type': 'application/json',
      ...authHeaders(),
      ...(options.headers || {})
    }
  });

  let body = {};
  try {
    body = await response.json();
  } catch {
    body = {};
  }

  return { ok: response.ok, status: response.status, body };
}

function ensureProvidersShape(payload) {
  if (!payload || typeof payload !== 'object') return false;
  if (!Array.isArray(payload.configuredProviders)) return false;
  if (!payload.defaults || typeof payload.defaults !== 'object') return false;
  return true;
}

async function run() {
  console.log(`GenAI smoke target: ${API_URL}`);

  const providersRes = await requestJson('/genai/providers');
  if (!providersRes.ok) {
    throw new Error(`Provider status failed: HTTP ${providersRes.status} ${JSON.stringify(providersRes.body)}`);
  }

  if (!ensureProvidersShape(providersRes.body)) {
    throw new Error('Provider status payload shape mismatch');
  }

  const configured = providersRes.body.configuredProviders;
  console.log(`Configured providers: ${configured.length ? configured.join(', ') : 'none'}`);

  const generateRes = await requestJson('/genai/generate', {
    method: 'POST',
    body: JSON.stringify({
      prompt: 'Return one short health check sentence.',
      provider: 'auto',
      maxTokens: 100,
      temperature: 0.2
    })
  });

  if (configured.length === 0) {
    if (generateRes.ok) {
      throw new Error('Expected generation to fail when no providers are configured');
    }

    const message = JSON.stringify(generateRes.body || {});
    if (!message.includes('No configured AI provider succeeded')) {
      throw new Error(
        `Expected not-configured fallback error but got HTTP ${generateRes.status} ${message}`
      );
    }

    console.log('Auto fallback behavior verified for no-provider configuration.');
    console.log('GenAI smoke test passed.');
    return;
  }

  if (!generateRes.ok) {
    throw new Error(`Generation failed: HTTP ${generateRes.status} ${JSON.stringify(generateRes.body)}`);
  }

  const text = generateRes.body?.text;
  const provider = generateRes.body?.provider;
  if (typeof text !== 'string' || !text.trim()) {
    throw new Error('Generation response text is missing or empty');
  }
  if (typeof provider !== 'string' || !provider.trim()) {
    throw new Error('Generation response provider is missing');
  }

  console.log(`Generation succeeded via provider: ${provider}`);
  console.log('GenAI smoke test passed.');
}

run().catch(error => {
  console.error(`GenAI smoke test failed: ${error.message}`);
  process.exitCode = 1;
});
