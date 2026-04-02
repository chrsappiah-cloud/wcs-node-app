import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { acknowledgeAlert, resolveAlert, type Alert } from '@dreamflow/api-client';
import { useDashboardData } from '../../home/useDashboardData';
import { commonStyles } from '../../shared/styles';
import { useSessionStore } from '../../session/sessionStore';
import { LoadingState } from '../../shared/LoadingState';
import { ErrorState } from '../../shared/ErrorState';

export function AlertsScreen() {
  const userId = useSessionStore(state => state.userId);
  const queryClient = useQueryClient();
  const { dashboard, isLoading, isError, refetch } = useDashboardData(userId);

  const updateAlertOptimistically = (alertId: string, updater: (alert: Alert) => Alert) => {
    const key = ['alerts', userId] as const;
    const previousAlerts = queryClient.getQueryData<Alert[]>(key);

    if (previousAlerts) {
      queryClient.setQueryData<Alert[]>(
        key,
        previousAlerts.map(alert => (alert.id === alertId ? updater(alert) : alert))
      );
    }

    return { previousAlerts };
  };

  const acknowledgeMutation = useMutation({
    mutationFn: (alertId: string) => acknowledgeAlert(alertId),
    onMutate: async alertId => {
      await queryClient.cancelQueries({ queryKey: ['alerts', userId] });
      return updateAlertOptimistically(alertId, alert => ({ ...alert, acknowledged: true }));
    },
    onError: (_error, _alertId, context) => {
      if (context?.previousAlerts) {
        queryClient.setQueryData(['alerts', userId], context.previousAlerts);
      }
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['alerts', userId] });
    }
  });

  const resolveMutation = useMutation({
    mutationFn: (alertId: string) => resolveAlert(alertId),
    onMutate: async alertId => {
      await queryClient.cancelQueries({ queryKey: ['alerts', userId] });
      return updateAlertOptimistically(alertId, alert => ({
        ...alert,
        resolvedAt: alert.resolvedAt || new Date().toISOString(),
        acknowledged: true
      }));
    },
    onError: (_error, _alertId, context) => {
      if (context?.previousAlerts) {
        queryClient.setQueryData(['alerts', userId], context.previousAlerts);
      }
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['alerts', userId] });
    }
  });

  return (
    <ScrollView style={commonStyles.screen} contentContainerStyle={commonStyles.content}>
      <Text style={styles.headline}>Alerts</Text>

      {isLoading ? <LoadingState label="Loading alerts..." /> : null}
      {isError ? <ErrorState onRetry={refetch} /> : null}

      {acknowledgeMutation.isError || resolveMutation.isError ? (
        <ErrorState
          title="Alert update failed"
          detail="Could not update alert status."
          onRetry={refetch}
        />
      ) : null}

      {dashboard.alerts.length === 0 ? (
        <View style={commonStyles.card}>
          <Text style={commonStyles.title}>No alerts</Text>
          <Text style={commonStyles.subtitle}>Alert feed is clear for this user.</Text>
        </View>
      ) : (
        dashboard.alerts.map(alert => (
          <View key={alert.id} style={commonStyles.card}>
            <Text style={commonStyles.title}>{alert.type.toUpperCase()}</Text>
            <Text style={commonStyles.subtitle}>{alert.message}</Text>
            <Text style={commonStyles.subtitle}>
              Created: {new Date(alert.createdAt).toLocaleString()}
            </Text>
            <Text style={commonStyles.subtitle}>Status: {alert.resolvedAt ? 'Resolved' : 'Open'}</Text>

            <View style={styles.actionsRow}>
              <Pressable
                style={styles.ackButton}
                onPress={() => acknowledgeMutation.mutate(alert.id)}
                disabled={acknowledgeMutation.isPending || Boolean(alert.acknowledged)}
              >
                <Text style={styles.ackLabel}>{alert.acknowledged ? 'Acknowledged' : 'Acknowledge'}</Text>
              </Pressable>
              <Pressable
                style={styles.resolveButton}
                onPress={() => resolveMutation.mutate(alert.id)}
                disabled={resolveMutation.isPending}
              >
                <Text style={styles.resolveLabel}>Resolve</Text>
              </Pressable>
            </View>
          </View>
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  headline: {
    fontSize: 28,
    color: '#0F3342',
    fontFamily: 'Avenir Next',
    fontWeight: '700'
  },
  actionsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 10
  },
  ackButton: {
    backgroundColor: '#E0F2FE',
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 7
  },
  ackLabel: {
    color: '#1E3A8A',
    fontSize: 12,
    fontWeight: '700'
  },
  resolveButton: {
    backgroundColor: '#DCFCE7',
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 7
  },
  resolveLabel: {
    color: '#166534',
    fontSize: 12,
    fontWeight: '700'
  }
});
