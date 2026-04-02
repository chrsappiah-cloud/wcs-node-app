import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

interface DevicesCardProps {
  onOpenMap?: () => void;
  onReviewAlerts?: () => void;
}

export function DevicesCard({ onOpenMap, onReviewAlerts }: DevicesCardProps) {
  return (
    <View style={styles.footerCard}>
      <Text style={styles.footerHeadline}>Devices & Signals</Text>
      <Text style={styles.footerText}>2 APNs tokens healthy • 1 watch paired • next sync in 04:12</Text>
      <View style={styles.footerActions}>
        <Pressable style={styles.primaryButton} onPress={onOpenMap}>
          <Text style={styles.primaryButtonText}>Open Map</Text>
        </Pressable>
        <Pressable style={styles.secondaryButton} onPress={onReviewAlerts}>
          <Text style={styles.secondaryButtonText}>Review Alerts</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  footerCard: {
    backgroundColor: '#E7F7F5',
    borderRadius: 22,
    padding: 16
  },
  footerHeadline: {
    color: '#134B56',
    fontSize: 18,
    fontWeight: '700'
  },
  footerText: {
    color: '#235460',
    marginTop: 8,
    fontSize: 13,
    lineHeight: 18
  },
  footerActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14
  },
  primaryButton: {
    backgroundColor: '#0A7C86',
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 14
  },
  primaryButtonText: {
    color: '#F5FEFF',
    fontWeight: '700',
    fontSize: 13
  },
  secondaryButton: {
    borderColor: '#0A7C86',
    borderWidth: 1,
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 14
  },
  secondaryButtonText: {
    color: '#0A7C86',
    fontWeight: '700',
    fontSize: 13
  }
});
