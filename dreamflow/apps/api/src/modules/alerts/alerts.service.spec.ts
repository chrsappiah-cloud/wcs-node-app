import type { Queue } from 'bullmq';
import { AlertsService } from './alerts.service';

describe('AlertsService', () => {
  let service: AlertsService;
  let notificationQueue: { add: jest.Mock };

  beforeEach(() => {
    service = new AlertsService();
    notificationQueue = { add: jest.fn().mockResolvedValue(undefined) };
    service.setNotificationQueue(notificationQueue as unknown as Queue);
  });

  it('creates alerts, indexes them, and enqueues notifications', async () => {
    const alert = await service.createAlert('circle-1', 'user-1', 'sos', 'Need help now');

    expect(service.getAlert(alert.id)).toEqual(alert);
    expect(service.getCircleAlerts('circle-1')).toEqual([alert]);
    expect(service.getUserAlerts('user-1')).toEqual([alert]);
    expect(notificationQueue.add).toHaveBeenCalledWith(
      'send-alert-notification',
      expect.objectContaining({ alertId: alert.id, circleId: 'circle-1', userId: 'user-1' }),
      expect.objectContaining({ attempts: 3, removeOnComplete: true })
    );
  });

  it('acknowledges, resolves, and filters recent unresolved alerts', async () => {
    const recentAlert = await service.createAlert('circle-1', 'user-1', 'arrival', 'Arrived home');
    const oldAlert = await service.createAlert('circle-1', 'user-1', 'departure', 'Left work');
    oldAlert.createdAt = new Date(Date.now() - 120 * 60_000).toISOString();

    expect(service.acknowledgeAlert(recentAlert.id)?.acknowledged).toBe(true);
    expect(service.getUnresolvedAlerts('circle-1')).toHaveLength(2);

    const resolvedAlert = service.resolveAlert(oldAlert.id);
    expect(resolvedAlert?.resolvedAt).toBeDefined();
    expect(service.getUnresolvedAlerts('circle-1')).toEqual([recentAlert]);
    expect(service.getRecentAlerts('circle-1', 60)).toEqual([recentAlert]);
  });
});