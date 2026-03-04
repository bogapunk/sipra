from rest_framework import viewsets
from django.db.models import Q
from .models import Tarea, HistorialTarea
from .serializers import TareaSerializer, HistorialTareaSerializer


class TareaViewSet(viewsets.ModelViewSet):
    queryset = Tarea.objects.select_related('area', 'secretaria', 'proyecto', 'responsable')
    serializer_class = TareaSerializer

    def perform_update(self, serializer):
        instance = serializer.save()
        if instance.proyecto_id and instance.porcentaje_avance == 100 and instance.estado == 'Finalizada':
            from projects.models import Proyecto
            tareas_proy = Tarea.objects.filter(proyecto_id=instance.proyecto_id)
            if tareas_proy.exists() and all(t.porcentaje_avance == 100 for t in tareas_proy):
                Proyecto.objects.filter(id=instance.proyecto_id).update(estado='Finalizado')

    def get_queryset(self):
        qs = Tarea.objects.select_related('area', 'secretaria', 'proyecto', 'responsable')
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
        return qs


class HistorialTareaViewSet(viewsets.ModelViewSet):
    queryset = HistorialTarea.objects.select_related('tarea', 'usuario').order_by('-fecha')
    serializer_class = HistorialTareaSerializer

    def get_queryset(self):
        qs = HistorialTarea.objects.select_related('tarea', 'usuario').order_by('-fecha')
        tarea = self.request.query_params.get("tarea")
        if tarea:
            qs = qs.filter(tarea_id=tarea)
        return qs
