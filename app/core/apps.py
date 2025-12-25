from django.http import JsonResponse
from django.db import connection

def index(request):
    return JsonResponse({
        "status": "ok",
        "service": "django-mock"
    })

def health(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1;")
            cursor.fetchone()
        return JsonResponse({"db": "ok"})
    except Exception as e:
        return JsonResponse({"db": "error", "detail": str(e)}, status=500)
