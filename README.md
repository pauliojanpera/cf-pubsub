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
