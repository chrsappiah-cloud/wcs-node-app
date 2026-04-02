import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { commonStyles } from '../../shared/styles';

interface PresenceItem {
  id: string;
  name: string;
  state: 'online' | 'idle' | 'offline';
  place: string;
  minutesAgo: number;
}

interface PresenceCardProps {
  members: PresenceItem[];
}

export function PresenceCard({ members }: PresenceCardProps) {
  return (
    <View style={commonStyles.card}>
      <Text style={commonStyles.title}>Circle Presence</Text>
      {members.map(member => (
        <View key={member.id} style={styles.rowItem}>
          <View style={[styles.dot, member.state === 'online' ? styles.dotOnline : member.state === 'idle' ? styles.dotIdle : styles.dotOffline]} />
          <View style={styles.rowBody}>
            <Text style={styles.rowTitle}>{member.name}</Text>
            <Text style={commonStyles.subtitle}>{member.place}</Text>
          </View>
          <Text style={styles.rowMeta}>{member.minutesAgo}m</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  rowItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 10,
    gap: 10
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 8
  },
  dotOnline: {
    backgroundColor: '#16A34A'
  },
  dotIdle: {
    backgroundColor: '#F59E0B'
  },
  dotOffline: {
    backgroundColor: '#94A3B8'
  },
  rowBody: {
    flex: 1
  },
  rowTitle: {
    color: '#0F172A',
    fontSize: 15,
    fontWeight: '700'
  },
  rowMeta: {
    color: '#64748B',
    fontSize: 12,
    fontWeight: '700'
  }
});
