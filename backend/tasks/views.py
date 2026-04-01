from datetime import timedelta
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q, Prefetch, Max, Count, Avg
from .models import Tarea, HistorialTarea, ComentarioTarea, AdjuntoTarea
from projects.models import AdjuntoAuditLog
from config.pagination import TaskListPagination
from .serializers import (
    TareaListSerializer,
    TareaSerializer,
    HistorialTareaSerializer,
    ComentarioTareaSerializer,
    AdjuntoTareaSerializer,
)
from users.access import (
    ROL_ADMIN,
    ROL_CARGA,
    ROL_VISUALIZACION,
    ensure_read_only_for_roles,
    ensure_task_assignment_allowed,
    filter_projects_for_user,
    filter_tasks_for_user,
)

MINUTOS_EDICION_USUARIO = 15


class TareaViewSet(viewsets.ModelViewSet):
    queryset = Tarea.objects.select_related(
        'area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre'
    )
    serializer_class = TareaSerializer
    pagination_class = TaskListPagination

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        ensure_read_only_for_roles(
            request.user,
            request,
            read_roles=(ROL_VISUALIZACION, ROL_CARGA),
            write_roles=(ROL_ADMIN, ROL_CARGA),
            message='No tiene permisos para gestionar tareas.',
        )

    def perform_create(self, serializer):
        data = serializer.validated_data
        proyecto = data.get('proyecto')
        tarea_padre = data.get('tarea_padre')
        proyecto_base = proyecto or getattr(tarea_padre, 'proyecto', None)
        ensure_task_assignment_allowed(
            self.request.user,
            area_id=getattr(data.get('area'), 'id', None),
            secretaria_id=getattr(data.get('secretaria'), 'id', None),
            responsable_id=getattr(data.get('responsable'), 'id', None),
            proyecto=proyecto_base,
        )
        instance = serializer.save()
        if instance.tarea_padre_id and not instance.proyecto_id and instance.tarea_padre.proyecto_id:
            instance.proyecto = instance.tarea_padre.proyecto
            instance.etapa = instance.tarea_padre.etapa
            instance.save(update_fields=['proyecto', 'etapa'])
        if not instance.orden:
            siblings = Tarea.objects.filter(
                proyecto_id=instance.proyecto_id,
                tarea_padre_id=instance.tarea_padre_id,
            ).exclude(id=instance.id)
            max_orden = siblings.aggregate(max_orden=Max('orden')).get('max_orden') or 0
            instance.orden = max_orden + 1
            instance.save(update_fields=['orden'])

    def perform_update(self, serializer):
        data = serializer.validated_data
        proyecto = data.get('proyecto', serializer.instance.proyecto)
        tarea_padre = data.get('tarea_padre', serializer.instance.tarea_padre)
        proyecto_base = proyecto or getattr(tarea_padre, 'proyecto', None)
        ensure_task_assignment_allowed(
            self.request.user,
            area_id=getattr(data.get('area', serializer.instance.area), 'id', None),
            secretaria_id=getattr(data.get('secretaria', serializer.instance.secretaria), 'id', None),
            responsable_id=getattr(data.get('responsable', serializer.instance.responsable), 'id', None),
            proyecto=proyecto_base,
        )
        instance = serializer.save()
        if instance.tarea_padre_id and not instance.proyecto_id and instance.tarea_padre.proyecto_id:
            instance.proyecto = instance.tarea_padre.proyecto
            instance.etapa = instance.tarea_padre.etapa
            instance.save(update_fields=['proyecto', 'etapa'])
        if instance.proyecto_id and instance.porcentaje_avance == 100 and instance.estado == 'Finalizada':
            from projects.models import Proyecto
            tareas_proy = Tarea.objects.filter(proyecto_id=instance.proyecto_id)
            if tareas_proy.exists() and all(t.porcentaje_avance == 100 for t in tareas_proy):
                Proyecto.objects.filter(id=instance.proyecto_id).update(estado='Finalizado')

    def get_serializer_class(self):
        if getattr(self, 'action', None) == 'list':
            return TareaListSerializer
        return TareaSerializer

    def get_queryset(self):
        qs = Tarea.objects.select_related(
            'area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre'
        )
        proyecto = self.request.query_params.get("proyecto")
        area = self.request.query_params.get("area")
        estado = self.request.query_params.get("estado")
        responsable = self.request.query_params.get("responsable")
        usuario = self.request.query_params.get("usuario")
        secretaria = self.request.query_params.get("secretaria")
        search = (self.request.query_params.get("search") or self.request.query_params.get("q") or "").strip()
        vencimiento = self.request.query_params.get("vencimiento")
        solo_raices = self.request.query_params.get("solo_raices") == "1"
        orden = (self.request.query_params.get("orden") or "").strip().lower()
        if usuario:
            from users.models import Usuario
            from projects.models import Proyecto, ProyectoArea, ProyectoEquipo, ProyectoSecretaria
            u = Usuario.objects.filter(id=usuario).first()
            if u:
                condiciones = Q(responsable_id=u.id)
                if u.area_id:
                    condiciones |= Q(area_id=u.area_id)
                if u.secretaria_id:
                    condiciones |= Q(secretaria_id=u.secretaria_id)
                proy_ids_responsable = Proyecto.objects.filter(usuario_responsable_id=u.id).values_list('id', flat=True)
                proy_ids_creador = Proyecto.objects.filter(creado_por_id=u.id).values_list('id', flat=True)
                proy_ids_equipo = ProyectoEquipo.objects.filter(usuario_id=u.id).values_list('proyecto_id', flat=True)
                proy_ids = set(proy_ids_responsable) | set(proy_ids_creador) | set(proy_ids_equipo)
                if u.area_id:
                    proy_ids |= set(
                        ProyectoArea.objects.filter(area_id=u.area_id).values_list('proyecto_id', flat=True)
                    )
                if u.secretaria_id:
                    proy_ids |= set(
                        ProyectoSecretaria.objects.filter(secretaria_id=u.secretaria_id).values_list(
                            'proyecto_id', flat=True
                        )
                    )
                if proy_ids:
                    condiciones |= Q(proyecto_id__in=proy_ids)
                qs = qs.filter(condiciones)
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        if area and not usuario:
            qs = qs.filter(area_id=area)
        if secretaria and not usuario:
            qs = qs.filter(secretaria_id=secretaria)
        if estado:
            qs = qs.filter(estado=estado)
        if responsable and not usuario:
            qs = qs.filter(responsable_id=responsable)
        qs = filter_tasks_for_user(qs, self.request.user)
        if search:
            from .search import aplicar_busqueda_tareas
            qs = aplicar_busqueda_tareas(qs, search)
        if vencimiento:
            hoy = timezone.now().date()
            limite = hoy + timedelta(days=7)
            if vencimiento == 'vencidas':
                qs = qs.exclude(estado='Finalizada').filter(fecha_vencimiento__lt=hoy)
            elif vencimiento == 'proximas':
                qs = qs.exclude(estado='Finalizada').filter(
                    fecha_vencimiento__gte=hoy,
                    fecha_vencimiento__lte=limite,
                )
            elif vencimiento == 'en-plazo':
                qs = qs.exclude(estado='Finalizada').filter(fecha_vencimiento__gt=limite)
        qs = qs.select_related('area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre')
        if getattr(self, 'action', None) == 'retrieve':
            return qs.prefetch_related(
                Prefetch(
                    'subtareas',
                    queryset=Tarea.objects.select_related(
                        'area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre'
                    ).order_by('orden', 'id'),
                    to_attr='subtareas_prefetch',
                )
            ).order_by('tarea_padre_id', 'orden', 'id')
        if solo_raices:
            qs = qs.filter(tarea_padre__isnull=True)
        if orden == 'recientes':
            return qs.order_by('-fecha_creacion', '-id')
        return qs.order_by('tarea_padre_id', 'orden', 'id')

    @action(detail=False, methods=['get'], url_path='resumen')
    def resumen(self, request):
        """
        Resumen global de tareas para tarjetas KPI del panel.
        Se calcula sobre TODO el universo accesible por el usuario (sin paginar).
        """
        qs = filter_tasks_for_user(Tarea.objects.all(), request.user)
        data = qs.aggregate(
            total=Count('id'),
            pendientes=Count('id', filter=Q(estado='Pendiente')),
            en_proceso=Count('id', filter=Q(estado='En proceso')),
            bloqueadas=Count('id', filter=Q(estado='Bloqueada')),
            avance_promedio=Avg('porcentaje_avance'),
        )
        return Response({
            'total': int(data.get('total') or 0),
            'pendientes': int(data.get('pendientes') or 0),
            'en_proceso': int(data.get('en_proceso') or 0),
            'bloqueadas': int(data.get('bloqueadas') or 0),
            'avance_promedio': round(float(data.get('avance_promedio') or 0), 2),
        })


