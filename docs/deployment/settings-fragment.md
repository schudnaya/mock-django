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
