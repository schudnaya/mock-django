# Инструкция по развертыванию mock-django

## 1. Локальная проверка

Из корня репозитория:

```bash
docker compose up -d --build
```

Проверка:

```bash
curl -f http://localhost:8080/health/
```

## 2. Production-like запуск

Создать `.env`:

```bash
cp .env.example .env
```

Отредактировать значения:

```bash
nano .env
```

Запустить:

```bash
chmod +x deploy/scripts/*.sh
./deploy/scripts/deploy.sh
```

Проверить контейнеры:

```bash
docker compose -f deploy/docker-compose.prod.yml ps
```

Проверить доступность:

```bash
curl -f http://localhost/health/
```

## 3. Миграции

Миграции выполняются внутри `deploy.sh`, но при необходимости можно запустить вручную:

```bash
docker compose -f deploy/docker-compose.prod.yml run --rm web python manage.py migrate --noinput
```

## 4. Резервное копирование БД

```bash
./deploy/scripts/backup-db.sh
```

Резервные копии сохраняются в папку `backups/`, которая не должна попадать в git.

## 5. Остановка

```bash
docker compose -f deploy/docker-compose.prod.yml down
```

Остановка с удалением volume БД выполняется только осознанно:

```bash
docker compose -f deploy/docker-compose.prod.yml down -v
```

## 6. Минимальные требования к серверу

- Linux-сервер;
- Docker;
- Docker Compose plugin;
- доступ по SSH для GitLab Runner;
- открытые порты 80/443 или демонстрационный порт;
- права пользователя на запуск Docker.
