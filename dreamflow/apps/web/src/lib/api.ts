const runtimeDefaultApiBase = (() => {
  if (typeof window === 'undefined') return 'http://localhost:3000';
  const host = window.location.hostname;
  const isLocalHost = host === 'localhost' || host === '127.0.0.1';
  return isLocalHost ? 'http://localhost:3000' : window.location.origin;
})();

const RAW_API_BASE = import.meta.env.VITE_API_BASE_URL ?? runtimeDefaultApiBase;
const API_BASE = RAW_API_BASE.replace(/\/+$/, '');
const API_V1_BASE = /\/v1$/i.test(API_BASE) ? API_BASE : `${API_BASE}/v1`;

export interface LandingPayload {
  hero: {
    title: string;
    subtitle: string;
    primaryCta: string;
  };
  phases: Array<{ step: number; name: string; detail: string }>;
  services: Array<{ key: string; title: string; blurb: string }>;
}

export async function getLandingContent(): Promise<LandingPayload> {
  const response = await fetch(`${API_V1_BASE}/wcs-platform/landing-content`);
  if (!response.ok) {
    throw new Error('Unable to load landing content');
  }
  return response.json() as Promise<LandingPayload>;
}

export async function postBookCall(payload: {
  name: string;
  email: string;
  phone?: string;
  notes?: string;
}) {
  const response = await fetch(`${API_V1_BASE}/wcs-platform/book-call`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    throw new Error('Unable to submit call request');
  }

  return response.json();
}

export interface MarketingMetricsPayload {
  sessionsGrowth: number[];
  featureMix: {
    artGen: number;
    musicCues: number;
    breathing: number;
    coachNotes: number;
  };
  mvpProgress: number[];
  funnel: Array<{ stage: string; value: number }>;
}

export async function getMarketingMetrics(): Promise<MarketingMetricsPayload> {
  const response = await fetch(`${API_V1_BASE}/wcs-platform/metrics`);
  if (!response.ok) {
    throw new Error('Unable to load marketing metrics');
  }
  return response.json() as Promise<MarketingMetricsPayload>;
}

export async function postConsult(payload: {
  name: string;
  email: string;
  channel?: string;
  details?: string;
}) {
  const response = await fetch(`${API_V1_BASE}/wcs-platform/consult`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    throw new Error('Unable to submit consult request');
  }

  return response.json();
}

export type GenAIProviderName = 'openai' | 'anthropic' | 'gemini' | 'huggingface';

export interface GenAIProvidersPayload {
  configuredProviders: GenAIProviderName[];
  defaults: {
    openai: string;
    anthropic: string;
    gemini: string;
    huggingface: string;
  };
}

export interface GenerateTextPayload {
  prompt: string;
  provider?: 'auto' | GenAIProviderName;
  model?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface GenerateTextResponse {
  provider: GenAIProviderName;
  text: string;
  generatedAt: string;
  fallbackAttempts?: Array<{ provider: GenAIProviderName; reason: string }>;
}

export async function getGenAIProviders(): Promise<GenAIProvidersPayload> {
  const response = await fetch(`${API_V1_BASE}/genai/providers`);
  if (!response.ok) {
    throw new Error('Unable to load GenAI provider status');
  }
  return response.json() as Promise<GenAIProvidersPayload>;
}

export async function generateText(payload: GenerateTextPayload): Promise<GenerateTextResponse> {
  const response = await fetch(`${API_V1_BASE}/genai/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    throw new Error('Unable to generate AI text');
  }

  return response.json() as Promise<GenerateTextResponse>;
}
