"""Servicio centralizado de cálculo de avances.

Unifica en un solo lugar toda la lógica de avance del sistema:
- Avance por tareas (promedio de porcentaje_avance de las tareas).
- Avance por objetivos (promedio ponderado según el estado del objetivo).
- Resúmenes de objetivos por estado (totales y por proyecto/grupo).
- Últimos historiales de avance.

Todos los módulos (serializers, dashboards, reportes) deben consumir desde aquí
para evitar duplicación de lógica e inconsistencias entre paneles y reportes.
"""
from collections import defaultdict

from django.db.models import Avg, Count

from .models import ProyectoObjetivo


# --------------------------------------------------------------------------- #
# Avance por TAREAS
# --------------------------------------------------------------------------- #
def avance_tareas_bulk(proyecto_ids):
    """Promedio de porcentaje_avance de las tareas, agrupado por proyecto.

    Devuelve {proyecto_id: avg_avance}. Evita N+1 con una sola consulta agregada.
    """
    if not proyecto_ids:
        return {}
    from tasks.models import Tarea
    return dict(
        Tarea.objects.filter(proyecto_id__in=proyecto_ids)
        .values('proyecto_id')
        .annotate(avg=Avg('porcentaje_avance'))
        .values_list('proyecto_id', 'avg')
    )


def bulk_avances_historiales(proyecto_ids):
    """Avances (promedio de tareas) y último historial por proyecto.

    Retorna (avances, ultimos_historiales) donde:
    - avances: {proyecto_id: avg_avance}
    - ultimos_historiales: {proyecto_id: HistorialTarea} (el más reciente)

    Usa objetos HistorialTarea con relaciones para el dashboard (área/usuario/fecha).
    """
    if not proyecto_ids:
        return {}, {}
    from tasks.models import HistorialTarea
    avances = avance_tareas_bulk(proyecto_ids)
    historiales = HistorialTarea.objects.filter(
        tarea__proyecto_id__in=proyecto_ids
    ).select_related('tarea__area', 'usuario').order_by('-fecha')
    ultimos = {}
    for h in historiales:
        pid = h.tarea.proyecto_id
        if pid not in ultimos:
            ultimos[pid] = h
    return avances, ultimos


def ultimos_dos_historiales_por_tarea(tarea_ids):
    """Últimos 2 registros de historial por tarea, en formato liviano.

    Devuelve {tarea_id: [(fecha, porcentaje_avance), ...]} con como máximo 2 items
    (el más reciente primero). Usa values_list para no instanciar modelos pesados,
    y corta a 2 por tarea en memoria: solo se conservan los registros realmente usados.
    """
    if not tarea_ids:
        return {}
    from tasks.models import HistorialTarea
    rows = (
        HistorialTarea.objects.filter(tarea_id__in=tarea_ids)
        .order_by('tarea_id', '-fecha')
        .values_list('tarea_id', 'fecha', 'porcentaje_avance')
    )
    resultado = defaultdict(list)
    for tarea_id, fecha, pct in rows:
        if len(resultado[tarea_id]) < 2:
            resultado[tarea_id].append((fecha, pct))
    return resultado


# --------------------------------------------------------------------------- #
# Avance por OBJETIVOS
# --------------------------------------------------------------------------- #
def avance_ponderado_objetivos(en_progreso, finalizado, total):
    """Avance ponderado por estado: En progreso=50%, Finalizado=100%, No iniciado=0%."""
    if not total:
        return 0
    puntos = (
        en_progreso * ProyectoObjetivo.AVANCE_POR_ESTADO[ProyectoObjetivo.ESTADO_EN_PROGRESO]
        + finalizado * ProyectoObjetivo.AVANCE_POR_ESTADO[ProyectoObjetivo.ESTADO_FINALIZADO]
    )
    return round(puntos / total, 2)


