import { PresenceProcessor } from './presence.processor';

describe('PresenceProcessor', () => {
  let processor: PresenceProcessor;

  beforeEach(() => {
    processor = new PresenceProcessor();
  });

  it('flags suspiciously fast movement as an anomaly', async () => {
    await processor.processBroadcast({
      userId: 'user-1',
      lat: 37.7749,
      lng: -122.4194,
      accuracy: 5,
      recordedAt: '2026-04-02T00:00:00.000Z'
    });

    const result = await processor.processBroadcast({
      userId: 'user-1',
      lat: 40.7128,
      lng: -74.006,
      accuracy: 5,
      recordedAt: '2026-04-02T00:00:01.000Z'
    });

    expect(result).toEqual(
      expect.objectContaining({
        processed: true,
        anomaly: true,
        message: 'Suspiciously fast movement detected'
      })
    );
    expect(processor.getRecentLocations('user-1')).toHaveLength(2);
  });
});