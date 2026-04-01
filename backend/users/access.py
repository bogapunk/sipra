from __future__ import annotations

from django.db.models import Q
from rest_framework.exceptions import PermissionDenied

from .models import Usuario

ROL_ADMIN = 'Administrador'
ROL_CARGA = 'Carga'
ROL_VISUALIZACION = 'Visualización'


def is_valid_user(user) -> bool:
    return isinstance(user, Usuario) and getattr(user, 'is_authenticated', False)


def get_role_name(user) -> str:
    if not is_valid_user(user):
        return ''
    return (getattr(getattr(user, 'rol', None), 'nombre', '') or '').strip()


def is_admin(user) -> bool:
    return get_role_name(user) == ROL_ADMIN


def is_carga(user) -> bool:
    return get_role_name(user) == ROL_CARGA


def is_visualizador(user) -> bool:
    return get_role_name(user) == ROL_VISUALIZACION


def require_roles(user, *allowed_roles: str, message: str = 'No tiene permisos para realizar esta acción.'):
    if is_admin(user) and ROL_ADMIN not in allowed_roles:
        return
    if get_role_name(user) not in allowed_roles:
        raise PermissionDenied(message)


def ensure_read_only_for_roles(user, request, *, read_roles: tuple[str, ...], write_roles: tuple[str, ...], message: str):
    role = get_role_name(user)
    if request.method in ('GET', 'HEAD', 'OPTIONS'):
        if role in read_roles or role in write_roles or is_admin(user):
            return
    elif role in write_roles or is_admin(user):
        return
    raise PermissionDenied(message)


def project_access_q(user, *, prefix: str = ''):
    """
    Acceso a listado/detalle de proyecto (rol Carga).
    - Proyecto individual (no transversal): responsable/creador/equipo o área/secretaría vía proyecto.
    - Proyecto transversal: solo coordinación (responsable, creador, equipo); no alcanza con estar
      vinculado solo por ProyectoArea/ProyectoSecretaria (las tareas se filtran aparte).
    """
    if not is_carga(user):
        return Q(pk__in=[])

    base = f'{prefix}__' if prefix else ''
    q_coord = Q(**{f'{base}usuario_responsable_id': user.id}) | Q(**{f'{base}creado_por_id': user.id}) | Q(
        **{f'{base}equipo__usuario_id': user.id}
    )
    q_area_sec = Q()
    if user.area_id:
        q_area_sec |= Q(**{f'{base}area_id': user.area_id}) | Q(**{f'{base}proyectoarea__area_id': user.area_id})
    if user.secretaria_id:
        q_area_sec |= Q(**{f'{base}secretaria_id': user.secretaria_id}) | Q(
            **{f'{base}proyectosecretaria_set__secretaria_id': user.secretaria_id}
        )
    q_individual = q_coord | q_area_sec
    return (
        Q(**{f'{base}es_transversal': True}) & q_coord
        | Q(**{f'{base}es_transversal': False}) & q_individual
    )


def _visualizador_project_scope_q(user):
    """Si el visualizador tiene área o secretaría, limita proyectos a esa dependencia."""
    if user.area_id:
        return Q(area_id=user.area_id) | Q(proyectoarea__area_id=user.area_id)
    if user.secretaria_id:
        return Q(secretaria_id=user.secretaria_id) | Q(proyectosecretaria_set__secretaria_id=user.secretaria_id)
    return None


def _visualizador_task_scope_q(user):
    """Si el visualizador tiene área o secretaría, limita tareas a esa dependencia."""
    if user.area_id:
        return (
            Q(area_id=user.area_id)
            | Q(proyecto__area_id=user.area_id)
            | Q(proyecto__proyectoarea__area_id=user.area_id)
        )
    if user.secretaria_id:
        return (
            Q(secretaria_id=user.secretaria_id)
            | Q(proyecto__secretaria_id=user.secretaria_id)
            | Q(proyecto__proyectosecretaria_set__secretaria_id=user.secretaria_id)
        )
    return None


def dedupe_queryset_by_pk(qs):
    """
    Equivale a .distinct() por filas sin SELECT DISTINCT sobre todas las columnas.
    SQL Server rechaza DISTINCT si hay tipos TEXT legacy en el SELECT (p. ej. con select_related).
    Los llamadores que necesiten select_related/prefetch deben volver a encadenarlos.
    """
    model = qs.model
    pk = model._meta.pk.name
    ids = qs.values_list(pk, flat=True).order_by().distinct()
    return model.objects.filter(**{f'{pk}__in': ids})


def filter_projects_for_user(qs, user):
    if is_admin(user):
        return qs
    if is_visualizador(user):
        scope = _visualizador_project_scope_q(user)
        if scope is None:
            return qs
        return dedupe_queryset_by_pk(qs.filter(scope))
    if not is_carga(user):
        return qs.none()
    # Proyecto por equipo/área/secretaría/responsable, y también si tiene al menos una tarea
    # visible con las mismas reglas que filter_tasks_for_user (p. ej. transversal con tarea
    # asignada a la secretaría del usuario aunque el vínculo a nivel proyecto no coincida).
    from tasks.models import Tarea

    via_proyecto = project_access_q(user)
    via_tareas = Tarea.objects.filter(proyecto_id__isnull=False).filter(task_access_q(user)).values('proyecto_id')
    return dedupe_queryset_by_pk(qs.filter(via_proyecto | Q(pk__in=via_tareas)))


