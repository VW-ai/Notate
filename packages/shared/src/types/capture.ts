import type { Tag } from "./tag";

export type CaptureType = "thought" | "link" | "file" | "image";

export interface Capture {
  id: string;
  type: CaptureType;
  content: string;
  sourceUrl?: string;
  filePath?: string;
  thumbnailPath?: string;
  summary?: string;
  tags: Tag[];
  primaryTagId?: string;
  createdAt: string;
  updatedAt: string;
  isDeleted: boolean;
}

export interface CapturePreview {
  id: string;
  type: CaptureType;
  content: string;
  createdAt: string;
}

export interface CreateCaptureInput {
  type: CaptureType;
  content: string;
  // File data is passed separately via Tauri's file handling
  filePath?: string;
  habitId?: string;
}

export interface CreateCaptureResponse {
  capture: Capture;
  evolutionHint?: EvolutionHint;
}

export interface EvolutionHint {
  oldCapture: CapturePreview;
  similarity: number;
  daysAgo: number;
}

export interface CaptureDetail {
  capture: Capture;
  related: Capture[];
  trace?: TraceInfo;
}

export interface TraceInfo {
  id: string;
  title: string;
  position: number;
  total: number;
}
