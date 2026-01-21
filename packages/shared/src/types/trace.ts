import type { Capture } from "./capture";

export interface Trace {
  id: string;
  title: string;
  captures: Capture[];
  createdAt: string;
  updatedAt: string;
}
