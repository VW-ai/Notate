import { create } from 'zustand';
import type { Capture, CreateCaptureInput } from '@notate/shared';
import { captureService } from '@/services/capture';

interface CaptureState {
  captures: Map<string, Capture>;
  loading: boolean;
  error: string | null;

  // Actions
  fetchCaptures: () => Promise<void>;
  createCapture: (input: CreateCaptureInput) => Promise<Capture>;
  updateCapture: (id: string, content: string) => Promise<void>;
  deleteCapture: (id: string) => Promise<void>;
  clearError: () => void;
}

export const useCaptureStore = create<CaptureState>((set) => ({
  captures: new Map(),
  loading: false,
  error: null,

  fetchCaptures: async () => {
    set({ loading: true, error: null });
    try {
      const captures = await captureService.getCaptures();
      const captureMap = new Map(captures.map((c) => [c.id, c]));
      set({ captures: captureMap, loading: false });
    } catch (error) {
      set({ error: String(error), loading: false });
    }
  },

  createCapture: async (input) => {
    set({ error: null });
    try {
      const capture = await captureService.createCapture(input);
      set((state) => ({
        captures: new Map(state.captures).set(capture.id, capture),
      }));
      return capture;
    } catch (error) {
      set({ error: String(error) });
      throw error;
    }
  },

  updateCapture: async (id, content) => {
    set({ error: null });
    try {
      const capture = await captureService.updateCapture(id, content);
      set((state) => ({
        captures: new Map(state.captures).set(id, capture),
      }));
    } catch (error) {
      set({ error: String(error) });
      throw error;
    }
  },

  deleteCapture: async (id) => {
    set({ error: null });
    try {
      await captureService.deleteCapture(id);
      set((state) => {
        const newCaptures = new Map(state.captures);
        newCaptures.delete(id);
        return { captures: newCaptures };
      });
    } catch (error) {
      set({ error: String(error) });
      throw error;
    }
  },

  clearError: () => set({ error: null }),
}));
