export interface Tag {
  id: string;
  name: string;
  color?: string;
  count: number;
}

export interface TagBlock {
  tag: Tag;
  position: { x: number; y: number };
  captures: import("./capture").CapturePreview[];
}

export interface CanvasLayout {
  tags: TagBlock[];
  version: string;
}
