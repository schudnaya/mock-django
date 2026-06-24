#!/usr/bin/env sh
set -eu

if [ $# -lt 1 ]; then
  echo "Usage: ./deploy/scripts/rollback.sh <git-tag-or-commit-sha>" >&2
  exit 1
fi

TARGET_REF="$1"

echo "==> Rolling back to $TARGET_REF"
git fetch --all --tags
git checkout "$TARGET_REF"

echo "==> Redeploying selected revision"
chmod +x deploy/scripts/*.sh
./deploy/scripts/deploy.sh

echo "==> Rollback finished"
