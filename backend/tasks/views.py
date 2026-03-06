from datetime import timedelta
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q, Prefetch, Max
from .models import Tarea, HistorialTarea, ComentarioTarea, AdjuntoTarea
from projects.models import AdjuntoAuditLog
from .serializers import TareaSerializer, HistorialTareaSerializer, ComentarioTareaSerializer, AdjuntoTareaSerializer

MINUTOS_EDICION_USUARIO = 15


class TareaViewSet(viewsets.ModelViewSet):
    queryset = Tarea.objects.select_related(
        'area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre'
    ).prefetch_related(
        Prefetch('subtareas', queryset=Tarea.objects.select_related('area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre'))
    )
    serializer_class = TareaSerializer

    def perform_create(self, serializer):
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

    def get_queryset(self):
        qs = Tarea.objects.select_related(
            'area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre'
        ).prefetch_related(
            Prefetch(
                'subtareas',
                queryset=Tarea.objects.select_related('area', 'secretaria', 'proyecto', 'responsable', 'tarea_padre').order_by('orden', 'id')
            )
        )
        proyecto = self.request.query_params.get("proyecto")
        area = self.request.query_params.get("area")
        estado = self.request.query_params.get("estado")
        responsable = self.request.query_params.get("responsable")
        usuario = self.request.query_params.get("usuario")
        if usuario:
            from users.models import Usuario
            from projects.models import Proyecto, ProyectoEquipo
            u = Usuario.objects.filter(id=usuario).first()
            if u:
                condiciones = Q(responsable_id=u.id)
                if u.area_id:
                    condiciones |= Q(area_id=u.area_id)
                if u.secretaria_id:
                    condiciones |= Q(secretaria_id=u.secretaria_id)
                proy_ids_responsable = Proyecto.objects.filter(usuario_responsable_id=u.id).values_list('id', flat=True)
                proy_ids_equipo = ProyectoEquipo.objects.filter(usuario_id=u.id).values_list('proyecto_id', flat=True)
                proy_ids = set(proy_ids_responsable) | set(proy_ids_equipo)
                if proy_ids:
                    condiciones |= Q(proyecto_id__in=proy_ids)
                qs = qs.filter(condiciones)
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        if area and not usuario:
            qs = qs.filter(area_id=area)
        secretaria = self.request.query_params.get("secretaria")
        if secretaria and not usuario:
            qs = qs.filter(secretaria_id=secretaria)
        if estado:
            qs = qs.filter(estado=estado)
        if responsable and not usuario:
            qs = qs.filter(responsable_id=responsable)
        return qs.order_by('tarea_padre_id', 'orden', 'id')


class HistorialTareaViewSet(viewsets.ModelViewSet):
    queryset = HistorialTarea.objects.select_related('tarea', 'usuario').order_by('-fecha')
    serializer_class = HistorialTareaSerializer

    def get_queryset(self):
        qs = HistorialTarea.objects.select_related('tarea', 'usuario').order_by('-fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs


class ComentarioTareaViewSet(viewsets.ModelViewSet):
    queryset = ComentarioTarea.objects.select_related('tarea', 'usuario', 'editado_por').order_by('fecha')
    serializer_class = ComentarioTareaSerializer

    def get_queryset(self):
        qs = ComentarioTarea.objects.select_related('tarea', 'usuario', 'editado_por').order_by('fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs

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

    def get_queryset(self):
        qs = AdjuntoTarea.objects.select_related('tarea', 'subido_por').order_by('-fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs

    def _es_admin(self, user):
        return getattr(user, 'rol', None) and getattr(user.rol, 'nombre', None) == 'Administrador'

    def _puede_modificar(self, adjunto):
        user = self.request.user
        return self._es_admin(user) or adjunto.subido_por_id == user.id

    def perform_create(self, serializer):
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
