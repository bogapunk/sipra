from django.db import models


class Area(models.Model):
    nombre = models.CharField(max_length=120)
    descripcion = models.TextField(blank=True)
    estado = models.BooleanField(default=True)
    # Responsable general del área (opcional, para autocompletar al crear proyectos)
    usuario_responsable_area = models.ForeignKey(
        'users.Usuario', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='area_responsable'
    )

    def __str__(self):
        return self.nombre
