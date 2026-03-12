from rest_framework import viewsets
from .models import Secretaria
from .serializers import SecretariaSerializer
from users.access import ensure_read_only_for_roles, ROL_ADMIN, ROL_VISUALIZACION


class SecretariaViewSet(viewsets.ModelViewSet):
    queryset = Secretaria.objects.all()
    serializer_class = SecretariaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        ensure_read_only_for_roles(
            request.user,
            request,
            read_roles=(ROL_VISUALIZACION,),
            write_roles=(ROL_ADMIN,),
            message='Solo el Administrador puede gestionar secretarias.',
        )

    def get_queryset(self):
        qs = Secretaria.objects.all()
        activa = self.request.query_params.get('activa')
        if activa is not None:
            qs = qs.filter(activa=activa.lower() in ('true', '1', 'yes'))
        return qs
