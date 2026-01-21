export type TriggerType = "link" | "file_type" | "manual";

export interface Habit {
  id: string;
  name: string;
  description: string;
  triggerType: TriggerType;
  triggerPattern?: string;
  actionPrompt: string;
  isActive: boolean;
  isSystem: boolean;
  triggerCount: number;
  lastTriggeredAt?: string;
  createdAt: string;
}

export interface ParsedRule {
  triggerType: string;
  triggerPattern?: string;
  actions: string[];
  tags: string[];
}

export interface CreateHabitResponse {
  habit: Habit;
  parsedRule: ParsedRule;
}
