import { Injectable } from '@nestjs/common';
import { Queue } from 'bullmq';

export interface LocationEvent {
  userId: string;
  lat: number;
  lng: number;
  accuracy: number;
  speed?: number;
  recordedAt: string;
  processedAt: string;
}

export interface UserPresence {
  userId: string;
  lastLocation: LocationEvent;
  isActive: boolean;
  batteryLevel?: number;
}

@Injectable()
export class PresenceService {
  private presenceMap = new Map<string, UserPresence>();
  private locationHistory = new Map<string, LocationEvent[]>(); // userId -> events
  private geofenceQueue: Queue | null = null;
  private presenceQueue: Queue | null = null;

  private readonly queueJobOptions = {
    attempts: 3,
    backoff: { type: 'exponential' as const, delay: 500 },
    removeOnComplete: true,
    removeOnFail: false
  };

  setQueues(geofenceQueue: Queue, presenceQueue: Queue) {
    this.geofenceQueue = geofenceQueue;
    this.presenceQueue = presenceQueue;
  }

  async ingestLocation(
    userId: string,
    lat: number,
    lng: number,
    accuracy: number,
    speed?: number
  ): Promise<LocationEvent> {
    const recordedAt = new Date().toISOString();
    const event: LocationEvent = {
      userId,
      lat,
      lng,
      accuracy,
      speed,
      recordedAt,
      processedAt: recordedAt
    };

    // Store in history
    if (!this.locationHistory.has(userId)) {
      this.locationHistory.set(userId, []);
    }
    const history = this.locationHistory.get(userId)!;
    history.push(event);
    // Keep last 100 events
    if (history.length > 100) {
      history.shift();
    }

    // Update presence
    this.presenceMap.set(userId, {
      userId,
      lastLocation: event,
      isActive: true
    });

    // Enqueue for geofence processing
    if (this.geofenceQueue) {
      await this.geofenceQueue.add('evaluate-geofence', { userId, lat, lng, recordedAt }, this.queueJobOptions);
    }

    // Enqueue for presence broadcast
    if (this.presenceQueue) {
      await this.presenceQueue.add(
        'broadcast-location',
        { userId, lat, lng, accuracy, recordedAt },
        this.queueJobOptions
      );
    }

    return event;
  }

  getPresence(userId: string): UserPresence | null {
    return this.presenceMap.get(userId) || null;
  }

  getLocationHistory(userId: string, limit: number = 50): LocationEvent[] {
    const history = this.locationHistory.get(userId) || [];
    return history.slice(-limit);
  }

  setUserActive(userId: string, isActive: boolean): void {
    const presence = this.presenceMap.get(userId);
    if (presence) {
      presence.isActive = isActive;
    }
  }

  getBatchPresence(userIds: string[]): Map<string, UserPresence | null> {
    const result = new Map<string, UserPresence | null>();
    for (const userId of userIds) {
      result.set(userId, this.presenceMap.get(userId) || null);
    }
    return result;
  }

  clearStalePresence(staleAfterMs: number = 300000): string[] {
    const now = Date.now();
    const staleUserIds: string[] = [];

    this.presenceMap.forEach((presence, userId) => {
      const lastUpdateTime = new Date(presence.lastLocation.processedAt).getTime();
      if (now - lastUpdateTime > staleAfterMs) {
        this.presenceMap.delete(userId);
        staleUserIds.push(userId);
      }
    });

    return staleUserIds;
  }
}
