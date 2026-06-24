#!/usr/bin/env sh
set -eu

COMPOSE_FILE="deploy/docker-compose.prod.yml"

if [ ! -f ".env" ]; then
  echo "ERROR: .env file is missing. Create it from .env.example before deployment." >&2
  exit 1
fi

echo "==> Building images"
docker compose -f "$COMPOSE_FILE" build

echo "==> Starting database"
docker compose -f "$COMPOSE_FILE" up -d db

echo "==> Applying migrations"
docker compose -f "$COMPOSE_FILE" run --rm web python manage.py migrate --noinput

echo "==> Collecting static files"
docker compose -f "$COMPOSE_FILE" run --rm web python manage.py collectstatic --noinput || true

echo "==> Starting application stack"
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

echo "==> Current containers"
docker compose -f "$COMPOSE_FILE" ps

echo "==> Deployment finished"
