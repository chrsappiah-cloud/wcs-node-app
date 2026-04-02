import React from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';

interface LoadingStateProps {
  label?: string;
}

export function LoadingState({ label = 'Loading data...' }: LoadingStateProps) {
  return (
    <View style={styles.container}>
      <ActivityIndicator color="#0A7C86" size="small" />
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 8
  },
  label: {
    color: '#235460',
    fontWeight: '600'
  }
});
