import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  getHealth,
  getUserAlerts,
  getUserCircles,
  getUserPresence,
  type Alert,
  type Circle,
  type UserPresence
} from '@dreamflow/api-client';
import type { DashboardState } from './types';

function toTimeline(alerts: Alert[]) {
  return alerts.slice(0, 5).map(alert => ({
    id: alert.id,
    title: alert.type.replace('_', ' ').toUpperCase(),
    detail: alert.message,
    time: new Date(alert.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }));
}

function calculateSignalHealth(presence: UserPresence | null, circles: Circle[]) {
  if (!presence?.lastLocation) {
    return 72;
  }

  const geofenceFactor = Math.min(circles.reduce((sum, c) => sum + c.geofences.length, 0) * 2, 10);
  const ageMs = Date.now() - new Date(presence.lastLocation.processedAt).getTime();
  const freshnessPenalty = Math.min(Math.floor(ageMs / 10000), 20);

  return Math.max(55, 100 - freshnessPenalty + geofenceFactor);
}

export function useDashboardData(userId: string) {
  const healthQuery = useQuery({
    queryKey: ['health'],
    queryFn: getHealth,
    retry: 1
  });

  const circlesQuery = useQuery({
    queryKey: ['circles', userId],
    queryFn: () => getUserCircles(userId),
    retry: 1
  });

  const presenceQuery = useQuery({
    queryKey: ['presence', userId],
    queryFn: () => getUserPresence(userId),
    retry: 1
  });

  const alertsQuery = useQuery({
    queryKey: ['alerts', userId],
    queryFn: async () => {
      const result = await getUserAlerts(userId, 12);
      return result.alerts;
    },
    retry: 1
  });

  const dashboard = useMemo<DashboardState>(() => {
    const circles = circlesQuery.data ?? [];
    const alerts = alertsQuery.data ?? [];
    const presence = presenceQuery.data ?? null;

    return {
      healthStatus: healthQuery.data?.status ?? 'offline',
      circles,
      primaryCircle: circles[0] ?? null,
      presence,
      alerts,
      timeline: toTimeline(alerts),
      signalHealth: calculateSignalHealth(presence, circles)
    };
  }, [alertsQuery.data, circlesQuery.data, healthQuery.data?.status, presenceQuery.data]);

  return {
    dashboard,
    isLoading:
      healthQuery.isLoading || circlesQuery.isLoading || presenceQuery.isLoading || alertsQuery.isLoading,
    isError: healthQuery.isError || circlesQuery.isError || presenceQuery.isError || alertsQuery.isError,
    error:
      healthQuery.error ?? circlesQuery.error ?? presenceQuery.error ?? alertsQuery.error ?? null,
    refetch: () => {
      void healthQuery.refetch();
      void circlesQuery.refetch();
      void presenceQuery.refetch();
      void alertsQuery.refetch();
    }
  };
}
