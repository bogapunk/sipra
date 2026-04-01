"""Utilidades de queryset para listados de proyectos (evita filas duplicadas por JOINs M2M)."""
from django.db.models import Prefetch, Subquery

from .models import Proyecto, ProyectoArea, ProyectoEquipo, ProyectoPresupuestoItem, ProyectoSecretaria


def _ids_subquery(qs):
    """Subconsulta de ids únicos; order_by() vacío evita conflictos con DISTINCT en algunos motores."""
    return Subquery(qs.order_by().values('id').distinct())


def proyecto_dashboard_list_qs(qs_filtrado):
    """
    Reconstruye un queryset de Proyecto con un registro por id.
    Los filtros por proyectoarea / proyectosecretaria duplican filas en el JOIN.
    """
    return (
        Proyecto.objects.filter(id__in=_ids_subquery(qs_filtrado))
        .select_related('creado_por', 'secretaria', 'usuario_responsable', 'area')
        .prefetch_related(
            Prefetch('proyectoarea_set', queryset=ProyectoArea.objects.select_related('area')),
            Prefetch('proyectosecretaria_set', queryset=ProyectoSecretaria.objects.select_related('secretaria')),
            Prefetch('equipo', queryset=ProyectoEquipo.objects.select_related('usuario')),
        )
        .order_by('id')
    )


def proyecto_viewset_list_qs(qs_filtrado):
    """Listado API proyectos (incluye ítems de presupuesto)."""
    return (
        Proyecto.objects.filter(id__in=_ids_subquery(qs_filtrado))
        .select_related('usuario_responsable', 'area', 'secretaria', 'creado_por')
        .prefetch_related(
            Prefetch('equipo', queryset=ProyectoEquipo.objects.select_related('usuario')),
            Prefetch('presupuesto_items', queryset=ProyectoPresupuestoItem.objects.order_by('orden', 'id')),
            'proyectoarea_set__area',
            'proyectosecretaria_set__secretaria',
        )
        .order_by('id')
    )
