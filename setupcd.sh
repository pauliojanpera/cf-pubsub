#!/usr/bin/env sh

set -eu

mkdir -p .github/workflows

cat > .github/workflows/deploy.yml <<'EOF'
name: Deploy Cloudflare Worker

on:
  push:
    branches:
      - main

  workflow_dispatch:

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Install dependencies
        run: npm ci || npm install

      - name: Deploy Worker
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: deploy
EOF

echo "Created .github/workflows/deploy.yml"
