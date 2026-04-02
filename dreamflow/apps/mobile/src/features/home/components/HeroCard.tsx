import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { palette } from '../../shared/styles';

interface HeroCardProps {
  activeCircleCount: number;
  signalHealth: number;
  openAlerts: number;
  healthStatus: string;
}

export function HeroCard({ activeCircleCount, signalHealth, openAlerts, healthStatus }: HeroCardProps) {
  return (
    <View style={styles.heroCard}>
      <Text style={styles.eyebrow}>DreamFlow</Text>
      <Text style={styles.headline}>Map-First Family Safety</Text>
      <Text style={styles.subhead}>Live presence, circle health, and alert intelligence in one command surface.</Text>

      <View style={styles.kpiRow}>
        <View style={styles.kpiBox}>
          <Text style={styles.kpiValue}>{activeCircleCount}</Text>
          <Text style={styles.kpiLabel}>Active Circle</Text>
        </View>
        <View style={styles.kpiBox}>
          <Text style={styles.kpiValue}>{signalHealth}%</Text>
          <Text style={styles.kpiLabel}>Signal Health</Text>
        </View>
        <View style={styles.kpiBox}>
          <Text style={styles.kpiValue}>{openAlerts}</Text>
          <Text style={styles.kpiLabel}>Open Alerts</Text>
        </View>
      </View>

      <View style={styles.healthBadge}>
        <Text style={styles.healthBadgeText}>API: {healthStatus.toUpperCase()}</Text>
      </View>

      <View style={styles.mapSurface}>
        <View style={styles.mapRingLarge} />
        <View style={styles.mapRingSmall} />
        <View style={styles.pinPrimary} />
        <View style={styles.pinSecondary} />
        <View style={styles.pinTertiary} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  heroCard: {
    backgroundColor: palette.deep,
    borderRadius: 26,
    padding: 18,
    overflow: 'hidden'
  },
  eyebrow: {
    color: palette.mint,
    letterSpacing: 1.2,
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase'
  },
  headline: {
    color: palette.textLight,
    fontSize: 30,
    lineHeight: 34,
    marginTop: 8,
    fontFamily: 'Avenir Next',
    fontWeight: '700'
  },
  subhead: {
    color: '#C7DEEA',
    marginTop: 8,
    fontSize: 14,
    lineHeight: 20
  },
  kpiRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 14
  },
  kpiBox: {
    flex: 1,
    borderRadius: 14,
    backgroundColor: palette.deepMuted,
    paddingVertical: 10,
    paddingHorizontal: 8
  },
  kpiValue: {
    color: '#F8FDFF',
    fontSize: 20,
    fontWeight: '700'
  },
  kpiLabel: {
    color: '#ABCDD8',
    fontSize: 12,
    marginTop: 4
  },
  healthBadge: {
    marginTop: 10,
    alignSelf: 'flex-start',
    backgroundColor: '#1B5A70',
    borderRadius: 12,
    paddingVertical: 5,
    paddingHorizontal: 9
  },
  healthBadgeText: {
    color: '#DBF3FF',
    fontWeight: '700',
    fontSize: 11
  },
  mapSurface: {
    marginTop: 14,
    height: 150,
    borderRadius: 14,
    backgroundColor: '#0B2836',
    overflow: 'hidden'
  },
  mapRingLarge: {
    position: 'absolute',
    width: 150,
    height: 150,
    borderRadius: 80,
    borderWidth: 2,
    borderColor: '#2A5568',
    top: 12,
    left: -28
  },
  mapRingSmall: {
    position: 'absolute',
    width: 96,
    height: 96,
    borderRadius: 50,
    borderWidth: 2,
    borderColor: '#2A5568',
    bottom: -14,
    right: 16
  },
  pinPrimary: {
    position: 'absolute',
    width: 14,
    height: 14,
    borderRadius: 8,
    backgroundColor: '#47E2B0',
    top: 42,
    left: 72
  },
  pinSecondary: {
    position: 'absolute',
    width: 12,
    height: 12,
    borderRadius: 8,
    backgroundColor: '#F4B860',
    bottom: 28,
    left: 146
  },
  pinTertiary: {
    position: 'absolute',
    width: 12,
    height: 12,
    borderRadius: 8,
    backgroundColor: '#73A7FF',
    top: 24,
    right: 60
  }
});