def task_access_q(user, *, prefix: str = ''):
    """
    Tareas visibles para Carga.
    - Sin proyecto (tareas particulares): responsable o área/secretaría en la tarea.
    - Proyecto transversal: responsable/creador/equipo del proyecto ven todas las tareas; el resto
      solo ve tareas donde coincide su área o secretaría en la tarea (o es responsable de la tarea).
    - Proyecto individual: se mantiene la lógica amplia (tarea o proyecto por área/secretaría/vínculos).
    """
    if not is_carga(user):
        return Q(pk__in=[])

    base = f'{prefix}__' if prefix else ''
    p = f'{base}proyecto__' if prefix else 'proyecto__'

    solo_tarea = Q(**{f'{base}responsable_id': user.id})
    if user.area_id:
        solo_tarea |= Q(**{f'{base}area_id': user.area_id})
    if user.secretaria_id:
        solo_tarea |= Q(**{f'{base}secretaria_id': user.secretaria_id})

    coord_q = (
        Q(**{f'{p}usuario_responsable_id': user.id})
        | Q(**{f'{p}creado_por_id': user.id})
        | Q(**{f'{p}equipo__usuario_id': user.id})
    )
    strict_transversal = solo_tarea | coord_q

    broad = Q(**{f'{base}responsable_id': user.id})
    if user.area_id:
        broad |= (
            Q(**{f'{base}area_id': user.area_id})
            | Q(**{f'{p}area_id': user.area_id})
            | Q(**{f'{p}proyectoarea__area_id': user.area_id})
        )
    if user.secretaria_id:
        broad |= (
            Q(**{f'{base}secretaria_id': user.secretaria_id})
            | Q(**{f'{p}secretaria_id': user.secretaria_id})
            | Q(**{f'{p}proyectosecretaria_set__secretaria_id': user.secretaria_id})
        )
    broad |= coord_q

    et = f'{p}es_transversal'
    return (
        Q(**{f'{base}proyecto__isnull': True}) & solo_tarea
        | Q(**{et: True}) & strict_transversal
        | Q(**{f'{base}proyecto__isnull': False}) & Q(**{et: False}) & broad
    )


def filter_tasks_for_user(qs, user):
    if is_admin(user):
        return qs
    if is_visualizador(user):
        scope = _visualizador_task_scope_q(user)
        if scope is None:
            return qs
        return dedupe_queryset_by_pk(qs.filter(scope))
    if not is_carga(user):
        return qs.none()
    return dedupe_queryset_by_pk(qs.filter(task_access_q(user)))


def ensure_project_assignment_allowed(
    user,
    *,
    area_ids=None,
    secretaria_ids=None,
    usuario_responsable_id=None,
):
    """area_ids y secretaria_ids son listas de ids efectivos (vacías = sin dependencia en ese eje)."""
    if is_admin(user):
        return
    if not is_carga(user):
        raise PermissionDenied('Solo Administrador o Carga pueden crear o editar proyectos.')

    eff_area_ids = list(area_ids) if area_ids is not None else []
    eff_sec_ids = list(secretaria_ids) if secretaria_ids is not None else []

    if eff_area_ids and eff_sec_ids:
        raise PermissionDenied('No puede combinar áreas y secretarías en el mismo proyecto.')

    if user.area_id and eff_area_ids:
        for aid in eff_area_ids:
            if int(aid) != int(user.area_id):
                raise PermissionDenied('Solo puede asignar proyectos a su propia área.')
    if user.secretaria_id and eff_sec_ids:
        for sid in eff_sec_ids:
            if int(sid) != int(user.secretaria_id):
                raise PermissionDenied('Solo puede asignar proyectos a su propia secretaría.')

    if usuario_responsable_id and int(usuario_responsable_id) != int(user.id):
        raise PermissionDenied('Solo puede asignarse a sí mismo como responsable del proyecto.')


def ensure_task_assignment_allowed(user, *, area_id=None, secretaria_id=None, responsable_id=None, proyecto=None):
    if is_admin(user):
        return
    if not is_carga(user):
        raise PermissionDenied('Solo Administrador o Carga pueden crear o editar tareas.')

    if user.area_id and area_id and int(area_id) != int(user.area_id):
        raise PermissionDenied('Solo puede asignar tareas a su propia área.')
    if user.secretaria_id and secretaria_id and int(secretaria_id) != int(user.secretaria_id):
        raise PermissionDenied('Solo puede asignar tareas a su propia secretaría.')
    if proyecto is not None:
        proyecto_id = getattr(proyecto, 'id', None)
        if proyecto_id is not None and not filter_projects_for_user(proyecto.__class__.objects.filter(id=proyecto_id), user).exists():
            raise PermissionDenied('No tiene acceso al proyecto asociado a esta tarea.')
    if responsable_id and int(responsable_id) != int(user.id):
        raise PermissionDenied('Solo puede asignarse a sí mismo como responsable de la tarea.')
