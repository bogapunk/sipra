import os
from datetime import timedelta

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import SystemRestoreLog, ActiveSession
from .services import (
    create_backup,
    list_backups,
    create_code_backup,
    list_code_backups,
    restore_from_file,
    ensure_backup_dir,
)


def get_client_ip(request):
    """Obtiene la IP del cliente desde la petición."""
    x_forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded:
        return x_forwarded.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')


def require_admin_user(request):
    """Valida que el usuario sea administrador. Retorna (usuario, error_response)."""
    user_id = request.data.get('user_id') or request.query_params.get('user_id')
    if not user_id:
        return None, Response(
            {'error': 'Se requiere user_id para esta operación.'},
            status=status.HTTP_400_BAD_REQUEST
        )
    from users.models import Usuario
    from users.models import Rol
    try:
        usuario = Usuario.objects.get(id=user_id)
    except Usuario.DoesNotExist:
        return None, Response(
            {'error': 'Usuario no encontrado.'},
            status=status.HTTP_404_NOT_FOUND
        )
    try:
        admin_rol = Rol.objects.get(nombre='Administrador')
    except Rol.DoesNotExist:
        return None, Response(
            {'error': 'Rol Administrador no configurado.'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    if usuario.rol_id != admin_rol.id:
        return None, Response(
            {'error': 'Solo el rol Administrador puede ejecutar esta operación.'},
            status=status.HTTP_403_FORBIDDEN
        )
    return usuario, None


def count_active_sessions():
    """Cuenta usuarios con sesión activa (últimos N minutos)."""
    from django.conf import settings
    mins = getattr(settings, 'ACTIVE_SESSION_MINUTES', 5)
    cutoff = timezone.now() - timedelta(minutes=mins)
    return ActiveSession.objects.filter(last_activity__gte=cutoff).values('user_id').distinct().count()


class SessionHeartbeatView(APIView):
    """Registra/actualiza sesión activa del usuario. Llamar periódicamente desde el frontend."""

    def post(self, request):
        user_id = request.data.get('user_id')
        session_key = request.data.get('session_key') or request.META.get('HTTP_X_SESSION_KEY', '')
        if not user_id:
            return Response({'ok': False, 'error': 'user_id requerido'}, status=status.HTTP_400_BAD_REQUEST)
        if not session_key:
            return Response({'ok': False, 'error': 'session_key requerido'}, status=status.HTTP_400_BAD_REQUEST)

        from users.models import Usuario
        try:
            usuario = Usuario.objects.get(id=user_id)
        except Usuario.DoesNotExist:
            return Response({'ok': False, 'error': 'Usuario no encontrado'}, status=status.HTTP_404_NOT_FOUND)

        session, _ = ActiveSession.objects.update_or_create(
            session_key=session_key,
            defaults={'user': usuario}
        )
        return Response({'ok': True})


class SessionEndView(APIView):
    """Finaliza la sesión al cerrar o hacer logout."""

    def post(self, request):
        session_key = request.data.get('session_key') or request.META.get('HTTP_X_SESSION_KEY', '')
        if session_key:
            ActiveSession.objects.filter(session_key=session_key).delete()
        return Response({'ok': True})


class BackupListView(APIView):
    """Lista los backups disponibles (solo Admin)."""

    def get(self, request):
        usuario, err = require_admin_user(request)
        if err:
            return err
        backups = list_backups()
        return Response({'backups': backups})


class BackupCreateView(APIView):
    """Ejecuta un backup manual (solo Admin)."""

    def post(self, request):
        usuario, err = require_admin_user(request)
        if err:
            return err
        try:
            result = create_backup()
            return Response({
                'success': True,
                'message': 'Backup creado correctamente.',
                'path': result if isinstance(result, str) and os.path.exists(result) else None,
            })
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CodeBackupListView(APIView):
    """Lista los backups de código disponibles (solo Admin)."""

    def get(self, request):
        usuario, err = require_admin_user(request)
        if err:
            return err
        backups = list_code_backups()
        return Response({'backups': backups})


class CodeBackupCreateView(APIView):
    """Genera un backup del código del sistema en formato ZIP (solo Admin)."""

    def post(self, request):
        usuario, err = require_admin_user(request)
        if err:
            return err
        try:
            result = create_code_backup()
            return Response({
                'success': True,
                'message': 'Backup de código creado correctamente.',
                'path': result if isinstance(result, str) and os.path.exists(result) else None,
            })
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class RestoreView(APIView):
    """
    Restaura desde un backup.
    Flujo: validar admin → verificar usuarios activos → backup automático → log → restore.
    """

    def post(self, request):
        usuario, err = require_admin_user(request)
        if err:
            return err

        # 1. Verificar usuarios activos (más de 1 = bloquear)
        active_count = count_active_sessions()
        if active_count > 1:
            return Response(
                {'error': 'No se puede restaurar mientras haya usuarios activos en el sistema.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        backup_filename = request.data.get('backup_file') or request.data.get('filename')
        if not backup_filename:
            return Response(
                {'error': 'Se requiere backup_file o filename para restaurar.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 2. Ejecutar backup automático antes de restaurar
        try:
            create_backup()
        except Exception as e:
            return Response(
                {'error': f'No se pudo crear el backup previo antes del restore. {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # 3. Registrar log ANTES de ejecutar restore
        ip = get_client_ip(request)
        ip_addr = None
        if ip:
            try:
                from ipaddress import ip_address
                ip_address(ip)
                ip_addr = ip
            except ValueError:
                pass
        log = SystemRestoreLog.objects.create(
            user=usuario,
            backup_file=backup_filename,
            ip_address=ip_addr
        )

        # 4. Ejecutar restore
        try:
            restore_from_file(backup_filename)
        except Exception as e:
            return Response(
                {'error': f'Error al restaurar: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response({
            'success': True,
            'message': 'Restore ejecutado correctamente.',
            'log_id': log.id,
        })
