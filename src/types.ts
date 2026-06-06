export type EventEnvelope<T = unknown> = {
  id: string;
  topic: string;
  timestamp: number;
  payload: T;
};
