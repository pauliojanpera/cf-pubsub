import { EventEnvelope } from "./types";

export interface Env {}

export default {
  async queue(batch: MessageBatch<EventEnvelope>, env: Env) {
    for (const msg of batch.messages) {
      try {
        const event = msg.body;

        console.log(
          JSON.stringify({
            topic: event.topic,
            id: event.id,
            timestamp: event.timestamp,
            payload: event.payload
          })
        );

        msg.ack();
      } catch (err) {
        console.error(err);
        msg.retry();
      }
    }
  }
};