def conteo_objetivos_por_estado(items):
    """Cuenta una colección de ProyectoObjetivo por estado.

    Devuelve (no_iniciado, en_progreso, finalizado, total). `items` es iterable de
    instancias ProyectoObjetivo (ya cargadas/prefetcheadas para evitar consultas extra).
    """
    no_iniciado = en_progreso = finalizado = 0
    for it in items:
        estado = it.estado_avance
        if estado == ProyectoObjetivo.ESTADO_NO_INICIADO:
            no_iniciado += 1
        elif estado == ProyectoObjetivo.ESTADO_EN_PROGRESO:
            en_progreso += 1
        elif estado == ProyectoObjetivo.ESTADO_FINALIZADO:
            finalizado += 1
    total = no_iniciado + en_progreso + finalizado
    return no_iniciado, en_progreso, finalizado, total


def resumen_objetivos_proyecto(proyecto):
    """Resumen de objetivos de un proyecto: dict {total, no_iniciado, en_progreso, finalizado, avance}.

    Usa la relación prefetcheada `objetivos_proyecto` si está disponible.
    """
    rel = getattr(proyecto, 'objetivos_proyecto', None)
    if rel is not None:
        items = list(rel.all())
    else:
        items = list(ProyectoObjetivo.objects.filter(proyecto=proyecto))
    no_iniciado, en_progreso, finalizado, total = conteo_objetivos_por_estado(items)
    return {
        'total': total,
        'no_iniciado': no_iniciado,
        'en_progreso': en_progreso,
        'finalizado': finalizado,
        'avance': avance_ponderado_objetivos(en_progreso, finalizado, total),
    }


def avance_objetivos_proyecto(proyecto):
    """Avance ponderado de objetivos de un proyecto, o None si no tiene objetivos."""
    resumen = resumen_objetivos_proyecto(proyecto)
    if not resumen['total']:
        return None
    return resumen['avance']


def objetivos_por_proyecto_map(proyectos_por_grupo):
    """Dado {grupo: set(proyecto_ids)} retorna {proyecto_id: {estado: cantidad}}.

    Una sola consulta agregada para todos los proyectos involucrados.
    """
    todos_ids = set()
    for ids in proyectos_por_grupo.values():
        todos_ids |= ids
    obj_map = defaultdict(lambda: {
        ProyectoObjetivo.ESTADO_NO_INICIADO: 0,
        ProyectoObjetivo.ESTADO_EN_PROGRESO: 0,
        ProyectoObjetivo.ESTADO_FINALIZADO: 0,
    })
    if todos_ids:
        rows = (
            ProyectoObjetivo.objects.filter(proyecto_id__in=todos_ids)
            .values('proyecto_id', 'estado_avance')
            .annotate(cantidad=Count('id'))
        )
        for row in rows:
            estado_obj = row['estado_avance']
            if estado_obj in obj_map[row['proyecto_id']]:
                obj_map[row['proyecto_id']][estado_obj] = row['cantidad']
    return obj_map


def agregar_objetivos_grupo(proyecto_ids, objetivos_map):
    """Suma los objetivos por estado de un conjunto de proyectos y calcula el avance ponderado.

    Devuelve {total, no_iniciado, en_progreso, finalizado, avance}.
    """
    no_iniciado = en_progreso = finalizado = 0
    for pid in proyecto_ids:
        detalle = objetivos_map.get(pid)
        if not detalle:
            continue
        no_iniciado += detalle.get(ProyectoObjetivo.ESTADO_NO_INICIADO, 0)
        en_progreso += detalle.get(ProyectoObjetivo.ESTADO_EN_PROGRESO, 0)
        finalizado += detalle.get(ProyectoObjetivo.ESTADO_FINALIZADO, 0)
    total = no_iniciado + en_progreso + finalizado
    return {
        'total': total,
        'no_iniciado': no_iniciado,
        'en_progreso': en_progreso,
        'finalizado': finalizado,
        'avance': avance_ponderado_objetivos(en_progreso, finalizado, total),
    }
