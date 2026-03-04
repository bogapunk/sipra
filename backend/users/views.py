from rest_framework import viewsets, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Usuario, Rol
from .serializers import UsuarioSerializer, RolSerializer


class RolViewSet(viewsets.ModelViewSet):
    queryset = Rol.objects.all()
    serializer_class = RolSerializer


class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = Usuario.objects.all()  # Base para el router; get_queryset filtra
    serializer_class = UsuarioSerializer

    def get_queryset(self):
        """Por defecto solo usuarios activos. Incluir inactivos con ?incluir_inactivos=1"""
        qs = Usuario.objects.select_related('rol', 'area', 'secretaria').order_by('nombre', 'apellido')
        if self.action == 'list' and self.request.query_params.get('incluir_inactivos') != '1':
            qs = qs.filter(estado=True)
        return qs

    def destroy(self, request, *args, **kwargs):
        """Eliminación lógica: desactiva el usuario en lugar de borrarlo (evita ProtectedError)."""
        instance = self.get_object()
        instance.estado = False
        instance.save(update_fields=['estado'])
        return Response(status=status.HTTP_204_NO_CONTENT)


class UsuariosParaSelectorView(APIView):
    """Lista de usuarios (id, nombre, apellido, nombre_completo) para selectores.
    Parámetros opcionales: area, secretaria - filtra usuarios por área o secretaría."""
    def get(self, request):
        usuarios = Usuario.objects.filter(estado=True).order_by('nombre', 'apellido')
        area_id = request.query_params.get('area')
        secretaria_id = request.query_params.get('secretaria')
        if area_id:
            try:
                usuarios = usuarios.filter(area_id=int(area_id))
            except (ValueError, TypeError):
                pass
        if secretaria_id:
            try:
                usuarios = usuarios.filter(secretaria_id=int(secretaria_id))
            except (ValueError, TypeError):
                pass
        data = [{'id': u.id, 'nombre': u.nombre, 'apellido': u.apellido or '', 'nombre_completo': u.nombre_completo} for u in usuarios]
        return Response(data)
