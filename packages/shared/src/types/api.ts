import type { Capture } from "./capture";
import type { Tag } from "./tag";

export type RefineStyle =
  | "professional"
  | "polite"
  | "friendly"
  | "shorter"
  | "longer";

export interface TimelineResponse {
  captures: Capture[];
  hasMore: boolean;
  nextCursor?: string;
}

export interface TypeCount {
  total: number;
  todayCount: number;
}

export interface EntitySummary {
  people: number;
  companies: number;
  projects: number;
}

export interface TypesSummary {
  thoughts: TypeCount;
  links: TypeCount;
  files: TypeCount;
  images: TypeCount;
  entities: EntitySummary;
}

export interface RefineMessageInput {
  context: string;
  message: string;
  style?: RefineStyle;
}

export interface RefineMessageResponse {
  refined: string;
}

export type ErrorCode =
  | "INVALID_INPUT"
  | "NOT_FOUND"
  | "AI_API_ERROR"
  | "FILE_TOO_LARGE"
  | "UNSUPPORTED_FILE_TYPE"
  | "INTERNAL_ERROR";

export interface ErrorResponse {
  code: ErrorCode;
  message: string;
  details?: Record<string, unknown>;
}

export interface AiProcessingCompleteEvent {
  captureId: string;
  tags: Tag[];
  summary?: string;
}

export interface TraceCreatedEvent {
  trace: import("./trace").Trace;
}

export interface TraceUpdatedEvent {
  traceId: string;
  captureId: string;
}
