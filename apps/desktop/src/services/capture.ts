import { invoke } from '@tauri-apps/api/core';
import type { Capture, CreateCaptureInput } from '@notate/shared';

export const captureService = {
  async createCapture(input: CreateCaptureInput): Promise<Capture> {
    return invoke('create_capture', { input });
  },

  async getCapture(id: string): Promise<Capture> {
    return invoke('get_capture', { id });
  },

  async getCaptures(limit = 20, offset = 0): Promise<Capture[]> {
    return invoke('get_captures', { limit, offset });
  },

  async updateCapture(id: string, content: string): Promise<Capture> {
    return invoke('update_capture', { id, content });
  },

  async deleteCapture(id: string): Promise<void> {
    return invoke('delete_capture', { id });
  },
};
