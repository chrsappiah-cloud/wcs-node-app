import { createCircleSchema, locationPingSchema } from './index';

describe('schemas', () => {
  it('validates circle creation payloads', () => {
    expect(createCircleSchema.parse({ name: 'Family', type: 'family' })).toEqual({
      name: 'Family',
      type: 'family'
    });
    expect(() => createCircleSchema.parse({ name: 'F', type: 'family' })).toThrow();
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
});