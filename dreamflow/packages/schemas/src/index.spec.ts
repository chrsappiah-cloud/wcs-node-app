import {
  createAlertSchema,
  createCircleSchema,
  createCircleResponseSchema,
  createAlertResponseSchema,
  locationPingSchema,
  locationPingResponseSchema,
  sendOtpSchema,
  sendOtpResponseSchema,
  sosSchema,
  sosResponseSchema,
  verifyOtpSchema,
  verifyOtpResponseSchema
} from './index';

describe('schemas', () => {
  it('validates circle creation payloads', () => {
    expect(createCircleSchema.parse({ name: 'Family', type: 'family', userId: 'u1' })).toEqual({
      name: 'Family',
      type: 'family',
      userId: 'u1'
    });
    expect(() => createCircleSchema.parse({ name: 'F', type: 'family', userId: 'u1' })).toThrow();
  });

  it('accepts valid location pings and rejects invalid coordinates', () => {
    expect(
      locationPingSchema.parse({
        userId: 'user-1',
        lat: 37.7749,
        lng: -122.4194,
        accuracy: 4.2,
        recordedAt: '2026-04-02T00:00:00.000Z'
      })
    ).toMatchObject({ userId: 'user-1', lat: 37.7749, lng: -122.4194 });

    expect(() =>
      locationPingSchema.parse({
        userId: 'user-1',
        lat: 120,
        lng: -122.4194,
        accuracy: 4.2,
        recordedAt: '2026-04-02T00:00:00.000Z'
      })
    ).toThrow();
  });

  it('validates OTP send and verify payloads', () => {
    expect(sendOtpSchema.parse({ phone: '+14155552671' })).toEqual({ phone: '+14155552671' });
    expect(verifyOtpSchema.parse({ phone: '+14155552671', code: '123456' })).toEqual({
      phone: '+14155552671',
      code: '123456'
    });

    expect(() => sendOtpSchema.parse({ phone: '4155552671' })).toThrow();
    expect(() => verifyOtpSchema.parse({ phone: '+14155552671', code: '12' })).toThrow();
  });

  it('validates alert contracts for create and sos', () => {
    expect(
      createAlertSchema.parse({
        circleId: 'c1',
        userId: 'u1',
        type: 'sos',
        message: 'Help needed'
      })
    ).toMatchObject({ type: 'sos' });

    expect(sosSchema.parse({ userId: 'u1', circleId: 'c1', lat: 37.77, lng: -122.41 })).toEqual({
      userId: 'u1',
      circleId: 'c1',
      lat: 37.77,
      lng: -122.41
    });

    expect(() => createAlertSchema.parse({ circleId: 'c1', userId: 'u1', type: 'unknown', message: 'x' })).toThrow();
    expect(() => sosSchema.parse({ userId: 'u1', circleId: 'c1', lat: Number.NaN, lng: -122.41 })).toThrow();
  });

  it('validates response contracts', () => {
    const circle = createCircleResponseSchema.parse({
      id: 'circle-1',
      name: 'Family Circle',
      type: 'family',
      createdAt: new Date().toISOString(),
      members: ['user-1'],
      geofences: [
        {
          id: 'gf-1',
          lat: 37.77,
          lng: -122.42,
          radiusMeters: 100,
          name: 'Home'
        }
      ]
    });
    expect(circle.id).toBe('circle-1');

    const ping = locationPingResponseSchema.parse({
      accepted: true,
      event: {
        userId: 'user-1',
        lat: 37.77,
        lng: -122.42,
        accuracy: 12,
        speed: 1.5,
        recordedAt: new Date().toISOString(),
        processedAt: new Date().toISOString(),
      },
      timestamp: new Date().toISOString(),
    });
    expect(ping.accepted).toBe(true);

    expect(sendOtpResponseSchema.parse({ sent: true }).sent).toBe(true);
    expect(verifyOtpResponseSchema.parse({ token: 'jwt-token' }).token).toBe('jwt-token');

    const alert = createAlertResponseSchema.parse({
      id: 'alert-1',
      circleId: 'circle-1',
      userId: 'user-1',
      type: 'arrival',
      geofenceId: 'gf-1',
      message: 'Arrived at Home',
      createdAt: new Date().toISOString(),
      acknowledged: false,
    });
    expect(alert.id).toBe('alert-1');

    const sos = sosResponseSchema.parse({
      accepted: true,
      type: 'sos',
      alert,
    });
    expect(sos.type).toBe('sos');
  });
});