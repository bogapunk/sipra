from rest_framework import viewsets
from .models import Secretaria
from .serializers import SecretariaSerializer


class SecretariaViewSet(viewsets.ModelViewSet):
    queryset = Secretaria.objects.all()
    serializer_class = SecretariaSerializer

    def get_queryset(self):
        qs = Secretaria.objects.all()
        activa = self.request.query_params.get('activa')
        if activa is not None:
            qs = qs.filter(activa=activa.lower() in ('true', '1', 'yes'))
        return qs
