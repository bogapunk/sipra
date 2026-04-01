"""Conteo de vínculos área/secretaría de un proyecto (transversalidad)."""
from .models import Proyecto, ProyectoArea, ProyectoSecretaria


def ids_areas_proyecto(proyecto: Proyecto) -> set:
    ids = set()
    if proyecto.area_id:
        ids.add(proyecto.area_id)
    ids.update(ProyectoArea.objects.filter(proyecto_id=proyecto.pk).values_list('area_id', flat=True))
    return ids


def ids_secretarias_proyecto(proyecto: Proyecto) -> set:
    ids = set()
    if proyecto.secretaria_id:
        ids.add(proyecto.secretaria_id)
    ids.update(ProyectoSecretaria.objects.filter(proyecto_id=proyecto.pk).values_list('secretaria_id', flat=True))
    return ids


def proyecto_tiene_multiples_dependencias(proyecto: Proyecto) -> bool:
    """True si hay más de un área o más de una secretaría vinculada (proyecto transversal)."""
    return len(ids_areas_proyecto(proyecto)) > 1 or len(ids_secretarias_proyecto(proyecto)) > 1


def actualizar_bandera_transversal(proyecto: Proyecto) -> None:
    """Persiste `es_transversal` según dependencias (llamar tras crear/editar vínculos área/secretaría)."""
    flag = proyecto_tiene_multiples_dependencias(proyecto)
    if proyecto.es_transversal != flag:
        proyecto.es_transversal = flag
        proyecto.save(update_fields=['es_transversal'])
