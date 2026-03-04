"""
Vistas de login y auth. Importa desde jwt_auth para evitar circular.
"""
from django.contrib.auth.hashers import check_password

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .models import Usuario
from .jwt_auth import generate_token


class LoginView(APIView):
    """Login con email y contraseña. Retorna JWT y datos del usuario."""

    permission_classes = [AllowAny]

    def post(self, request):
        email = (request.data.get('email') or '').strip().lower()
        password = request.data.get('password') or ''
        if not email or not password:
            return Response(
                {'error': 'Se requiere email y contraseña.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            usuario = Usuario.objects.select_related('rol', 'area', 'secretaria').get(
                email__iexact=email, estado=True
            )
        except Usuario.DoesNotExist:
            return Response(
                {'error': 'Credenciales incorrectas.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        if not check_password(password, usuario.password):
            return Response(
                {'error': 'Credenciales incorrectas.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        token = generate_token(usuario)
        return Response({
            'success': True,
            'token': token,
            'user': {
                'id': usuario.id,
                'nombre': usuario.nombre,
                'apellido': usuario.apellido or '',
                'nombreCompleto': usuario.nombre_completo,
                'email': usuario.email,
                'rol': usuario.rol_id,
                'rolNombre': usuario.rol.nombre,
                'area': usuario.area_id,
                'areaNombre': usuario.area.nombre if usuario.area else '',
                'secretaria': usuario.secretaria_id,
                'secretariaNombre': usuario.secretaria.nombre if usuario.secretaria else '',
            },
        })


class AuthMeView(APIView):
    """Devuelve el usuario actual desde el token JWT."""

    def get(self, request):
        usuario = getattr(request, 'user', None)
        if not usuario or not isinstance(usuario, Usuario):
            return Response({'error': 'No autenticado.'}, status=status.HTTP_401_UNAUTHORIZED)
        return Response({
            'success': True,
            'user': {
                'id': usuario.id,
                'nombre': usuario.nombre,
                'apellido': usuario.apellido or '',
                'nombreCompleto': usuario.nombre_completo,
                'email': usuario.email,
                'rol': usuario.rol_id,
                'rolNombre': usuario.rol.nombre,
                'area': usuario.area_id,
                'areaNombre': usuario.area.nombre if usuario.area else '',
                'secretaria': usuario.secretaria_id,
                'secretariaNombre': usuario.secretaria.nombre if usuario.secretaria else '',
            },
        })
