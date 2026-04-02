import { Injectable, Logger } from '@nestjs/common';

export interface GeofenceEvaluationJob {
  userId: string;
  lat: number;
  lng: number;
  recordedAt: string;
}

function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth's radius in meters
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

@Injectable()
export class GeofenceProcessor {
  private logger = new Logger('GeofenceProcessor');
  private userGeofenceState = new Map<
    string,
    Map<string, { isInside: boolean; lastCheck: string }>
  >();

  async processGeofenceEvaluation(data: GeofenceEvaluationJob) {
    if (
      !data.userId ||
      !Number.isFinite(data.lat) ||
      !Number.isFinite(data.lng) ||
      !data.recordedAt
    ) {
      throw new Error('Invalid geofence job payload');
    }

    const processingDelayMs = parseInt(process.env.DREAMFLOW_GEOFENCE_PROCESSING_DELAY_MS || '0', 10);
    if (processingDelayMs > 0) {
      await new Promise(resolve => setTimeout(resolve, processingDelayMs));
    }

    this.logger.debug(`Evaluating geofences for user ${data.userId}`);

    // Mock: Lookup user's circles and geofences from DB
    // For now, we'll simulate this with stub data
    const mockCircles = [
      {
        id: 'circle-123',
        name: 'Family',
        geofences: [
          { id: 'geo-home', lat: 37.7749, lng: -122.4194, radiusMeters: 500, name: 'Home' },
          { id: 'geo-work', lat: 37.4419, lng: -122.143, radiusMeters: 300, name: 'Work' }
        ]
      }
    ];

    const alerts: any[] = [];

    for (const circle of mockCircles) {
      for (const geofence of circle.geofences) {
        const distance = calculateDistance(data.lat, data.lng, geofence.lat, geofence.lng);
        const isInside = distance <= geofence.radiusMeters;

        // Track state transitions
        if (!this.userGeofenceState.has(data.userId)) {
          this.userGeofenceState.set(data.userId, new Map());
        }

        const userState = this.userGeofenceState.get(data.userId)!;
        const previousState = userState.get(geofence.id) || { isInside: false, lastCheck: data.recordedAt };

        if (isInside !== previousState.isInside) {
          const eventType = isInside ? 'arrival' : 'departure';
          alerts.push({
            circleId: circle.id,
            userId: data.userId,
            type: eventType,
            geofenceId: geofence.id,
            geofenceName: geofence.name,
            message: `${eventType === 'arrival' ? 'Arrived at' : 'Departed from'} ${geofence.name}`,
            distance,
            timestamp: data.recordedAt
          });

          this.logger.log(
            `Geofence ${eventType}: user ${data.userId} at ${geofence.name} (${distance.toFixed(0)}m)`
          );
        }

        userState.set(geofence.id, { isInside, lastCheck: data.recordedAt });
      }
    }

    return { processed: true, alertsTriggered: alerts.length, alerts };
  }
}
