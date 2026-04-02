import { CirclesService } from './circles.service';

describe('CirclesService', () => {
  let service: CirclesService;

  beforeEach(() => {
    service = new CirclesService();
  });

  it('creates circles and maintains member indexes', () => {
    const circle = service.create('Family', 'family', 'user-1');

    expect(circle.name).toBe('Family');
    expect(circle.members).toEqual(['user-1']);
    expect(service.getByUserId('user-1')).toEqual([circle]);

    service.addMember(circle.id, 'user-2');

    expect(service.getCircleMemberCount(circle.id)).toBe(2);
    expect(service.getByUserId('user-2')).toEqual([circle]);

    service.removeMember(circle.id, 'user-2');

    expect(service.getCircleMemberCount(circle.id)).toBe(1);
    expect(service.getByUserId('user-2')).toEqual([]);
  });

  it('adds and removes geofences on a circle', () => {
    const circle = service.create('Care Team', 'care', 'user-1');

    service.addGeofence(circle.id, {
      id: '',
      name: 'Home',
      lat: 37.7749,
      lng: -122.4194,
      radiusMeters: 250
    });

    const updatedCircle = service.getById(circle.id);
    expect(updatedCircle?.geofences).toHaveLength(1);
    expect(updatedCircle?.geofences[0].id).toMatch(/^geofence-/);

    service.removeGeofence(circle.id, updatedCircle!.geofences[0].id);

    expect(service.getById(circle.id)?.geofences).toHaveLength(0);
  });
});