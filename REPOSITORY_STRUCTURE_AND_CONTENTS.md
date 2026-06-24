# Структура и наполнение файлов для репозитория mock-django

```text
.
├── .env.example
├── .gitignore
├── .gitlab-ci.yml
├── README_DEPLOYMENT.md
├── deploy/docker-compose.prod.yml
├── deploy/nginx/default.conf
├── deploy/scripts/backup-db.sh
├── deploy/scripts/deploy.sh
├── deploy/scripts/rollback.sh
├── docs/deployment/README.md
├── docs/deployment/deployment-guide.md
├── docs/deployment/gitlab-ci-variables.md
├── docs/deployment/release-checklist.md
├── docs/deployment/risk-register.md
├── docs/deployment/roadmap.md
├── docs/deployment/rollback-plan.md
├── docs/deployment/settings-fragment.md
├── docs/pdf/cbs_mock_django_acceptance_checklist.pdf
├── docs/pdf/cbs_mock_django_deployment_artifacts.pdf
├── docs/pdf/cbs_mock_django_roadmap.pdf
```

## `.env.example`
```text
# Example production-like environment for mock-django.
# Copy this file to .env on the deployment server and replace all placeholder values.
# Do not commit real secrets to the repository.

DEBUG=False
SECRET_KEY=change-me-generate-a-long-random-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1,example.org
CSRF_TRUSTED_ORIGINS=http://localhost,http://127.0.0.1,https://example.org

POSTGRES_DB=mockdb
POSTGRES_USER=mockuser
POSTGRES_PASSWORD=change-me
POSTGRES_HOST=db
POSTGRES_PORT=5432

GUNICORN_WORKERS=3
HEALTHCHECK_URL=http://localhost/health/
```

## `.gitignore`
```gitignore
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
.pytest_cache/
.coverage
htmlcov/

# Django
*.log
db.sqlite3
staticfiles/
media/

# Local environment and secrets
.env
.env.*
!.env.example

# Deployment artifacts
backups/
*.sql
*.dump

# IDE / OS
.vscode/
.idea/
.DS_Store
```

## `.gitlab-ci.yml`
```yaml
# GitLab CI/CD pipeline for mock-django.
# The file is intended for a GitLab mirror/import of the GitHub repository.
# Required CI/CD variables are described in docs/deployment/gitlab-ci-variables.md.

stages:
  - validate
  - test
  - build
  - deploy

variables:
  PYTHONUNBUFFERED: "1"
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"
  POSTGRES_DB: "mockdb"
  POSTGRES_USER: "mockuser"
  POSTGRES_PASSWORD: "mockpass"
  POSTGRES_HOST: "postgres"
  POSTGRES_PORT: "5432"
  DJANGO_SETTINGS_MODULE: "config.settings"

cache:
  paths:
    - .cache/pip/

python_check:
  stage: validate
  image: python:3.11-alpine
  before_script:
    - apk add --no-cache gcc musl-dev postgresql-dev
    - pip install --upgrade pip
    - pip install -r requirements.txt
  script:
    - cd app
    - python manage.py check
  rules:
    - if: '$CI_COMMIT_BRANCH'

django_tests:
  stage: test
  image: python:3.11-alpine
  services:
    - name: postgres:15-alpine
      alias: postgres
  before_script:
    - apk add --no-cache gcc musl-dev postgresql-dev
    - pip install --upgrade pip
    - pip install -r requirements.txt
  script:
    - cd app
    - python manage.py migrate --noinput
    - python manage.py test --noinput
  rules:
    - if: '$CI_COMMIT_BRANCH'

docker_build:
  stage: build
  image: docker:27
  services:
    - name: docker:27-dind
      command: ["--tls=false"]
  variables:
    DOCKER_HOST: "tcp://docker:2375"
    DOCKER_TLS_CERTDIR: ""
  before_script:
    - docker version
  script:
    - docker build -t "$CI_REGISTRY_IMAGE/mock-django:$CI_COMMIT_SHORT_SHA" .
    - |
      if [ -n "$CI_REGISTRY" ]; then
        echo "$CI_REGISTRY_PASSWORD" | docker login "$CI_REGISTRY" -u "$CI_REGISTRY_USER" --password-stdin
        docker push "$CI_REGISTRY_IMAGE/mock-django:$CI_COMMIT_SHORT_SHA"
      fi
  rules:
    - if: '$CI_COMMIT_BRANCH'

deploy_staging:
  stage: deploy
  image: alpine:3.20
  before_script:
    - apk add --no-cache openssh-client bash
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - printf "%s" "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - printf "%s
" "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
  script:
    - >
      ssh "$DEPLOY_USER@$DEPLOY_HOST"
      "cd '$DEPLOY_PATH'
      && git fetch --all
      && git checkout '$CI_COMMIT_SHA'
      && chmod +x deploy/scripts/*.sh
      && ./deploy/scripts/deploy.sh"
  environment:
    name: staging
    url: $STAGING_URL
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      when: manual

deploy_production:
  stage: deploy
  image: alpine:3.20
  before_script:
    - apk add --no-cache openssh-client bash
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - printf "%s" "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - printf "%s
" "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
  script:
    - >
      ssh "$DEPLOY_USER@$DEPLOY_HOST"
      "cd '$DEPLOY_PATH'
      && git fetch --all
      && git checkout '$CI_COMMIT_SHA'
      && chmod +x deploy/scripts/*.sh
      && ./deploy/scripts/backup-db.sh
      && ./deploy/scripts/deploy.sh"
  environment:
    name: production
    url: $PRODUCTION_URL
  rules:
    - if: '$CI_COMMIT_TAG'
      when: manual
```

