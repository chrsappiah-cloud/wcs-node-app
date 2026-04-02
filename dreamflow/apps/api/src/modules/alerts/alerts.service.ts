import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Queue } from 'bullmq';

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

@Injectable()
export class AlertsService {
  private alerts = new Map<string, Alert>();
  private circleAlerts = new Map<string, string[]>(); // circleId -> alertIds
  private userAlerts = new Map<string, string[]>(); // userId -> alertIds
  private notificationQueue: Queue | null = null;

  private readonly queueJobOptions = {
    attempts: 3,
    backoff: { type: 'exponential' as const, delay: 500 },
    removeOnComplete: true,
    removeOnFail: false
  };

  setNotificationQueue(queue: Queue) {
    this.notificationQueue = queue;
  }

  async createAlert(
    circleId: string,
    userId: string,
    type: Alert['type'],
    message: string,
    geofenceId?: string
  ): Promise<Alert> {
    const id = `alert-${randomUUID()}`;
    const alert: Alert = {
      id,
      circleId,
      userId,
      type,
      geofenceId,
      message,
      createdAt: new Date().toISOString(),
      acknowledged: false
    };

    this.alerts.set(id, alert);

    // Index by circle
    if (!this.circleAlerts.has(circleId)) {
      this.circleAlerts.set(circleId, []);
    }
    this.circleAlerts.get(circleId)!.push(id);

    // Index by user
    if (!this.userAlerts.has(userId)) {
      this.userAlerts.set(userId, []);
    }
    this.userAlerts.get(userId)!.push(id);

    // Enqueue for notification delivery
    if (this.notificationQueue) {
      await this.notificationQueue.add(
        'send-alert-notification',
        {
          alertId: id,
          circleId,
          userId,
          type,
          message,
          recipients: undefined // Will be resolved by worker
        },
        this.queueJobOptions
      );
    }

    return alert;
  }

  getAlert(id: string): Alert | null {
    return this.alerts.get(id) || null;
  }

  getCircleAlerts(circleId: string, limit: number = 50): Alert[] {
    const alertIds = this.circleAlerts.get(circleId) || [];
    return alertIds
      .slice(-limit)
      .map(id => this.alerts.get(id)!)
      .filter(Boolean);
  }

  getUserAlerts(userId: string, limit: number = 50): Alert[] {
    const alertIds = this.userAlerts.get(userId) || [];
    return alertIds
      .slice(-limit)
      .map(id => this.alerts.get(id)!)
      .filter(Boolean);
  }

  acknowledgeAlert(alertId: string): Alert | null {
    const alert = this.alerts.get(alertId);
    if (alert) {
      alert.acknowledged = true;
      return alert;
    }
    return null;
  }

  resolveAlert(alertId: string): Alert | null {
    const alert = this.alerts.get(alertId);
    if (alert) {
      alert.resolvedAt = new Date().toISOString();
      return alert;
    }
    return null;
  }

  getUnresolvedAlerts(circleId: string): Alert[] {
    const alertIds = this.circleAlerts.get(circleId) || [];
    return alertIds
      .map(id => this.alerts.get(id)!)
      .filter(a => a && !a.resolvedAt);
  }

  getRecentAlerts(circleId: string, minutes: number = 60): Alert[] {
    const since = new Date(Date.now() - minutes * 60000);
    const alertIds = this.circleAlerts.get(circleId) || [];
    return alertIds
      .map(id => this.alerts.get(id)!)
      .filter(a => a && new Date(a.createdAt) > since);
  }
}
