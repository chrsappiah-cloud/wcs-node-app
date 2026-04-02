import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { commonStyles } from '../../shared/styles';

interface TimelineItem {
  id: string;
  title: string;
  detail: string;
  time: string;
}

interface TimelineCardProps {
  items: TimelineItem[];
}

export function TimelineCard({ items }: TimelineCardProps) {
  return (
    <View style={commonStyles.card}>
      <Text style={commonStyles.title}>Timeline</Text>
      {items.length === 0 ? (
        <Text style={[commonStyles.subtitle, styles.empty]}>Timeline will appear after activity events.</Text>
      ) : (
        items.map(item => (
          <View key={item.id} style={styles.timelineRow}>
            <View style={styles.timelineRail}>
              <View style={styles.timelineNode} />
            </View>
            <View style={styles.rowBody}>
              <Text style={styles.rowTitle}>{item.title}</Text>
              <Text style={commonStyles.subtitle}>{item.detail}</Text>
            </View>
            <Text style={styles.rowMeta}>{item.time}</Text>
          </View>
        ))
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  empty: {
    marginTop: 8
  },
  timelineRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    paddingTop: 10
  },
  timelineRail: {
    width: 16,
    alignItems: 'center',
    marginTop: 1
  },
  timelineNode: {
    width: 10,
    height: 10,
    borderRadius: 8,
    backgroundColor: '#0B7884'
  },
  rowBody: {
    flex: 1
  },
  rowTitle: {
    color: '#0F172A',
    fontSize: 14,
    fontWeight: '700'
  },
  rowMeta: {
    color: '#64748B',
    fontSize: 12,
    fontWeight: '700'
  }
});
