export type AlertType =
  | 'arrival'
  | 'departure'
  | 'sos'
  | 'low_battery'
  | 'device_offline'
  | 'inactivity';

export interface LivePresence {
  userId: string;
  lat: number;
  lng: number;
  accuracy: number;
  batteryLevel?: number;
  activity?: 'still' | 'walking' | 'running' | 'driving';
  recordedAt: string;
}
