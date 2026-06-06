#!/usr/bin/env sh

set -eu

PROJECT="cf-pubsub"

mkdir -p "$PROJECT/src"

cat > "$PROJECT/wrangler.toml" <<'EOF'
name = "cf-pubsub"
main = "src/producer.ts"
compatibility_date = "2026-01-01"

[[queues.producers]]
binding = "EVENT_QUEUE"
queue = "event-queue"

[[queues.consumers]]
queue = "event-queue"
max_batch_size = 10
max_batch_timeout = 5
EOF

cat > "$PROJECT/package.json" <<'EOF'
{
  "name": "cf-pubsub",
  "private": true,
  "type": "module",
  "dependencies": {
    "typescript": "^5.5.0"
  },
  "devDependencies": {
    "wrangler": "^4.0.0"
  }
}
EOF

cat > "$PROJECT/src/types.ts" <<'EOF'
export type EventEnvelope<T = unknown> = {
  id: string;
  topic: string;
  timestamp: number;
  payload: T;
};
EOF

cat > "$PROJECT/src/producer.ts" <<'EOF'
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
EOF

cat > "$PROJECT/src/consumer.ts" <<'EOF'
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
EOF

cat > "$PROJECT/README.md" <<'EOF'
# Cloudflare Pub/Sub

Simple event transport built on Cloudflare Workers + Queues.

## Create queue

npx wrangler queues create event-queue

## Deploy

npm install
npx wrangler deploy

## Publish

curl -X POST \
  "https://your-worker.workers.dev?topic=test" \
  -H "content-type: application/json" \
  -d '{"hello":"world"}'
EOF

cat > "$PROJECT/.gitignore" <<'EOF'
node_modules
dist
.wrangler
EOF

echo "Project created: $PROJECT"

if command -v zip >/dev/null 2>&1; then
  zip -r "${PROJECT}.zip" "$PROJECT"
  echo "Archive created: ${PROJECT}.zip"
fi
