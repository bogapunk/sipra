from django.db import models
from django.core.exceptions import ValidationError
from users.models import Usuario
from areas.models import Area
from projects.models import Proyecto, Etapa


class Tarea(models.Model):
    ESTADOS = [
        ("Pendiente", "Pendiente"),
        ("En proceso", "En proceso"),
        ("Finalizada", "Finalizada"),
        ("Bloqueada", "Bloqueada"),
    ]

    PRIORIDADES = [
        ("Baja", "Baja"),
        ("Media", "Media"),
        ("Alta", "Alta"),
    ]

    proyecto = models.ForeignKey(
        Proyecto, on_delete=models.CASCADE, related_name="tareas", null=True, blank=True
    )
    etapa = models.ForeignKey(Etapa, null=True, blank=True, on_delete=models.SET_NULL)
    area = models.ForeignKey(Area, on_delete=models.PROTECT, null=True, blank=True)
    secretaria = models.ForeignKey(
        'secretarias.Secretaria', on_delete=models.PROTECT, null=True, blank=True, related_name='tareas'
    )
    titulo = models.CharField(max_length=200)
    descripcion = models.TextField(blank=True)
    responsable = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    fecha_inicio = models.DateField()
    fecha_vencimiento = models.DateField()
    estado = models.CharField(max_length=20, choices=ESTADOS, default="Pendiente")
    porcentaje_avance = models.IntegerField(default=0)
    prioridad = models.CharField(max_length=20, choices=PRIORIDADES, default="Media")
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def clean(self):
        if self.area and self.secretaria:
            raise ValidationError('Seleccione solo un Área o una Secretaría, no ambos.')

    def __str__(self):
        return self.titulo


class HistorialTarea(models.Model):
    tarea = models.ForeignKey("Tarea", on_delete=models.CASCADE, related_name="historial")
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    comentario = models.TextField(blank=True)
    porcentaje_avance = models.IntegerField()
    porcentaje_anterior = models.IntegerField(null=True, blank=True)
    fecha = models.DateTimeField(auto_now_add=True)
