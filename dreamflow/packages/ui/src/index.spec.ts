import { colors } from './tokens/colors';
import * as uiExports from './index';

describe('ui package', () => {
  it('re-exports the color tokens', () => {
    expect(uiExports.colors).toBe(colors);
  });

  it('provides the expected brand and semantic colors', () => {
    expect(colors).toEqual({
      brandPrimary: '#0A7C86',
      brandSecondary: '#0C4A6E',
      surface: '#F7FAFC',
      textPrimary: '#0F172A',
      textMuted: '#475569',
      success: '#059669',
      warning: '#D97706',
      danger: '#DC2626'
    });
  });
});