from datetime import timedelta
from django.db.models import Prefetch
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied
from .models import (
    Eje, Plan, Programa, ObjetivoEstrategico, Indicador,
    Proyecto, ProyectoArea, ProyectoEquipo, ProyectoPresupuestoItem, Etapa, ComentarioProyecto, AdjuntoProyecto,
    ComentarioAuditLog, AdjuntoAuditLog,
)
from .serializers import (
    EjeSerializer, PlanSerializer, ProgramaSerializer,
    ObjetivoEstrategicoSerializer, IndicadorSerializer,
    ProyectoSerializer, ProyectoAreaSerializer, ProyectoEquipoSerializer,
    EtapaSerializer, ComentarioProyectoSerializer, AdjuntoProyectoSerializer,
    ComentarioAuditLogSerializer, AdjuntoAuditLogSerializer,
)
from users.access import (
    ROL_ADMIN,
    ROL_CARGA,
    ROL_VISUALIZACION,
    ensure_project_assignment_allowed,
    ensure_read_only_for_roles,
    filter_projects_for_user,
    require_roles,
)


def _ensure_catalog_access(request):
    ensure_read_only_for_roles(
        request.user,
        request,
        read_roles=(ROL_VISUALIZACION,),
        write_roles=(ROL_ADMIN,),
        message='Solo el Administrador puede modificar catálogos de planificación.',
    )


def _ensure_project_access(request):
    ensure_read_only_for_roles(
        request.user,
        request,
        read_roles=(ROL_VISUALIZACION, ROL_CARGA),
        write_roles=(ROL_ADMIN, ROL_CARGA),
        message='No tiene permisos para gestionar proyectos.',
    )


def _ensure_project_collaboration_access(request):
    ensure_read_only_for_roles(
        request.user,
        request,
        read_roles=(ROL_VISUALIZACION, ROL_CARGA),
        write_roles=(ROL_ADMIN, ROL_CARGA, ROL_VISUALIZACION),
        message='No tiene permisos para gestionar comentarios o adjuntos del proyecto.',
    )


class EjeViewSet(viewsets.ModelViewSet):
    queryset = Eje.objects.all()
    serializer_class = EjeSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_catalog_access(request)


class PlanViewSet(viewsets.ModelViewSet):
    queryset = Plan.objects.select_related('eje').all()
    serializer_class = PlanSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_catalog_access(request)

    def get_queryset(self):
        qs = Plan.objects.select_related('eje').all()
        eje = self.request.query_params.get('eje')
        if eje:
            qs = qs.filter(eje_id=eje)
        return qs


class ProgramaViewSet(viewsets.ModelViewSet):
    queryset = Programa.objects.select_related('plan').all()
    serializer_class = ProgramaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_catalog_access(request)

    def get_queryset(self):
        qs = Programa.objects.select_related('plan').all()
        plan = self.request.query_params.get('plan')
        if plan:
            qs = qs.filter(plan_id=plan)
        return qs


class ObjetivoEstrategicoViewSet(viewsets.ModelViewSet):
    queryset = ObjetivoEstrategico.objects.select_related('programa').all()
    serializer_class = ObjetivoEstrategicoSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_catalog_access(request)

    def get_queryset(self):
        qs = ObjetivoEstrategico.objects.select_related('programa').all()
        programa = self.request.query_params.get('programa')
        if programa:
            qs = qs.filter(programa_id=programa)
        return qs


class IndicadorViewSet(viewsets.ModelViewSet):
    queryset = Indicador.objects.select_related('proyecto').all()
    serializer_class = IndicadorSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_catalog_access(request)

    def get_queryset(self):
        qs = Indicador.objects.select_related('proyecto').all()
        proyecto = self.request.query_params.get('proyecto')
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs


