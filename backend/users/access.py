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
    if is_admin(user) or is_visualizador(user):
        return Q()
    if not is_carga(user):
        return Q(pk__in=[])

    base = f'{prefix}__' if prefix else ''
    q = Q(**{f'{base}usuario_responsable_id': user.id}) | Q(**{f'{base}creado_por_id': user.id}) | Q(
        **{f'{base}equipo__usuario_id': user.id}
    )
    if user.area_id:
        q |= Q(**{f'{base}area_id': user.area_id}) | Q(**{f'{base}proyectoarea__area_id': user.area_id})
    if user.secretaria_id:
        q |= Q(**{f'{base}secretaria_id': user.secretaria_id})
    return q


def filter_projects_for_user(qs, user):
    if is_admin(user) or is_visualizador(user):
        return qs
    if not is_carga(user):
        return qs.none()
    return qs.filter(project_access_q(user)).distinct()


def task_access_q(user, *, prefix: str = ''):
    if is_admin(user) or is_visualizador(user):
        return Q()
    if not is_carga(user):
        return Q(pk__in=[])

    base = f'{prefix}__' if prefix else ''
    q = Q(**{f'{base}responsable_id': user.id})
    if user.area_id:
        q |= Q(**{f'{base}area_id': user.area_id}) | Q(**{f'{base}proyecto__area_id': user.area_id}) | Q(
            **{f'{base}proyecto__proyectoarea__area_id': user.area_id}
        )
    if user.secretaria_id:
        q |= Q(**{f'{base}secretaria_id': user.secretaria_id}) | Q(**{f'{base}proyecto__secretaria_id': user.secretaria_id})
    q |= Q(**{f'{base}proyecto__usuario_responsable_id': user.id}) | Q(**{f'{base}proyecto__creado_por_id': user.id}) | Q(
        **{f'{base}proyecto__equipo__usuario_id': user.id}
    )
    return q


def filter_tasks_for_user(qs, user):
    if is_admin(user) or is_visualizador(user):
        return qs
    if not is_carga(user):
        return qs.none()
    return qs.filter(task_access_q(user)).distinct()


def ensure_project_assignment_allowed(user, *, area_id=None, secretaria_id=None, usuario_responsable_id=None):
    if is_admin(user):
        return
    if not is_carga(user):
        raise PermissionDenied('Solo Administrador o Carga pueden crear o editar proyectos.')

    if user.area_id and area_id and int(area_id) != int(user.area_id):
        raise PermissionDenied('Solo puede asignar proyectos a su propia área.')
    if user.secretaria_id and secretaria_id and int(secretaria_id) != int(user.secretaria_id):
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
