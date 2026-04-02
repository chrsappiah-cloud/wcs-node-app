import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { postLocationPing } from '@dreamflow/api-client';
import { useDashboardData } from '../useDashboardData';
import { HeroCard } from '../components/HeroCard';
import { PresenceCard } from '../components/PresenceCard';
import { AlertsCard } from '../components/AlertsCard';
import { TimelineCard } from '../components/TimelineCard';
import { DevicesCard } from '../components/DevicesCard';
import { commonStyles } from '../../shared/styles';
import type { RootStackParamList } from '../../../navigation/types';
import { useSessionStore } from '../../session/sessionStore';
import { LoadingState } from '../../shared/LoadingState';
import { ErrorState } from '../../shared/ErrorState';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  const queryClient = useQueryClient();
  const userId = useSessionStore(state => state.userId);
  const { dashboard, isLoading, isError, refetch } = useDashboardData(userId);

  const locationMutation = useMutation({
    mutationFn: () =>
      postLocationPing({
        userId,
        lat: 37.7749,
        lng: -122.4194,
        accuracy: 8,
        speed: 0
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['presence', userId] });
      void queryClient.invalidateQueries({ queryKey: ['alerts', userId] });
    }
  });

  const memberRows = dashboard.primaryCircle
    ? dashboard.primaryCircle.members.map((memberId, index) => ({
        id: `${memberId}-${index}`,
        name: memberId,
        state: dashboard.presence?.isActive ? ('online' as const) : ('idle' as const),
        place: dashboard.presence?.lastLocation
          ? `${dashboard.presence.lastLocation.lat.toFixed(4)}, ${dashboard.presence.lastLocation.lng.toFixed(4)}`
          : 'Awaiting location ping',
        minutesAgo: dashboard.presence?.lastLocation
          ? Math.max(
              0,
              Math.floor(
                (Date.now() - new Date(dashboard.presence.lastLocation.processedAt).getTime()) / 60000
              )
            )
          : 0
      }))
    : [
        { id: 'demo-1', name: 'Maya', state: 'online' as const, place: 'Central Park South', minutesAgo: 1 },
        { id: 'demo-2', name: 'Kojo', state: 'idle' as const, place: 'Grove St Station', minutesAgo: 8 }
      ];

  return (
    <View style={commonStyles.screen}>
      <View style={styles.bgShapeA} />
      <View style={styles.bgShapeB} />

      <ScrollView contentContainerStyle={commonStyles.content} showsVerticalScrollIndicator={false}>
        {isLoading ? <LoadingState label="Syncing DreamFlow data..." /> : null}
        {isError ? <ErrorState onRetry={refetch} /> : null}

        <View style={styles.routeRow}>
          <Text style={styles.routeLink} onPress={() => navigation.navigate('Home')}>
            Home
          </Text>
          <Text style={styles.routeLink} onPress={() => navigation.navigate('Circle')}>
            Circle
          </Text>
          <Text style={styles.routeLink} onPress={() => navigation.navigate('Alerts')}>
            Alerts
          </Text>
          <Text style={styles.routeLink} onPress={() => navigation.navigate('Timeline')}>
            Timeline
          </Text>
          <Text style={styles.routeLink} onPress={() => navigation.navigate('Settings')}>
            Settings
          </Text>
        </View>

        <View style={styles.sessionRow}>
          <Text style={styles.sessionLabel}>User: {userId}</Text>
          <Pressable
            style={styles.locationButton}
            onPress={() => locationMutation.mutate()}
            disabled={locationMutation.isPending}
          >
            <Text style={styles.locationButtonText}>
              {locationMutation.isPending ? 'Pinging...' : 'Send Location Ping'}
            </Text>
          </Pressable>
        </View>
        {locationMutation.isError ? (
          <ErrorState
            title="Location ping failed"
            detail="Could not submit presence update."
            onRetry={() => locationMutation.mutate()}
          />
        ) : null}

        <HeroCard
          activeCircleCount={dashboard.circles.length}
          signalHealth={dashboard.signalHealth}
          openAlerts={dashboard.alerts.filter(a => !a.resolvedAt).length}
          healthStatus={dashboard.healthStatus}
        />

        <PresenceCard members={memberRows} />

        <AlertsCard alerts={dashboard.alerts} onOpenAlerts={() => navigation.navigate('Alerts')} />

        <TimelineCard items={dashboard.timeline} />

        <DevicesCard
          onOpenMap={() => navigation.navigate('Circle')}
          onReviewAlerts={() => navigation.navigate('Alerts')}
        />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  bgShapeA: {
    position: 'absolute',
    width: 260,
    height: 260,
    backgroundColor: '#C8ECE8',
    borderRadius: 150,
    top: -84,
    left: -70
  },
  bgShapeB: {
    position: 'absolute',
    width: 220,
    height: 220,
    backgroundColor: '#DDE8F6',
    borderRadius: 140,
    top: 68,
    right: -82
  },
  loadingText: {
    color: '#235460',
    fontWeight: '600'
  },
  sessionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8
  },
  sessionLabel: {
    color: '#235460',
    fontWeight: '700'
  },
  locationButton: {
    backgroundColor: '#0A7C86',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8
  },
  locationButtonText: {
    color: '#F5FEFF',
    fontWeight: '700',
    fontSize: 12
  },
  routeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10
  },
  routeLink: {
    color: '#0A7C86',
    fontWeight: '700',
    backgroundColor: '#DDF3F1',
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 6,
    overflow: 'hidden'
  }
});
