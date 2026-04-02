import type { AlertType, LivePresence } from './index';

describe('types', () => {
  it('supports valid alert and presence shapes', () => {
    const alertType: AlertType = 'sos';
    const presence: LivePresence = {
      userId: 'user-1',
      lat: 37.7749,
      lng: -122.4194,
      accuracy: 5,
      activity: 'walking',
      recordedAt: '2026-04-02T00:00:00.000Z'
    };

    expect(alertType).toBe('sos');
    expect(presence).toMatchObject({ userId: 'user-1', activity: 'walking' });
  });
});