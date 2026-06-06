import { EventEnvelope } from "./types";

export interface Env {
  EVENT_QUEUE: Queue<EventEnvelope>;
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    if (req.method !== "POST") {
      return new Response("POST only", { status: 405 });
    }

    const url = new URL(req.url);
    const topic = url.searchParams.get("topic") || "default";

    let payload: unknown = {};

    try {
      payload = await req.json();
    } catch {
      return new Response(
        JSON.stringify({
          ok: false,
          error: "invalid json"
        }),
        {
          status: 400,
          headers: {
            "content-type": "application/json"
          }
        }
      );
    }

    const event: EventEnvelope = {
      id: crypto.randomUUID(),
      topic,
      timestamp: Date.now(),
      payload
    };

    await env.EVENT_QUEUE.send(event);

    return new Response(
      JSON.stringify({
        ok: true,
        id: event.id
      }),
      {
        headers: {
          "content-type": "application/json"
        }
      }
    );
  }
};
