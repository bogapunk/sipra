from django.db import models
from django.core.exceptions import ValidationError


class Rol(models.Model):
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True)

    def __str__(self):
        return self.nombre


class Usuario(models.Model):
    nombre = models.CharField(max_length=150)
    apellido = models.CharField(max_length=150, blank=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    rol = models.ForeignKey(Rol, on_delete=models.PROTECT)
    area = models.ForeignKey('areas.Area', on_delete=models.PROTECT, null=True, blank=True, related_name='usuarios')
    secretaria = models.ForeignKey(
        'secretarias.Secretaria', on_delete=models.PROTECT, null=True, blank=True, related_name='usuarios'
    )
    estado = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def clean(self):
        if self.area_id and self.secretaria_id:
            raise ValidationError('Un usuario puede pertenecer a un Área O a una Secretaría, no a ambas.')

    def __str__(self):
        return self.nombre_completo

    @property
    def nombre_completo(self):
        return f"{self.nombre} {self.apellido}".strip()