## `README_DEPLOYMENT.md`
```markdown
# Материалы по развертыванию mock-django

Этот раздел репозитория содержит организационные и технические материалы для применения CI/CD-подхода к проекту `mock-django`.

## Что добавлено

- `.gitlab-ci.yml` — пример GitLab CI/CD pipeline: проверка Django, тесты, сборка Docker-образа, ручное развертывание.
- `.env.example` — шаблон переменных окружения без секретов.
- `deploy/docker-compose.prod.yml` — production-like Docker Compose конфигурация.
- `deploy/nginx/default.conf` — пример конфигурации reverse proxy.
- `deploy/scripts/` — скрипты развертывания, резервного копирования БД и отката.
- `docs/deployment/` — дорожная карта, инструкции, чек-листы, риск-регистр.
- `docs/pdf/` — PDF-материалы, подготовленные в процессе выполнения задания.

## Рекомендуемый порядок размещения

1. Добавить файлы из этого комплекта в корень репозитория.
2. Убедиться, что реальные значения секретов не попали в git.
3. На сервере развертывания создать `.env` на основе `.env.example`.
4. В GitLab CI/CD настроить защищенные переменные из `docs/deployment/gitlab-ci-variables.md`.
5. Проверить локальный запуск:
   ```bash
   docker compose -f deploy/docker-compose.prod.yml up -d --build
   ```
6. Проверить endpoint работоспособности:
   ```bash
   curl -f http://localhost/health/ || curl -f http://localhost:8080/health/
   ```

## Важное замечание

Репозиторий расположен на GitHub, поэтому `.gitlab-ci.yml` не будет выполняться GitHub автоматически. Он нужен для GitLab-зеркала, GitLab-import или демонстрации переноса схемы развертывания из GitLab-проекта. Если требуется запуск именно в GitHub, аналогичный workflow можно дополнительно оформить в `.github/workflows/ci.yml`.
```