class HistorialTareaViewSet(viewsets.ModelViewSet):
    queryset = HistorialTarea.objects.select_related('tarea', 'usuario').order_by('-fecha')
    serializer_class = HistorialTareaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        ensure_read_only_for_roles(
            request.user,
            request,
            read_roles=(ROL_VISUALIZACION, ROL_CARGA),
            write_roles=(ROL_ADMIN, ROL_CARGA),
            message='No tiene permisos para gestionar el historial de tareas.',
        )

    def get_queryset(self):
        qs = HistorialTarea.objects.select_related('tarea', 'usuario').order_by('-fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs.filter(tarea_id__in=filter_tasks_for_user(Tarea.objects.all(), self.request.user).values('id'))

    def perform_create(self, serializer):
        tarea = serializer.validated_data.get('tarea')
        if not filter_tasks_for_user(Tarea.objects.filter(id=tarea.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso a la tarea donde intenta registrar un avance.')
        serializer.save(usuario=self.request.user)


class ComentarioTareaViewSet(viewsets.ModelViewSet):
    queryset = ComentarioTarea.objects.select_related('tarea', 'usuario', 'editado_por').order_by('fecha')
    serializer_class = ComentarioTareaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        ensure_read_only_for_roles(
            request.user,
            request,
            read_roles=(ROL_VISUALIZACION, ROL_CARGA),
            write_roles=(ROL_ADMIN, ROL_CARGA, ROL_VISUALIZACION),
            message='No tiene permisos para gestionar comentarios de tareas.',
        )

    def get_queryset(self):
        qs = ComentarioTarea.objects.select_related('tarea', 'usuario', 'editado_por').order_by('fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs.filter(tarea_id__in=filter_tasks_for_user(Tarea.objects.all(), self.request.user).values('id'))

    def _es_admin(self, user):
        return getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'

    def _puede_editar_eliminar(self, comentario):
        user = self.request.user
        if self._es_admin(user):
            return True
        if comentario.usuario_id != user.id:
            return False
        limite = comentario.fecha + timedelta(minutes=MINUTOS_EDICION_USUARIO)
        return timezone.now() <= limite

    def perform_create(self, serializer):
        tarea = serializer.validated_data.get('tarea')
        if not filter_tasks_for_user(Tarea.objects.filter(id=tarea.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso a la tarea donde intenta comentar.')
        serializer.save(usuario=self.request.user)

    def perform_update(self, serializer):
        instance = serializer.instance
        if not self._puede_editar_eliminar(instance):
            raise PermissionDenied(
                "No puede editar este comentario. Solo puede editar los propios dentro de "
                f"{MINUTOS_EDICION_USUARIO} minutos, o ser Administrador."
            )
        texto_anterior = instance.texto
        serializer.save()
        if self._es_admin(self.request.user):
            from projects.models import ComentarioAuditLog
            ComentarioAuditLog.objects.create(
                tipo='tarea',
                comentario_id=instance.id,
                accion='editar',
                usuario=self.request.user,
                texto_anterior=texto_anterior,
                texto_nuevo=instance.texto,
                tarea_id=instance.tarea_id,
                proyecto_id=instance.tarea.proyecto_id if instance.tarea else None,
            )
            instance.fecha_edicion = timezone.now()
            instance.editado_por = self.request.user
            instance.save(update_fields=['fecha_edicion', 'editado_por'])
        else:
            instance.fecha_edicion = timezone.now()
            instance.editado_por = self.request.user
            instance.save(update_fields=['fecha_edicion', 'editado_por'])

    def perform_destroy(self, instance):
        if not self._puede_editar_eliminar(instance):
            raise PermissionDenied(
                "No puede eliminar este comentario. Solo puede eliminar los propios dentro de "
                f"{MINUTOS_EDICION_USUARIO} minutos, o ser Administrador."
            )
        if self._es_admin(self.request.user):
            from projects.models import ComentarioAuditLog
            ComentarioAuditLog.objects.create(
                tipo='tarea',
                comentario_id=instance.id,
                accion='eliminar',
                usuario=self.request.user,
                texto_anterior=instance.texto,
                tarea_id=instance.tarea_id,
                proyecto_id=instance.tarea.proyecto_id if instance.tarea else None,
            )
        instance.delete()


class AdjuntoTareaViewSet(viewsets.ModelViewSet):
    queryset = AdjuntoTarea.objects.select_related('tarea', 'subido_por').order_by('-fecha')
    serializer_class = AdjuntoTareaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        ensure_read_only_for_roles(
            request.user,
            request,
            read_roles=(ROL_VISUALIZACION, ROL_CARGA),
            write_roles=(ROL_ADMIN, ROL_CARGA, ROL_VISUALIZACION),
            message='No tiene permisos para gestionar adjuntos de tareas.',
        )

    def get_queryset(self):
        qs = AdjuntoTarea.objects.select_related('tarea', 'subido_por').order_by('-fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs.filter(tarea_id__in=filter_tasks_for_user(Tarea.objects.all(), self.request.user).values('id'))

    def _es_admin(self, user):
        return getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'

    def _puede_modificar(self, adjunto):
        user = self.request.user
        return self._es_admin(user) or adjunto.subido_por_id == user.id

    def perform_create(self, serializer):
        tarea = serializer.validated_data.get('tarea')
        if not filter_tasks_for_user(Tarea.objects.filter(id=tarea.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso a la tarea donde intenta subir un adjunto.')
        serializer.save(subido_por=self.request.user)

    def perform_update(self, serializer):
        instance = serializer.instance
        if not self._puede_modificar(instance):
            raise PermissionDenied("Solo puede editar sus propios adjuntos o ser Administrador.")
        nombre_anterior = instance.nombre_original
        serializer.save()
        AdjuntoAuditLog.objects.create(
            tipo='tarea',
            adjunto_id=instance.id,
            accion='editar',
            usuario=self.request.user,
            nombre_archivo=instance.nombre_original,
            nombre_anterior=nombre_anterior,
            nombre_nuevo=instance.nombre_original,
            tarea_id=instance.tarea_id,
            proyecto_id=instance.tarea.proyecto_id if instance.tarea else None,
        )

    def perform_destroy(self, instance):
        if not self._puede_modificar(instance):
            raise PermissionDenied("Solo puede eliminar sus propios adjuntos o ser Administrador.")
        AdjuntoAuditLog.objects.create(
            tipo='tarea',
            adjunto_id=instance.id,
            accion='eliminar',
            usuario=self.request.user,
            nombre_archivo=instance.nombre_original,
            tarea_id=instance.tarea_id,
            proyecto_id=instance.tarea.proyecto_id if instance.tarea else None,
        )
        instance.delete()
