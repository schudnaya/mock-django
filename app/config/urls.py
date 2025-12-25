from django.urls import path
from core.views import index, health

urlpatterns = [
    path("", index),
    path("health/", health),
]