## `deploy/docker-compose.prod.yml`
```yaml
services:
  web:
    build:
      context: ..
      dockerfile: Dockerfile
    container_name: cbs-mock-django-web
    restart: unless-stopped
    command: >
      gunicorn config.wsgi:application
      --bind 0.0.0.0:8000
      --workers ${GUNICORN_WORKERS:-3}
      --timeout 120
    env_file:
      - ../.env
    environment:
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
    expose:
      - "8000"
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - static_volume:/app/app/staticfiles
    networks:
      - cbs-network

  db:
    image: postgres:15-alpine
    container_name: cbs-mock-django-db
    restart: unless-stopped
    env_file:
      - ../.env
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-mockdb}
      POSTGRES_USER: ${POSTGRES_USER:-mockuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mockpass}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-mockuser} -d ${POSTGRES_DB:-mockdb}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - cbs-network

  nginx:
    image: nginx:1.27-alpine
    container_name: cbs-mock-django-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - static_volume:/static:ro
    depends_on:
      - web
    networks:
      - cbs-network

volumes:
  postgres_data:
  static_volume:

networks:
  cbs-network:
    driver: bridge
```

## `deploy/nginx/default.conf`
```nginx
upstream django_app {
    server web:8000;
}

server {
    listen 80;
    server_name _;

    client_max_body_size 20m;

    location /static/ {
        alias /static/;
        expires 7d;
        add_header Cache-Control "public";
    }

    location /health/ {
        proxy_pass http://django_app/health/;
        access_log off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://django_app;
        proxy_http_version 1.1;
        proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## `deploy/scripts/deploy.sh`
```bash
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
```

## `deploy/scripts/backup-db.sh`
```bash
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
docker compose -f "$COMPOSE_FILE" exec -T db   pg_dump -U "${POSTGRES_USER:-mockuser}" "${POSTGRES_DB:-mockdb}" > "$BACKUP_FILE"

echo "==> Backup completed: $BACKUP_FILE"
```

## `deploy/scripts/rollback.sh`
```bash
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
```

## `docs/deployment/README.md`
```markdown
# Документация по развертыванию

Документы в этой папке описывают перенос CI/CD-подхода на проект `mock-django`, разрабатываемый для ЦБС Петроградского района.

## Состав документации

- `roadmap.md` — дорожная карта внедрения.
- `deployment-guide.md` — техническая инструкция по запуску и развертыванию.
- `gitlab-ci-variables.md` — переменные, которые нужно завести в GitLab CI/CD.
- `release-checklist.md` — чек-лист приемки и релиза.
- `rollback-plan.md` — порядок отката.
- `risk-register.md` — основные риски и меры снижения.
- `settings-fragment.md` — пример изменений в настройках Django для production-like окружения.

PDF-версии материалов размещаются в `docs/pdf/`.
```

## `docs/deployment/roadmap.md`
```markdown
# Дорожная карта внедрения CI/CD и развертывания mock-django

## Цель

Применить к проекту `mock-django` подход развертывания, аналогичный учебному GitLab-проекту: контейнеризация, автоматические проверки, сборка Docker-образа, управляемое развертывание, приемка и возможность отката.

## Этап 1. Организационная подготовка

**Действия:**

1. Зафиксировать ответственных:
   - владелец репозитория;
   - ответственный за CI/CD;
   - ответственный за сервер развертывания;
   - ответственный за приемку.
2. Определить окружения:
   - локальное;
   - тестовое / staging;
   - production-like демонстрационное.
3. Зафиксировать критерии готовности:
   - приложение запускается в Docker;
   - БД поднимается отдельным контейнером;
   - endpoint `/health/` отвечает HTTP 200;
   - миграции применяются автоматически;
   - есть резервная копия БД перед релизом;
   - есть инструкция отката.

**Результат:** утвержденный план работ и список ответственных.

## Этап 2. Подготовка репозитория

**Действия:**

1. Добавить `.env.example`.
2. Добавить `.gitignore`, исключающий `.env`, резервные копии и временные файлы.
3. Добавить папку `deploy/`:
   - `docker-compose.prod.yml`;
   - `nginx/default.conf`;
   - `scripts/deploy.sh`;
   - `scripts/backup-db.sh`;
   - `scripts/rollback.sh`.
4. Добавить папку `docs/deployment/`.
5. Добавить PDF-материалы в `docs/pdf/`.

