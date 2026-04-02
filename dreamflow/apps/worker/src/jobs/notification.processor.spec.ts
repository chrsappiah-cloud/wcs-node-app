import { NotificationProcessor } from './notification.processor';

describe('NotificationProcessor', () => {
  let processor: NotificationProcessor;

  beforeEach(() => {
    processor = new NotificationProcessor();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('sends notifications and records aggregate delivery stats', async () => {
    jest.spyOn(Math, 'random').mockReturnValue(0.9);

    const result = await processor.sendAlertNotification({
      alertId: 'alert-1',
      circleId: 'circle-1',
      userId: 'user-1',
      type: 'sos',
      message: 'SOS triggered',
      recipients: ['user-2', 'user-3']
    });

    expect(result.recipients).toBe(2);
    expect(result.deliveries).toEqual([
      { recipient: 'user-2', channel: 'push', status: 'sent' },
      { recipient: 'user-3', channel: 'push', status: 'sent' }
    ]);
    expect(processor.getNotificationLog()).toHaveLength(1);
    expect(processor.getNotificationStats()).toEqual({
      total: 1,
      byType: { sos: 1 }
    });
  });

  it('can force failed deliveries for system failure-path coverage', async () => {
    process.env.DREAMFLOW_FORCE_NOTIFICATION_FAILURE = 'true';

    const result = await processor.sendAlertNotification({
      alertId: 'alert-2',
      circleId: 'circle-1',
      userId: 'user-1',
      type: 'sos',
      message: 'SOS triggered',
      recipients: ['user-2']
    });

    expect(result.deliveries).toEqual([
      { recipient: 'user-2', channel: 'push', status: 'failed' }
    ]);

    delete process.env.DREAMFLOW_FORCE_NOTIFICATION_FAILURE;
  });

  it('throws when repeated worker failure mode is enabled', async () => {
    process.env.DREAMFLOW_THROW_NOTIFICATION_FAILURE = 'true';

    await expect(
      processor.sendAlertNotification({
        alertId: 'alert-3',
        circleId: 'circle-1',
        userId: 'user-1',
        type: 'sos',
        message: 'SOS triggered',
        recipients: ['user-2']
      })
    ).rejects.toThrow('Forced notification delivery failure');

    delete process.env.DREAMFLOW_THROW_NOTIFICATION_FAILURE;
  });
});