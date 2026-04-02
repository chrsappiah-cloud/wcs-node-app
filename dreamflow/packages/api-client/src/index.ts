export const apiBaseUrl = process.env.DREAMFLOW_API_URL ?? 'http://localhost:3000/v1';

export interface Circle {
  id: string;
  name: string;
  type: 'family' | 'care' | 'team';
  createdAt: string;
  members: string[];
  geofences: Array<{
    id: string;
    lat: number;
    lng: number;
    radiusMeters: number;
    name: string;
  }>;
}

export interface UserPresence {
  userId: string;
  isActive: boolean;
  batteryLevel?: number;
  lastLocation: null | {
    userId: string;
    lat: number;
    lng: number;
    accuracy: number;
    speed?: number;
    recordedAt: string;
    processedAt: string;
  };
}

export interface Alert {
  id: string;
  circleId: string;
  userId: string;
  type: 'arrival' | 'departure' | 'sos' | 'low_battery' | 'device_offline' | 'inactivity';
  geofenceId?: string;
  message: string;
  createdAt: string;
  resolvedAt?: string;
  acknowledged: boolean;
}

async function getJson<T>(path: string): Promise<T> {
  const res = await fetch(`${apiBaseUrl}${path}`);
  if (!res.ok) {
    throw new Error(`Request failed: ${res.status} ${res.statusText}`);
  }
  return res.json() as Promise<T>;
}

async function postJson<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${apiBaseUrl}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: body ? JSON.stringify(body) : undefined
  });

  if (!res.ok) {
    throw new Error(`Request failed: ${res.status} ${res.statusText}`);
  }

  return res.json() as Promise<T>;
}

export async function getHealth(): Promise<{ status: string; service: string }> {
  return getJson('/health');
}

export async function getUserCircles(userId: string): Promise<Circle[]> {
  return getJson(`/circles/user/${encodeURIComponent(userId)}`);
}

export async function getCircle(circleId: string): Promise<Circle> {
  return getJson(`/circles/${encodeURIComponent(circleId)}`);
}

export async function getUserPresence(userId: string): Promise<UserPresence> {
  return getJson(`/presence/user/${encodeURIComponent(userId)}`);
}

export async function getUserAlerts(
  userId: string,
  limit: number = 10
): Promise<{ userId: string; alerts: Alert[]; count: number }> {
  return getJson(`/alerts/user/${encodeURIComponent(userId)}?limit=${limit}`);
}

export async function getCircleRecentAlerts(
  circleId: string,
  minutes: number = 120
): Promise<{ circleId: string; recent: Alert[]; count: number; minutes: number }> {
  return getJson(`/alerts/circle/${encodeURIComponent(circleId)}/recent?minutes=${minutes}`);
}

export async function createCircle(input: {
  name: string;
  type: 'family' | 'care' | 'team';
  userId: string;
}): Promise<Circle> {
  return postJson('/circles', input);
}

export async function acknowledgeAlert(alertId: string): Promise<Alert> {
  return postJson(`/alerts/${encodeURIComponent(alertId)}/acknowledge`);
}

export async function resolveAlert(alertId: string): Promise<Alert> {
  return postJson(`/alerts/${encodeURIComponent(alertId)}/resolve`);
}

export async function postLocationPing(input: {
  userId: string;
  lat: number;
  lng: number;
  accuracy: number;
  speed?: number;
}): Promise<{
  accepted: boolean;
  event: {
    userId: string;
    lat: number;
    lng: number;
    accuracy: number;
    speed?: number;
    recordedAt: string;
    processedAt: string;
  };
  timestamp: string;
}> {
  return postJson('/presence/location', input);
}