**Результат:** репозиторий содержит не только код, но и воспроизводимую схему развертывания.

## Этап 3. Техническая адаптация Django

**Действия:**

1. Проверить чтение параметров из переменных окружения:
   - `SECRET_KEY`;
   - `DEBUG`;
   - `ALLOWED_HOSTS`;
   - параметры PostgreSQL.
2. Проверить работу `python manage.py check`.
3. Проверить миграции:
   ```bash
   python manage.py migrate --noinput
   ```
4. Проверить healthcheck:
   ```bash
   curl -f http://localhost/health/
   ```

**Результат:** приложение готово к запуску через CI/CD и контейнерную инфраструктуру.

## Этап 4. Настройка GitLab CI/CD

**Действия:**

1. Добавить `.gitlab-ci.yml` в корень репозитория.
2. Создать защищенные переменные CI/CD:
   - `SSH_PRIVATE_KEY`;
   - `SSH_KNOWN_HOSTS`;
   - `DEPLOY_USER`;
   - `DEPLOY_HOST`;
   - `DEPLOY_PATH`;
   - `STAGING_URL`;
   - `PRODUCTION_URL`.
3. Запустить pipeline:
   - validate;
   - test;
   - build;
   - deploy.

**Результат:** изменения проходят автоматическую проверку и могут быть развернуты вручную.

## Этап 5. Развертывание

**Действия:**

1. На сервере установить Docker и Docker Compose plugin.
2. Клонировать репозиторий.
3. Создать `.env` на основе `.env.example`.
4. Выполнить:
   ```bash
   chmod +x deploy/scripts/*.sh
   ./deploy/scripts/deploy.sh
   ```
5. Проверить:
   ```bash
   docker compose -f deploy/docker-compose.prod.yml ps
   curl -f http://localhost/health/
   ```

**Результат:** приложение доступно через nginx и подключено к PostgreSQL.

## Этап 6. Приемка и сопровождение

**Действия:**

1. Пройти `release-checklist.md`.
2. Сохранить результат приемки.
3. Проверить резервную копию БД.
4. Проверить инструкцию отката.
5. Оформить релиз тегом:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

**Результат:** развертывание воспроизводимо и документировано.
```

## `docs/deployment/deployment-guide.md`
```markdown
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
```

## `docs/deployment/gitlab-ci-variables.md`
```markdown
# Переменные GitLab CI/CD

Эти переменные нужно добавить в GitLab:  
`Settings` → `CI/CD` → `Variables`.

## Обязательные переменные

| Переменная | Пример | Назначение |
|---|---|---|
| `DEPLOY_USER` | `deploy` | Пользователь сервера развертывания |
| `DEPLOY_HOST` | `192.0.2.10` | IP или домен сервера |
| `DEPLOY_PATH` | `/opt/mock-django` | Путь к репозиторию на сервере |
| `SSH_PRIVATE_KEY` | содержимое приватного ключа | Ключ для подключения GitLab Runner к серверу |
| `SSH_KNOWN_HOSTS` | строка из `ssh-keyscan` | Защита от подмены SSH-хоста |
| `STAGING_URL` | `http://staging.example.org` | Адрес тестового окружения |
| `PRODUCTION_URL` | `https://example.org` | Адрес production-like окружения |

## Рекомендуемые protected/masked параметры

| Переменная | Почему защищать |
|---|---|
| `SSH_PRIVATE_KEY` | дает доступ к серверу |
| `POSTGRES_PASSWORD` | пароль БД |
| `DJANGO_SECRET_KEY` | криптографический ключ Django |

## Получение SSH_KNOWN_HOSTS

На локальной машине:

```bash
ssh-keyscan -H <DEPLOY_HOST>
```

Скопировать вывод в переменную `SSH_KNOWN_HOSTS`.

## Примечание

Если репозиторий остается только на GitHub, `.gitlab-ci.yml` не запустится автоматически. Для выполнения pipeline нужен GitLab mirror/import или отдельный GitLab-проект, подключенный к этому коду.
```

## `docs/deployment/release-checklist.md`
```markdown
# Чек-лист приемки и релиза

