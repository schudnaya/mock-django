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
