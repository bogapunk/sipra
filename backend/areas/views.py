from rest_framework import viewsets
from .models import Area
from .serializers import AreaSerializer
from users.access import require_roles, ROL_ADMIN


def asegurar_presidencia():
    """Crea el área Presidencia si no existe."""
    Area.objects.get_or_create(nombre='Presidencia', defaults={'estado': True})


class AreaViewSet(viewsets.ModelViewSet):
    queryset = Area.objects.all()
    serializer_class = AreaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        require_roles(request.user, ROL_ADMIN, message='Solo el Administrador puede gestionar áreas.')

    def get_queryset(self):
        qs = Area.objects.all()
        estado = self.request.query_params.get('estado')
        if estado is not None:
            qs = qs.filter(estado=estado.lower() in ('true', '1', 'yes'))
        return qs

    def list(self, request, *args, **kwargs):
        asegurar_presidencia()
        return super().list(request, *args, **kwargs)
