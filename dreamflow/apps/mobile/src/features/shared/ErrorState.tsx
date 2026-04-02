import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

interface ErrorStateProps {
  title?: string;
  detail?: string;
  onRetry?: () => void;
}

export function ErrorState({
  title = 'Unable to load this screen',
  detail = 'Check API connectivity and try again.',
  onRetry
}: ErrorStateProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.detail}>{detail}</Text>
      <Pressable style={styles.retryButton} onPress={onRetry}>
        <Text style={styles.retryLabel}>Retry</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFF7ED',
    borderRadius: 14,
    padding: 12,
    gap: 4
  },
  title: {
    color: '#9A3412',
    fontWeight: '700',
    fontSize: 14
  },
  detail: {
    color: '#7C2D12',
    fontSize: 12
  },
  retryButton: {
    alignSelf: 'flex-start',
    marginTop: 6,
    backgroundColor: '#FDBA74',
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 6
  },
  retryLabel: {
    color: '#7C2D12',
    fontWeight: '700',
    fontSize: 12
  }
});