class ProyectoViewSet(viewsets.ModelViewSet):
    queryset = Proyecto.objects.select_related(
        'usuario_responsable', 'area', 'secretaria', 'creado_por'
    ).prefetch_related(
        Prefetch('equipo', queryset=ProyectoEquipo.objects.select_related('usuario')),
        Prefetch('presupuesto_items', queryset=ProyectoPresupuestoItem.objects.order_by('orden', 'id')),
    ).order_by('id')
    serializer_class = ProyectoSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_project_access(request)

    def get_object(self):
        """Usa queryset sin filtros de listado para retrieve/update/destroy (evita 'No Proyecto matches')."""
        from rest_framework.generics import get_object_or_404
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field
        lookup_value = self.kwargs[lookup_url_kwarg]
        filter_kwargs = {self.lookup_field: lookup_value}
        return get_object_or_404(self.get_queryset(), **filter_kwargs)

    def perform_destroy(self, instance):
        """Elimina en orden para evitar IntegrityError con Tarea->Etapa->Proyecto."""
        from django.db import transaction
        from tasks.models import HistorialTarea
        with transaction.atomic():
            # 1. Historial de tareas, luego tareas (Tarea referencia Etapa con SET_NULL)
            tarea_ids = list(instance.tareas.values_list('id', flat=True))
            HistorialTarea.objects.filter(tarea_id__in=tarea_ids).delete()
            instance.tareas.all().delete()
            # 2. Etapas, Indicadores, Comentarios, ProyectoArea, ProyectoEquipo
            instance.etapas.all().delete()
            instance.indicadores.all().delete()
            instance.comentarios.all().delete()
            instance.adjuntos.all().delete()
            instance.proyectoarea_set.all().delete()
            instance.equipo.all().delete()
            # 3. Proyecto
            instance.delete()

    def get_queryset(self):
        qs = Proyecto.objects.select_related(
            'usuario_responsable', 'area', 'secretaria', 'creado_por'
        ).prefetch_related(
            Prefetch('equipo', queryset=ProyectoEquipo.objects.select_related('usuario')),
            Prefetch('presupuesto_items', queryset=ProyectoPresupuestoItem.objects.order_by('orden', 'id')),
            'proyectoarea_set__area',
        ).order_by('id')
        secretaria_id = self.request.query_params.get('secretaria')
        area_id = self.request.query_params.get('area')
        if secretaria_id:
            qs = qs.filter(secretaria_id=secretaria_id)
        if area_id:
            qs = qs.filter(area_id=area_id)
        return filter_projects_for_user(qs, self.request.user)

    def perform_create(self, serializer):
        data = serializer.validated_data
        ensure_project_assignment_allowed(
            self.request.user,
            area_id=getattr(data.get('area'), 'id', None),
            secretaria_id=getattr(data.get('secretaria'), 'id', None),
            usuario_responsable_id=getattr(data.get('usuario_responsable'), 'id', None),
        )
        serializer.save(creado_por=self.request.user)

    def perform_update(self, serializer):
        data = serializer.validated_data
        ensure_project_assignment_allowed(
            self.request.user,
            area_id=getattr(data.get('area', serializer.instance.area), 'id', None),
            secretaria_id=getattr(data.get('secretaria', serializer.instance.secretaria), 'id', None),
            usuario_responsable_id=getattr(
                data.get('usuario_responsable', serializer.instance.usuario_responsable), 'id', None
            ),
        )
        serializer.save(creado_por=serializer.instance.creado_por)


class ProyectoEquipoViewSet(viewsets.ModelViewSet):
    queryset = ProyectoEquipo.objects.select_related('proyecto', 'usuario')
    serializer_class = ProyectoEquipoSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_project_access(request)

    def get_queryset(self):
        qs = ProyectoEquipo.objects.select_related('proyecto', 'usuario')
        proyecto = self.request.query_params.get('proyecto')
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs.filter(proyecto_id__in=filter_projects_for_user(Proyecto.objects.all(), self.request.user).values('id'))

    def perform_create(self, serializer):
        proyecto = serializer.validated_data.get('proyecto')
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta asignar equipo.')
        serializer.save()

    def perform_update(self, serializer):
        proyecto = serializer.validated_data.get('proyecto', serializer.instance.proyecto)
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta asignar equipo.')
        serializer.save()


