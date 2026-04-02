import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';

export interface Circle {
  id: string;
  name: string;
  type: 'family' | 'care' | 'team';
  createdAt: string;
  members: string[];
  geofences: Geofence[];
}

export interface Geofence {
  id: string;
  lat: number;
  lng: number;
  radiusMeters: number;
  name: string;
}

@Injectable()
export class CirclesService {
  private circles = new Map<string, Circle>();
  private memberCircles = new Map<string, string[]>(); // userId -> circleIds

  create(name: string, type: 'family' | 'care' | 'team', createdBy: string): Circle {
    const id = `circle-${randomUUID()}`;
    const circle: Circle = {
      id,
      name,
      type,
      createdAt: new Date().toISOString(),
      members: [createdBy],
      geofences: []
    };
    this.circles.set(id, circle);
    
    if (!this.memberCircles.has(createdBy)) {
      this.memberCircles.set(createdBy, []);
    }
    this.memberCircles.get(createdBy)!.push(id);
    
    return circle;
  }

  getById(id: string): Circle | null {
    return this.circles.get(id) || null;
  }

  getByUserId(userId: string): Circle[] {
    const circleIds = this.memberCircles.get(userId) || [];
    return circleIds.map(id => this.circles.get(id)!).filter(Boolean);
  }

  addMember(circleId: string, userId: string): Circle | null {
    const circle = this.circles.get(circleId);
    if (!circle) return null;
    
    if (!circle.members.includes(userId)) {
      circle.members.push(userId);
    }
    
    if (!this.memberCircles.has(userId)) {
      this.memberCircles.set(userId, []);
    }
    if (!this.memberCircles.get(userId)!.includes(circleId)) {
      this.memberCircles.get(userId)!.push(circleId);
    }
    
    return circle;
  }

  removeMember(circleId: string, userId: string): Circle | null {
    const circle = this.circles.get(circleId);
    if (!circle) return null;
    
    circle.members = circle.members.filter(id => id !== userId);
    
    const userCircles = this.memberCircles.get(userId);
    if (userCircles) {
      this.memberCircles.set(userId, userCircles.filter(id => id !== circleId));
    }
    
    return circle;
  }

  addGeofence(circleId: string, geofence: Geofence): Circle | null {
    const circle = this.circles.get(circleId);
    if (!circle) return null;
    
    if (!geofence.id) {
      geofence.id = `geofence-${randomUUID()}`;
    }
    circle.geofences.push(geofence);
    
    return circle;
  }

  removeGeofence(circleId: string, geofenceId: string): Circle | null {
    const circle = this.circles.get(circleId);
    if (!circle) return null;
    
    circle.geofences = circle.geofences.filter(g => g.id !== geofenceId);
    return circle;
  }

  getCircleMemberCount(circleId: string): number {
    const circle = this.circles.get(circleId);
    return circle ? circle.members.length : 0;
  }
}
