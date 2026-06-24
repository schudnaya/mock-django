#!/usr/bin/env sh
set -eu

COMPOSE_FILE="deploy/docker-compose.prod.yml"
BACKUP_DIR="backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

if [ ! -f ".env" ]; then
  echo "ERROR: .env file is missing. Cannot read database variables." >&2
  exit 1
fi

set -a
. ./.env
set +a

mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/${POSTGRES_DB:-mockdb}_${TIMESTAMP}.sql"

echo "==> Creating PostgreSQL backup: $BACKUP_FILE"
docker compose -f "$COMPOSE_FILE" exec -T db \
  pg_dump -U "${POSTGRES_USER:-mockuser}" "${POSTGRES_DB:-mockdb}" > "$BACKUP_FILE"

echo "==> Backup completed: $BACKUP_FILE"
