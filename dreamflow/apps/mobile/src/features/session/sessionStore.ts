import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface SessionState {
  userId: string;
  circleTypePreference: 'family' | 'care' | 'team';
  hasHydrated: boolean;
  setUserId: (nextUserId: string) => void;
  setCircleTypePreference: (next: 'family' | 'care' | 'team') => void;
  setHasHydrated: (value: boolean) => void;
}

export const useSessionStore = create<SessionState>()(
  persist(
    set => ({
      userId: 'demo-user',
      circleTypePreference: 'family',
      hasHydrated: false,
      setUserId: nextUserId => set({ userId: nextUserId.trim() || 'demo-user' }),
      setCircleTypePreference: next => set({ circleTypePreference: next }),
      setHasHydrated: value => set({ hasHydrated: value })
    }),
    {
      name: 'dreamflow-mobile-session',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: state => ({
        userId: state.userId,
        circleTypePreference: state.circleTypePreference
      }),
      onRehydrateStorage: () => state => {
        state?.setHasHydrated(true);
      }
    }
  )
);
