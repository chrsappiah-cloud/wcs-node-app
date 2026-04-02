import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { commonStyles } from '../../shared/styles';
import { useSessionStore } from '../../session/sessionStore';
import { useDashboardData } from '../../home/useDashboardData';
import { LoadingState } from '../../shared/LoadingState';
import { ErrorState } from '../../shared/ErrorState';

export function SettingsScreen() {
  const userId = useSessionStore(state => state.userId);
  const setUserId = useSessionStore(state => state.setUserId);
  const circleTypePreference = useSessionStore(state => state.circleTypePreference);
  const setCircleTypePreference = useSessionStore(state => state.setCircleTypePreference);
  const [draftUserId, setDraftUserId] = React.useState(userId);
  const { isLoading, isError, refetch } = useDashboardData(userId);

  return (
    <ScrollView style={commonStyles.screen} contentContainerStyle={commonStyles.content}>
      <Text style={styles.headline}>Settings</Text>

      {isLoading ? <LoadingState label="Checking session connectivity..." /> : null}
      {isError ? <ErrorState onRetry={refetch} /> : null}

      <View style={commonStyles.card}>
        <Text style={commonStyles.title}>Session</Text>
        <Text style={commonStyles.subtitle}>Active user id</Text>
        <TextInput value={draftUserId} onChangeText={setDraftUserId} style={styles.input} />
        <Pressable style={styles.applyButton} onPress={() => setUserId(draftUserId)}>
          <Text style={styles.applyLabel}>Apply User</Text>
        </Pressable>
      </View>

      <View style={commonStyles.card}>
        <Text style={commonStyles.title}>Circle Type Preference</Text>
        <View style={styles.typeRow}>
          {(['family', 'care', 'team'] as const).map(type => (
            <Pressable
              key={type}
              style={[styles.typeChip, circleTypePreference === type ? styles.typeChipActive : null]}
              onPress={() => setCircleTypePreference(type)}
            >
              <Text style={[styles.typeChipLabel, circleTypePreference === type ? styles.typeChipLabelActive : null]}>
                {type}
              </Text>
            </Pressable>
          ))}
        </View>
      </View>

      <View style={commonStyles.card}>
        <Text style={commonStyles.title}>Privacy Defaults</Text>
        <Text style={commonStyles.subtitle}>Consent scope: Circle-only visibility</Text>
        <Text style={commonStyles.subtitle}>Audit mode: Enabled</Text>
      </View>

      <View style={commonStyles.card}>
        <Text style={commonStyles.title}>Data Sync</Text>
        <Text style={commonStyles.subtitle}>API target: http://localhost:3000/v1</Text>
        <Text style={commonStyles.subtitle}>Session user: {userId}</Text>
        <Text style={commonStyles.subtitle}>Location update cadence: 12 seconds</Text>
      </View>
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
  input: {
    marginTop: 10,
    borderWidth: 1,
    borderColor: '#B8D5DB',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF'
  },
  applyButton: {
    marginTop: 10,
    alignSelf: 'flex-start',
    backgroundColor: '#0A7C86',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8
  },
  applyLabel: {
    color: '#F5FEFF',
    fontSize: 12,
    fontWeight: '700'
  },
  typeRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 10
  },
  typeChip: {
    borderWidth: 1,
    borderColor: '#8AB8C2',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: '#FFFFFF'
  },
  typeChipActive: {
    backgroundColor: '#DDF3F1',
    borderColor: '#0A7C86'
  },
  typeChipLabel: {
    color: '#155E75',
    fontSize: 12,
    fontWeight: '700'
  },
  typeChipLabelActive: {
    color: '#0A7C86'
  }
});
