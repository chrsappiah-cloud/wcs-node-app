import { Injectable, Logger } from '@nestjs/common';

export interface AlertNotificationJob {
  alertId: string;
  circleId: string;
  userId: string;
  type: 'arrival' | 'departure' | 'sos' | 'low_battery' | 'device_offline' | 'inactivity';
  message: string;
  recipients?: string[];
}

@Injectable()
export class NotificationProcessor {
  private logger = new Logger('NotificationProcessor');
  private notificationLog: any[] = [];

  async sendAlertNotification(data: AlertNotificationJob) {
    const processingDelayMs = parseInt(process.env.DREAMFLOW_NOTIFICATION_PROCESSING_DELAY_MS || '0', 10);
    if (processingDelayMs > 0) {
      await new Promise(resolve => setTimeout(resolve, processingDelayMs));
    }

    this.logger.log(`Sending notification for alert ${data.alertId}: ${data.type}`);

    // Mock: Resolve recipients if not provided
    const recipients = data.recipients || [data.userId];

    // Mock: Send via multiple channels (push, SMS, email)
    const deliveries = await Promise.all(
      recipients.map(recipientId => this.sendToRecipient(recipientId, data))
    );

    const result = {
      alertId: data.alertId,
      type: data.type,
      message: data.message,
      recipients: recipients.length,
      deliveries: deliveries.map(d => ({
        recipient: d.recipient,
        channel: d.channel,
        status: d.status
      })),
      sentAt: new Date().toISOString()
    };

    this.notificationLog.push(result);

    return result;
  }

  private async sendToRecipient(
    recipientId: string,
    notification: AlertNotificationJob
  ): Promise<{ recipient: string; channel: string; status: 'sent' | 'failed' | 'queued' }> {
    // Mock: Deliver via push notification
    this.logger.debug(
      `Push notification to ${recipientId}: ${notification.type} - ${notification.message}`
    );

    // Simulate delivery delay
    await new Promise(resolve => setTimeout(resolve, 100));

    if (process.env.DREAMFLOW_THROW_NOTIFICATION_FAILURE === 'true') {
      throw new Error('Forced notification delivery failure');
    }

    // Mock: 90% success rate
    const forceFailure = process.env.DREAMFLOW_FORCE_NOTIFICATION_FAILURE === 'true';
    const success = !forceFailure && Math.random() > 0.1;

    if (success) {
      return { recipient: recipientId, channel: 'push', status: 'sent' };
    } else {
      this.logger.warn(`Failed to deliver notification to ${recipientId}`);
      return { recipient: recipientId, channel: 'push', status: 'failed' };
    }
  }

  getNotificationLog(limit: number = 100) {
    return this.notificationLog.slice(-limit);
  }

  getNotificationStats() {
    const total = this.notificationLog.length;
    const byType = this.notificationLog.reduce(
      (acc, n) => {
        acc[n.type] = (acc[n.type] || 0) + 1;
        return acc;
      },
      {} as Record<string, number>
    );

    return { total, byType };
  }
}
