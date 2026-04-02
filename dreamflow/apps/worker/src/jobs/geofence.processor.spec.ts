import { GeofenceProcessor } from './geofence.processor';

describe('GeofenceProcessor', () => {
  let processor: GeofenceProcessor;

  beforeEach(() => {
    processor = new GeofenceProcessor();
  });

  it('emits arrival and departure transitions based on prior geofence state', async () => {
    const arrival = await processor.processGeofenceEvaluation({
      userId: 'user-1',
      lat: 37.7749,
      lng: -122.4194,
      recordedAt: new Date().toISOString()
    });

    expect(arrival.alertsTriggered).toBe(1);
    expect(arrival.alerts[0]).toMatchObject({ type: 'arrival', geofenceId: 'geo-home' });

    const noTransition = await processor.processGeofenceEvaluation({
      userId: 'user-1',
      lat: 37.7749,
      lng: -122.4194,
      recordedAt: new Date().toISOString()
    });

    expect(noTransition.alertsTriggered).toBe(0);

    const departure = await processor.processGeofenceEvaluation({
      userId: 'user-1',
      lat: 0,
      lng: 0,
      recordedAt: new Date().toISOString()
    });

    expect(departure.alertsTriggered).toBe(1);
    expect(departure.alerts[0]).toMatchObject({ type: 'departure', geofenceId: 'geo-home' });
  });

  it('rejects malformed job payloads', async () => {
    await expect(
      processor.processGeofenceEvaluation({
        userId: 'user-1',
        lat: Number.NaN,
        lng: -122.4194,
        recordedAt: new Date().toISOString()
      })
    ).rejects.toThrow('Invalid geofence job payload');
  });
});