import { create } from 'zustand';
import type { AppConfig } from '@/services/config';
import { configService } from '@/services/config';

interface AppState {
  config: AppConfig | null;
  initialized: boolean;
  theme: 'light' | 'dark' | 'system';

  // Actions
  initialize: () => Promise<void>;
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
}

export const useAppStore = create<AppState>((set) => ({
  config: null,
  initialized: false,
  theme: 'system',

  initialize: async () => {
    try {
      const config = await configService.getConfig();
      set({ config, initialized: true });
    } catch (error) {
      console.error('Failed to initialize app:', error);
      set({ initialized: true });
    }
  },

  setTheme: (theme) => set({ theme }),
}));
