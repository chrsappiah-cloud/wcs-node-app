import { Injectable, Logger } from '@nestjs/common';

export interface PresenceBroadcastJob {
  userId: string;
  lat: number;
  lng: number;
  accuracy: number;
  recordedAt: string;
}

@Injectable()
export class PresenceProcessor {
  private logger = new Logger('PresenceProcessor');
  private recentLocations = new Map<string, { lat: number; lng: number; timestamp: string }[]>();

  async processBroadcast(data: PresenceBroadcastJob) {
    const processingDelayMs = parseInt(process.env.DREAMFLOW_PRESENCE_PROCESSING_DELAY_MS || '0', 10);
    if (processingDelayMs > 0) {
      await new Promise(resolve => setTimeout(resolve, processingDelayMs));
    }

    this.logger.debug(`Broadcasting presence for user ${data.userId}`);

    // Store location for analytics
    if (!this.recentLocations.has(data.userId)) {
      this.recentLocations.set(data.userId, []);
    }

    const locations = this.recentLocations.get(data.userId)!;
    locations.push({
      lat: data.lat,
      lng: data.lng,
      timestamp: data.recordedAt
    });

    // Keep last 100 locations
    if (locations.length > 100) {
      locations.shift();
    }

    // Mock: Publish to circle members via WebSocket/SSE
    this.logger.log(`Broadcast location for ${data.userId} to circle members`);

    // Mock: Detect anomalies (extremely fast movement, etc.)
    if (locations.length > 1) {
      const prev = locations[locations.length - 2];
      const curr = locations[locations.length - 1];
      const timeMs = new Date(curr.timestamp).getTime() - new Date(prev.timestamp).getTime();

      const distance = this.calculateDistance(prev.lat, prev.lng, curr.lat, curr.lng);
      const speedMph = timeMs > 0 ? (distance / 1609.34 / (timeMs / 3600000)) : 0;

      if (speedMph > 500) {
        // Suspiciously fast
        this.logger.warn(`Anomaly: user ${data.userId} moving at ${speedMph.toFixed(0)} mph`);
        return {
          processed: true,
          anomaly: true,
          message: 'Suspiciously fast movement detected'
        };
      }
    }

    return {
      processed: true,
      anomaly: false,
      message: 'Location broadcast successful'
    };
  }

  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3;
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  getRecentLocations(userId: string, limit: number = 20) {
    const locations = this.recentLocations.get(userId) || [];
    return locations.slice(-limit);
  }
}
