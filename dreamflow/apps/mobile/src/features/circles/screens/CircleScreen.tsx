import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createCircle, type Circle } from '@dreamflow/api-client';
import { useDashboardData } from '../../home/useDashboardData';
import { commonStyles } from '../../shared/styles';
import { useSessionStore } from '../../session/sessionStore';
import { LoadingState } from '../../shared/LoadingState';
import { ErrorState } from '../../shared/ErrorState';

export function CircleScreen() {
  const [circleName, setCircleName] = React.useState('Neighborhood Family');
  const userId = useSessionStore(state => state.userId);
  const circleTypePreference = useSessionStore(state => state.circleTypePreference);
  const setCircleTypePreference = useSessionStore(state => state.setCircleTypePreference);
  const queryClient = useQueryClient();
  const { dashboard, isLoading, isError, refetch } = useDashboardData(userId);
  const circles = dashboard.circles;

  const createCircleMutation = useMutation({
    mutationFn: () =>
      createCircle({
        name: circleName,
        type: circleTypePreference,
        userId
      }),
    onMutate: async () => {
      const key = ['circles', userId] as const;
      await queryClient.cancelQueries({ queryKey: key });

      const previousCircles = queryClient.getQueryData<Circle[]>(key) ?? [];
      const optimisticCircle: Circle = {
        id: `temp-${Date.now()}`,
        name: circleName,
        type: circleTypePreference,
        createdAt: new Date().toISOString(),
        members: [userId],
        geofences: []
      };

      queryClient.setQueryData<Circle[]>(key, [optimisticCircle, ...previousCircles]);
      return { previousCircles, key };
    },
    onError: (_error, _variables, context) => {
      if (context?.previousCircles && context.key) {
        queryClient.setQueryData(context.key, context.previousCircles);
      }
    },
    onSuccess: () => {
      setCircleName('');
    },
    onSettled: (_data, _error, _variables, context) => {
      if (context?.key) {
        void queryClient.invalidateQueries({ queryKey: context.key });
      } else {
        void queryClient.invalidateQueries({ queryKey: ['circles', userId] });
      }
    }
  });

  return (
    <ScrollView style={commonStyles.screen} contentContainerStyle={commonStyles.content}>
      <Text style={styles.headline}>Circles</Text>

      {isLoading ? <LoadingState label="Loading circles..." /> : null}
      {isError ? <ErrorState onRetry={refetch} /> : null}

      <View style={commonStyles.card}>
        <Text style={commonStyles.title}>Create Circle</Text>
        <Text style={commonStyles.subtitle}>Owner: {userId}</Text>
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
        <TextInput
          value={circleName}
          onChangeText={setCircleName}
          placeholder="Circle name"
          style={styles.input}
        />
        <Pressable
          style={styles.createButton}
          onPress={() => createCircleMutation.mutate()}
          disabled={createCircleMutation.isPending || !circleName.trim()}
        >
          <Text style={styles.createButtonLabel}>
            {createCircleMutation.isPending ? 'Creating...' : 'Create Circle'}
          </Text>
        </Pressable>
      </View>
      {createCircleMutation.isError ? (
        <ErrorState
          title="Circle creation failed"
          detail="Verify API is running and userId is valid."
          onRetry={() => createCircleMutation.mutate()}
        />
      ) : null}

      {circles.length === 0 ? (
        <View style={commonStyles.card}>
          <Text style={commonStyles.title}>No circles yet</Text>
          <Text style={commonStyles.subtitle}>Create a circle from the API to populate this view.</Text>
        </View>
      ) : (
        circles.map(circle => (
          <View key={circle.id} style={commonStyles.card}>
            <Text style={commonStyles.title}>{circle.name}</Text>
            <Text style={commonStyles.subtitle}>Type: {circle.type}</Text>
            <Text style={commonStyles.subtitle}>Members: {circle.members.length}</Text>
            <Text style={commonStyles.subtitle}>Geofences: {circle.geofences.length}</Text>
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
  input: {
    marginTop: 10,
    borderWidth: 1,
    borderColor: '#B8D5DB',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF'
  },
  createButton: {
    marginTop: 10,
    alignSelf: 'flex-start',
    backgroundColor: '#0A7C86',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8
  },
  createButtonLabel: {
    color: '#F5FEFF',
    fontWeight: '700',
    fontSize: 12
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
