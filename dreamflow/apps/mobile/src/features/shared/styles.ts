import { StyleSheet } from 'react-native';

export const palette = {
  bg: '#ECF5F6',
  deep: '#0F3342',
  deepMuted: '#15485C',
  mint: '#7BE5CC',
  textLight: '#F5FCFF',
  textDark: '#0F172A',
  textMuted: '#475569',
  card: '#F9FCFF',
  accent: '#0A7C86',
  warning: '#F59E0B',
  danger: '#B91C1C'
} as const;

export const commonStyles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: palette.bg
  },
  content: {
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 24,
    gap: 14
  },
  card: {
    backgroundColor: palette.card,
    borderRadius: 22,
    padding: 16
  },
  title: {
    color: palette.textDark,
    fontSize: 18,
    fontWeight: '700'
  },
  subtitle: {
    color: palette.textMuted,
    fontSize: 13
  }
});
