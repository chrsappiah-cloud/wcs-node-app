import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { useDashboardData } from '../../home/useDashboardData';
import { commonStyles } from '../../shared/styles';
import { useSessionStore } from '../../session/sessionStore';
import { LoadingState } from '../../shared/LoadingState';
import { ErrorState } from '../../shared/ErrorState';

export function TimelineScreen() {
  const userId = useSessionStore(state => state.userId);
  const { dashboard, isLoading, isError, refetch } = useDashboardData(userId);

  return (
    <ScrollView style={commonStyles.screen} contentContainerStyle={commonStyles.content}>
      <Text style={styles.headline}>Timeline</Text>
      {isLoading ? <LoadingState label="Loading timeline..." /> : null}
      {isError ? <ErrorState onRetry={refetch} /> : null}
      {dashboard.timeline.length === 0 ? (
        <View style={commonStyles.card}>
          <Text style={commonStyles.title}>No events yet</Text>
          <Text style={commonStyles.subtitle}>Timeline items appear from alert and presence activity.</Text>
        </View>
      ) : (
        dashboard.timeline.map(item => (
          <View key={item.id} style={commonStyles.card}>
            <Text style={commonStyles.title}>{item.title}</Text>
            <Text style={commonStyles.subtitle}>{item.detail}</Text>
            <Text style={commonStyles.subtitle}>Time: {item.time}</Text>
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
  }
});
