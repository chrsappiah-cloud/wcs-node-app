import type { Queue } from 'bullmq';
import { PresenceService } from './presence.service';

describe('PresenceService', () => {
  let service: PresenceService;
  let geofenceQueue: { add: jest.Mock };
  let presenceQueue: { add: jest.Mock };

  beforeEach(() => {
    service = new PresenceService();
    geofenceQueue = { add: jest.fn().mockResolvedValue(undefined) };
    presenceQueue = { add: jest.fn().mockResolvedValue(undefined) };
    service.setQueues(geofenceQueue as unknown as Queue, presenceQueue as unknown as Queue);
  });

  it('ingests a location, updates presence, and enqueues downstream jobs', async () => {
    const event = await service.ingestLocation('user-1', 37.7749, -122.4194, 8.1, 2.5);

    expect(event.userId).toBe('user-1');
    expect(service.getPresence('user-1')).toMatchObject({
      userId: 'user-1',
      isActive: true,
      lastLocation: expect.objectContaining({ lat: 37.7749, lng: -122.4194 })
    });
    expect(geofenceQueue.add).toHaveBeenCalledWith(
      'evaluate-geofence',
      expect.objectContaining({ userId: 'user-1', lat: 37.7749, lng: -122.4194 }),
      expect.objectContaining({ attempts: 3, removeOnComplete: true })
    );
    expect(presenceQueue.add).toHaveBeenCalledWith(
      'broadcast-location',
      expect.objectContaining({ userId: 'user-1', accuracy: 8.1 }),
      expect.objectContaining({ removeOnComplete: true })
    );
  });

  it('caps location history and clears stale presence', async () => {
    for (let index = 0; index < 105; index += 1) {
      await service.ingestLocation('user-1', index, index, 5);
    }

    const history = service.getLocationHistory('user-1', 200);
    expect(history).toHaveLength(100);
    expect(history[0]).toMatchObject({ lat: 5, lng: 5 });

    const presence = service.getPresence('user-1');
    expect(presence).not.toBeNull();
    presence!.lastLocation.processedAt = new Date(Date.now() - 10_000).toISOString();

    expect(service.clearStalePresence(1_000)).toEqual(['user-1']);
    expect(service.getPresence('user-1')).toBeNull();
  });
});