## Перед релизом

- [ ] Все изменения закоммичены.
- [ ] Реальные секреты не добавлены в git.
- [ ] `.env.example` актуален.
- [ ] `python manage.py check` проходит без ошибок.
- [ ] Миграции применяются без ошибок.
- [ ] Docker-образ собирается.
- [ ] `docker-compose.prod.yml` запускает web, db и nginx.
- [ ] `/health/` возвращает HTTP 200.
- [ ] Создана резервная копия БД.
- [ ] Проверен план отката.

## Во время релиза

- [ ] Запущен pipeline.
- [ ] Успешны стадии validate, test и build.
- [ ] Развертывание staging выполнено вручную.
- [ ] Проведена smoke-проверка staging.
- [ ] Production-like развертывание подтверждено ответственным.
- [ ] Выполнен deploy production-like окружения.

## После релиза

- [ ] Проверен статус контейнеров.
- [ ] Проверен `/health/`.
- [ ] Проверены основные пользовательские сценарии.
- [ ] Зафиксирована версия релиза.
- [ ] Зафиксированы замечания и дальнейшие задачи.
```

## `docs/deployment/rollback-plan.md`
```markdown
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
```

## `docs/deployment/risk-register.md`
```markdown
# Риск-регистр

| Риск | Вероятность | Влияние | Меры снижения |
|---|---:|---:|---|
| Секреты попадут в репозиторий | Средняя | Высокое | Использовать `.env.example`, добавить `.env` в `.gitignore`, проверить историю git |
| Pipeline не запустится, так как репозиторий находится на GitHub | Средняя | Среднее | Использовать GitLab mirror/import или рассматривать `.gitlab-ci.yml` как артефакт проектирования |
| Ошибка подключения к PostgreSQL | Средняя | Высокое | Проверить переменные `POSTGRES_*`, healthcheck БД, порядок запуска сервисов |
| Миграции нарушат данные | Низкая/средняя | Высокое | Делать backup перед релизом, тестировать миграции на staging |
| Сервер не имеет прав на Docker | Средняя | Среднее | Добавить deploy-пользователя в группу docker или настроить sudo-политику |
| Нет endpoint `/health/` | Средняя | Среднее | Добавить простой view/URL или middleware для проверки работоспособности |
| Конфликт портов 80/8080 | Средняя | Среднее | Проверить занятые порты, изменить mapping в `docker-compose.prod.yml` |
| Отсутствует стратегия отката | Низкая | Высокое | Использовать `rollback.sh`, теги релизов и backup БД |
```

## `docs/deployment/settings-fragment.md`
```markdown
# Фрагмент настроек Django для production-like окружения

Этот фрагмент не нужно копировать автоматически без проверки текущего `app/config/settings.py`. Его задача — показать, какие изменения нужны, чтобы приложение корректно читало параметры из `.env`.

```python
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv("SECRET_KEY", "dev-only-secret-key")
DEBUG = os.getenv("DEBUG", "False").lower() == "true"

ALLOWED_HOSTS = [
    host.strip()
    for host in os.getenv("ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if host.strip()
]

CSRF_TRUSTED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("CSRF_TRUSTED_ORIGINS", "").split(",")
    if origin.strip()
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("POSTGRES_DB", "mockdb"),
        "USER": os.getenv("POSTGRES_USER", "mockuser"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD", "mockpass"),
        "HOST": os.getenv("POSTGRES_HOST", "db"),
        "PORT": os.getenv("POSTGRES_PORT", "5432"),
    }
}

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
```

## Healthcheck

Если endpoint `/health/` отсутствует, можно добавить простой view.

Пример `app/config/urls.py`:

```python
from django.contrib import admin
from django.http import JsonResponse
from django.urls import path

def health(request):
    return JsonResponse({"status": "ok"})

urlpatterns = [
    path("admin/", admin.site.urls),
    path("health/", health, name="health"),
]
```
```
