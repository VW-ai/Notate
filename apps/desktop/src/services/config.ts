import { invoke } from '@tauri-apps/api/core';

export interface AppConfig {
  app: {
    name: string;
    version: string;
  };
  capture: {
    maxContentLength: number;
    maxFileSize: {
      image: number;
      document: number;
    };
  };
  ui: {
    overlay: {
      width: number;
      height: number;
    };
    animation: {
      durationMs: number;
    };
  };
}

export const configService = {
  async getConfig(): Promise<AppConfig> {
    return invoke('get_config');
  },
};
