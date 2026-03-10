"""
Autenticación JWT - solo la clase de autenticación (evita import circular).
"""
import jwt
from datetime import datetime, timedelta
from django.utils import timezone
from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

from .models import Usuario


def _get_jwt_secret():
    return getattr(settings, 'SECRET_KEY', 'fallback-secret')


def generate_token(usuario: Usuario, expires_hours: int | None = None) -> str:
    """Genera un JWT para el usuario."""
    ttl_hours = expires_hours if expires_hours is not None else getattr(settings, 'JWT_EXPIRES_HOURS', 8)
    now = timezone.now()
    payload = {
        'user_id': usuario.id,
        'email': usuario.email,
        'token_version': getattr(usuario, 'token_version', 1),
        'iss': getattr(settings, 'JWT_ISSUER', 'sipra'),
        'aud': getattr(settings, 'JWT_AUDIENCE', 'sipra-web'),
        'exp': now + timedelta(hours=ttl_hours),
        'iat': now,
    }
    return jwt.encode(payload, _get_jwt_secret(), algorithm='HS256')


def usuario_from_token(token: str) -> Usuario | None:
    """Decodifica el JWT y retorna el Usuario o None."""
    try:
        payload = jwt.decode(
            token,
            _get_jwt_secret(),
            algorithms=['HS256'],
            issuer=getattr(settings, 'JWT_ISSUER', 'sipra'),
            audience=getattr(settings, 'JWT_AUDIENCE', 'sipra-web'),
        )
        user_id = payload.get('user_id')
        if not user_id:
            return None
        usuario = Usuario.objects.select_related('rol', 'area', 'secretaria').get(id=user_id, estado=True)
        if int(payload.get('token_version', 1)) != int(getattr(usuario, 'token_version', 1)):
            return None
        return usuario
    except (jwt.InvalidTokenError, Usuario.DoesNotExist):
        return None


class JWTAuthentication(BaseAuthentication):
    """Autenticación por Bearer JWT."""

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if not auth_header or not auth_header.startswith('Bearer '):
            return None
        token = auth_header[7:].strip()
        usuario = usuario_from_token(token)
        if not usuario:
            raise AuthenticationFailed('Token inválido o expirado.')
        return (usuario, token)