class ProyectoAreaViewSet(viewsets.ModelViewSet):
    queryset = ProyectoArea.objects.select_related('proyecto', 'area')
    serializer_class = ProyectoAreaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_project_access(request)

    def get_queryset(self):
        qs = ProyectoArea.objects.select_related('proyecto', 'area')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs.filter(proyecto_id__in=filter_projects_for_user(Proyecto.objects.all(), self.request.user).values('id'))

    def perform_create(self, serializer):
        proyecto = serializer.validated_data.get('proyecto')
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta asignar un área.')
        serializer.save()

    def perform_update(self, serializer):
        proyecto = serializer.validated_data.get('proyecto', serializer.instance.proyecto)
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta asignar un área.')
        serializer.save()


class EtapaViewSet(viewsets.ModelViewSet):
    queryset = Etapa.objects.select_related('proyecto')
    serializer_class = EtapaSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_project_access(request)

    def get_queryset(self):
        qs = Etapa.objects.select_related('proyecto')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs.filter(proyecto_id__in=filter_projects_for_user(Proyecto.objects.all(), self.request.user).values('id'))

    def perform_create(self, serializer):
        proyecto = serializer.validated_data.get('proyecto')
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta crear una etapa.')
        serializer.save()

    def perform_update(self, serializer):
        proyecto = serializer.validated_data.get('proyecto', serializer.instance.proyecto)
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta editar una etapa.')
        serializer.save()


MINUTOS_EDICION_USUARIO = 15


class ComentarioProyectoViewSet(viewsets.ModelViewSet):
    queryset = ComentarioProyecto.objects.select_related('proyecto', 'usuario', 'editado_por')
    serializer_class = ComentarioProyectoSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_project_collaboration_access(request)

    def get_queryset(self):
        qs = ComentarioProyecto.objects.select_related('proyecto', 'usuario', 'editado_por')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs.filter(proyecto_id__in=filter_projects_for_user(Proyecto.objects.all(), self.request.user).values('id'))

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
        proyecto = serializer.validated_data.get('proyecto')
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta comentar.')
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
            ComentarioAuditLog.objects.create(
                tipo='proyecto',
                comentario_id=instance.id,
                accion='editar',
                usuario=self.request.user,
                texto_anterior=texto_anterior,
                texto_nuevo=instance.texto,
                proyecto_id=instance.proyecto_id,
            )
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
            ComentarioAuditLog.objects.create(
                tipo='proyecto',
                comentario_id=instance.id,
                accion='eliminar',
                usuario=self.request.user,
                texto_anterior=instance.texto,
                proyecto_id=instance.proyecto_id,
            )
        instance.delete()


class ComentarioAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """Solo lectura. Permite al administrador consultar el log de ediciones/eliminaciones de comentarios."""
    queryset = ComentarioAuditLog.objects.select_related('usuario').order_by('-fecha')
    serializer_class = ComentarioAuditLogSerializer

    def get_queryset(self):
        require_roles(
            self.request.user,
            ROL_ADMIN,
            message='Solo el Administrador puede consultar el log de auditoría de comentarios.'
        )
        qs = ComentarioAuditLog.objects.select_related('usuario').order_by('-fecha')
        proyecto = self.request.query_params.get("proyecto")
        tarea = self.request.query_params.get("tarea")
        usuario = self.request.query_params.get("usuario")
        tipo = self.request.query_params.get("tipo")
        fecha_desde = self.request.query_params.get("fecha_desde")
        fecha_hasta = self.request.query_params.get("fecha_hasta")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        if usuario:
            qs = qs.filter(usuario_id=usuario)
        if tipo:
            qs = qs.filter(tipo=tipo)
        if fecha_desde:
            qs = qs.filter(fecha__date__gte=fecha_desde)
        if fecha_hasta:
            qs = qs.filter(fecha__date__lte=fecha_hasta)
        return qs

    def list(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'):
            raise PermissionDenied("Solo el Administrador puede consultar el log de auditoría de comentarios.")
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'):
            raise PermissionDenied("Solo el Administrador puede consultar el log de auditoría de comentarios.")
        return super().retrieve(request, *args, **kwargs)


class AdjuntoAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """Solo lectura. Permite al administrador consultar el log de adjuntos."""
    queryset = AdjuntoAuditLog.objects.select_related('usuario').order_by('-fecha')
    serializer_class = AdjuntoAuditLogSerializer

    def get_queryset(self):
        require_roles(
            self.request.user,
            ROL_ADMIN,
            message='Solo el Administrador puede consultar el log de auditoría de adjuntos.'
        )
        qs = AdjuntoAuditLog.objects.select_related('usuario').order_by('-fecha')
        proyecto = self.request.query_params.get("proyecto")
        tarea = self.request.query_params.get("tarea")
        usuario = self.request.query_params.get("usuario")
        tipo = self.request.query_params.get("tipo")
        fecha_desde = self.request.query_params.get("fecha_desde")
        fecha_hasta = self.request.query_params.get("fecha_hasta")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        if usuario:
            qs = qs.filter(usuario_id=usuario)
        if tipo:
            qs = qs.filter(tipo=tipo)
        if fecha_desde:
            qs = qs.filter(fecha__date__gte=fecha_desde)
        if fecha_hasta:
            qs = qs.filter(fecha__date__lte=fecha_hasta)
        return qs

    def list(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'):
            raise PermissionDenied("Solo el Administrador puede consultar el log de auditoría de adjuntos.")
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        user = request.user
        if not (getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'):
            raise PermissionDenied("Solo el Administrador puede consultar el log de auditoría de adjuntos.")
        return super().retrieve(request, *args, **kwargs)


class AdjuntoProyectoViewSet(viewsets.ModelViewSet):
    queryset = AdjuntoProyecto.objects.select_related('proyecto', 'subido_por').order_by('-fecha')
    serializer_class = AdjuntoProyectoSerializer

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        _ensure_project_collaboration_access(request)

    def get_queryset(self):
        qs = AdjuntoProyecto.objects.select_related('proyecto', 'subido_por').order_by('-fecha')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs.filter(proyecto_id__in=filter_projects_for_user(Proyecto.objects.all(), self.request.user).values('id'))

    def _es_admin(self, user):
        return getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'

    def _puede_modificar(self, adjunto):
        user = self.request.user
        return self._es_admin(user) or adjunto.subido_por_id == user.id

    def perform_create(self, serializer):
        proyecto = serializer.validated_data.get('proyecto')
        if not filter_projects_for_user(Proyecto.objects.filter(id=proyecto.id), self.request.user).exists():
            raise PermissionDenied('No tiene acceso al proyecto donde intenta subir un adjunto.')
        serializer.save(subido_por=self.request.user)

    def perform_update(self, serializer):
        instance = serializer.instance
        if not self._puede_modificar(instance):
            raise PermissionDenied("Solo puede editar sus propios adjuntos o ser Administrador.")
        nombre_anterior = instance.nombre_original
        serializer.save()
        AdjuntoAuditLog.objects.create(
            tipo='proyecto',
            adjunto_id=instance.id,
            accion='editar',
            usuario=self.request.user,
            nombre_archivo=instance.nombre_original,
            nombre_anterior=nombre_anterior,
            nombre_nuevo=instance.nombre_original,
            proyecto_id=instance.proyecto_id,
        )

    def perform_destroy(self, instance):
        if not self._puede_modificar(instance):
            raise PermissionDenied("Solo puede eliminar sus propios adjuntos o ser Administrador.")
        AdjuntoAuditLog.objects.create(
            tipo='proyecto',
            adjunto_id=instance.id,
            accion='eliminar',
            usuario=self.request.user,
            nombre_archivo=instance.nombre_original,
            proyecto_id=instance.proyecto_id,
        )
        instance.delete()
