#!/usr/bin/env sh

set -eu

REPO_NAME="cf-pubsub"
VISIBILITY="public"   # public | private

if [ ! -d ".git" ]; then
  git init
fi

git add .
git commit -m "Initial commit" || true

gh repo create "$REPO_NAME" \
  --"$VISIBILITY" \
  --source=. \
  --remote=origin \
  --push

echo
echo "Repository created and pushed."
echo

gh repo view --web
