from django.db import models


class Secretaria(models.Model):
    """Secretaría institucional con auditoría."""
    codigo = models.CharField(max_length=20, unique=True)
    nombre = models.CharField(max_length=150)
    descripcion = models.TextField(blank=True)
    activa = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_modificacion = models.DateTimeField(auto_now=True, null=True, blank=True)
    usuario_creacion = models.CharField(max_length=100, blank=True)
    usuario_modificacion = models.CharField(max_length=100, blank=True)

    class Meta:
        ordering = ['codigo']
        verbose_name = 'Secretaría'
        verbose_name_plural = 'Secretarías'

    def __str__(self):
        return self.nombre
