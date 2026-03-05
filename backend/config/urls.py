from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static


def api_root(request):
    base = request.build_absolute_uri('/').rstrip('/')
    return JsonResponse({
        "mensaje": "API Sistema de Seguimiento de Proyectos",
        "api": f"{base}/api/",
        "endpoints": ["/api/proyectos/", "/api/tareas/", "/api/areas/", "/api/usuarios/", "/api/roles/", "/api/dashboard/ejecutivo/"],
    })


urlpatterns = [
    path("", api_root),
    path("api/", include("projects.urls")),
]
# Servir archivos media desde Django en despliegues simples.
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
