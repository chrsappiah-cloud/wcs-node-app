import React from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppNavigator } from '../navigation/AppNavigator';
import { useSessionStore } from '../features/session/sessionStore';

const queryClient = new QueryClient();

export default function App() {
  const hasHydrated = useSessionStore(state => state.hasHydrated);

  if (!hasHydrated) {
    return (
      <SafeAreaProvider>
        <View style={styles.bootstrapScreen}>
          <ActivityIndicator color="#0A7C86" size="small" />
          <Text style={styles.bootstrapLabel}>Restoring session...</Text>
        </View>
      </SafeAreaProvider>
    );
  }

  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <AppNavigator />
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  bootstrapScreen: {
    flex: 1,
    backgroundColor: '#ECF5F6',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10
  },
  bootstrapLabel: {
    color: '#235460',
    fontWeight: '700'
  }
});
