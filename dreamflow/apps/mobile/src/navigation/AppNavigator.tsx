import React from 'react';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import type { RootStackParamList } from './types';
import { HomeScreen } from '../features/home/screens/HomeScreen';
import { CircleScreen } from '../features/circles/screens/CircleScreen';
import { AlertsScreen } from '../features/alerts/screens/AlertsScreen';
import { TimelineScreen } from '../features/timeline/screens/TimelineScreen';
import { SettingsScreen } from '../features/settings/screens/SettingsScreen';

const Stack = createNativeStackNavigator<RootStackParamList>();

const theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: '#ECF5F6'
  }
};

export function AppNavigator() {
  return (
    <NavigationContainer theme={theme}>
      <Stack.Navigator
        initialRouteName="Home"
        screenOptions={{
          headerStyle: { backgroundColor: '#ECF5F6' },
          headerTitleStyle: { fontFamily: 'Avenir Next', fontWeight: '700', color: '#0F3342' },
          headerTintColor: '#0A7C86'
        }}
      >
        <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Home' }} />
        <Stack.Screen name="Circle" component={CircleScreen} options={{ title: 'Circle' }} />
        <Stack.Screen name="Alerts" component={AlertsScreen} options={{ title: 'Alerts' }} />
        <Stack.Screen name="Timeline" component={TimelineScreen} options={{ title: 'Timeline' }} />
        <Stack.Screen name="Settings" component={SettingsScreen} options={{ title: 'Settings' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
