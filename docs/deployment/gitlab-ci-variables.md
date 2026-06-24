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
