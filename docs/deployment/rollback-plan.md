# План отката

## Когда выполнять откат

Откат выполняется, если после релиза обнаружены:

- приложение не запускается;
- `/health/` не отвечает HTTP 200;
- миграции привели к ошибкам;
- критичный пользовательский сценарий не работает;
- nginx не проксирует запросы к приложению.

## Подготовка

Перед каждым production-like релизом нужно выполнить:

```bash
./deploy/scripts/backup-db.sh
```

Также рекомендуется ставить git-тег на стабильную версию:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Откат к предыдущему коммиту или тегу

```bash
./deploy/scripts/rollback.sh <git-tag-or-commit-sha>
```

Пример:

```bash
./deploy/scripts/rollback.sh v1.0.0
```

## Проверка после отката

```bash
docker compose -f deploy/docker-compose.prod.yml ps
curl -f http://localhost/health/
```

## Восстановление БД

Если требуется восстановить БД из SQL-резервной копии:

```bash
cat backups/mockdb_YYYYMMDD_HHMMSS.sql | docker compose -f deploy/docker-compose.prod.yml exec -T db psql -U mockuser mockdb
```

Перед восстановлением нужно убедиться, что выбран правильный backup-файл.
