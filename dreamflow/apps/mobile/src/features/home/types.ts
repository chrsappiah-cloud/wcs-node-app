import type { Alert, Circle, UserPresence } from '@dreamflow/api-client';

export interface DashboardState {
  healthStatus: string;
  circles: Circle[];
  primaryCircle: Circle | null;
  presence: UserPresence | null;
  alerts: Alert[];
  timeline: Array<{ id: string; title: string; detail: string; time: string }>;
  signalHealth: number;
}
