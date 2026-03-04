from django.db import models
from django.conf import settings


class SystemRestoreLog(models.Model):
    """Registro de cada operación de restore ejecutada."""
    user = models.ForeignKey(
        'users.Usuario',
        on_delete=models.SET_NULL,
        null=True,
        related_name='restore_logs'
    )
    backup_file = models.CharField(max_length=255)
    executed_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        ordering = ['-executed_at']
        verbose_name = 'Log de Restore'
        verbose_name_plural = 'Logs de Restore'

    def __str__(self):
        return f"Restore {self.backup_file} por {self.user} el {self.executed_at}"


class ActiveSession(models.Model):
    """Sesiones activas para validar restore (solo 1 usuario permitido)."""
    user = models.ForeignKey(
        'users.Usuario',
        on_delete=models.CASCADE,
        related_name='active_sessions'
    )
    last_activity = models.DateTimeField(auto_now=True)
    session_key = models.CharField(max_length=64, unique=True, db_index=True)

    class Meta:
        ordering = ['-last_activity']
        verbose_name = 'Sesión activa'
        verbose_name_plural = 'Sesiones activas'
