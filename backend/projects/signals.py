"""Mantiene `Proyecto.es_transversal` al editar vínculos desde admin u otras rutas fuera del serializer."""
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .dependencias import actualizar_bandera_transversal
from .models import ProyectoArea, ProyectoSecretaria


@receiver(post_save, sender=ProyectoArea)
@receiver(post_delete, sender=ProyectoArea)
def _sync_transversal_tras_proyecto_area(sender, instance, **kwargs):
    actualizar_bandera_transversal(instance.proyecto)


@receiver(post_save, sender=ProyectoSecretaria)
@receiver(post_delete, sender=ProyectoSecretaria)
def _sync_transversal_tras_proyecto_secretaria(sender, instance, **kwargs):
    actualizar_bandera_transversal(instance.proyecto)
