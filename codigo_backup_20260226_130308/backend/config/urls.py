from django.urls import path, include
from django.http import JsonResponse


def api_root(request):
    return JsonResponse({
        "mensaje": "API Sistema de Seguimiento de Proyectos",
        "api": "http://localhost:8001/api/",
        "endpoints": ["/api/proyectos/", "/api/tareas/", "/api/areas/", "/api/usuarios/", "/api/roles/", "/api/dashboard/ejecutivo/"],
    })


urlpatterns = [
    path("", api_root),
    path("api/", include("projects.urls")),
]
