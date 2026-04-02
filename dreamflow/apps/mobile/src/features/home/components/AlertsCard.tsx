import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { Alert } from '@dreamflow/api-client';
import { commonStyles } from '../../shared/styles';

interface AlertsCardProps {
  alerts: Alert[];
  onOpenAlerts?: () => void;
}

export function AlertsCard({ alerts, onOpenAlerts }: AlertsCardProps) {
  return (
    <View style={commonStyles.card}>
      <View style={styles.header}>
        <Text style={commonStyles.title}>Alert Feed</Text>
        <Pressable style={styles.sosButton} onPress={onOpenAlerts}>
          <Text style={styles.sosLabel}>SOS</Text>
        </Pressable>
      </View>
      {alerts.length === 0 ? (
        <Text style={commonStyles.subtitle}>No active alerts right now.</Text>
      ) : (
        alerts.slice(0, 4).map(alert => (
          <View key={alert.id} style={styles.alertRow}>
            <View style={[styles.alertTag, alert.type === 'sos' ? styles.alertTagDanger : styles.alertTagInfo]}>
              <Text style={styles.alertTagText}>{alert.type.toUpperCase()}</Text>
            </View>
            <View style={styles.rowBody}>
              <Text style={styles.rowTitle}>{alert.message}</Text>
              <Text style={commonStyles.subtitle}>
                {new Date(alert.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
              </Text>
            </View>
          </View>
        ))
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  sosButton: {
    backgroundColor: '#FEE2E2',
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 5
  },
  sosLabel: {
    color: '#B91C1C',
    fontWeight: '800',
    fontSize: 12
  },
  alertRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    paddingTop: 10
  },
  alertTag: {
    borderRadius: 8,
    paddingHorizontal: 7,
    paddingVertical: 4,
    marginTop: 2
  },
  alertTagDanger: {
    backgroundColor: '#FFF1F2'
  },
  alertTagInfo: {
    backgroundColor: '#ECFEFF'
  },
  alertTagText: {
    color: '#0F172A',
    fontSize: 10,
    fontWeight: '800'
  },
  rowBody: {
    flex: 1
  },
  rowTitle: {
    color: '#0F172A',
    fontSize: 14,
    fontWeight: '700'
  }
});
