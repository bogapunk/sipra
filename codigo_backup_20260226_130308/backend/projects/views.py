from rest_framework import viewsets
from .models import (
    Eje, Plan, Programa, ObjetivoEstrategico, Indicador,
    Proyecto, ProyectoArea, ProyectoEquipo, Etapa, ComentarioProyecto,
)
from .serializers import (
    EjeSerializer, PlanSerializer, ProgramaSerializer,
    ObjetivoEstrategicoSerializer, IndicadorSerializer,
    ProyectoSerializer, ProyectoAreaSerializer, ProyectoEquipoSerializer,
    EtapaSerializer, ComentarioProyectoSerializer,
)


class EjeViewSet(viewsets.ModelViewSet):
    queryset = Eje.objects.all()
    serializer_class = EjeSerializer


class PlanViewSet(viewsets.ModelViewSet):
    queryset = Plan.objects.select_related('eje').all()
    serializer_class = PlanSerializer

    def get_queryset(self):
        qs = Plan.objects.select_related('eje').all()
        eje = self.request.query_params.get('eje')
        if eje:
            qs = qs.filter(eje_id=eje)
        return qs


class ProgramaViewSet(viewsets.ModelViewSet):
    queryset = Programa.objects.select_related('plan').all()
    serializer_class = ProgramaSerializer

    def get_queryset(self):
        qs = Programa.objects.select_related('plan').all()
        plan = self.request.query_params.get('plan')
        if plan:
            qs = qs.filter(plan_id=plan)
        return qs


class ObjetivoEstrategicoViewSet(viewsets.ModelViewSet):
    queryset = ObjetivoEstrategico.objects.select_related('programa').all()
    serializer_class = ObjetivoEstrategicoSerializer

    def get_queryset(self):
        qs = ObjetivoEstrategico.objects.select_related('programa').all()
        programa = self.request.query_params.get('programa')
        if programa:
            qs = qs.filter(programa_id=programa)
        return qs


class IndicadorViewSet(viewsets.ModelViewSet):
    queryset = Indicador.objects.select_related('proyecto').all()
    serializer_class = IndicadorSerializer

    def get_queryset(self):
        qs = Indicador.objects.select_related('proyecto').all()
        proyecto = self.request.query_params.get('proyecto')
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs


class ProyectoViewSet(viewsets.ModelViewSet):
    queryset = Proyecto.objects.select_related('usuario_responsable', 'area', 'secretaria', 'creado_por')
    serializer_class = ProyectoSerializer

    def get_queryset(self):
        qs = Proyecto.objects.select_related(
            'usuario_responsable', 'area', 'secretaria', 'creado_por'
        ).prefetch_related('equipo', 'proyectoarea_set')
        secretaria_id = self.request.query_params.get('secretaria')
        area_id = self.request.query_params.get('area')
        if secretaria_id:
            qs = qs.filter(secretaria_id=secretaria_id)
        if area_id:
            qs = qs.filter(area_id=area_id)
        return qs


class ProyectoEquipoViewSet(viewsets.ModelViewSet):
    queryset = ProyectoEquipo.objects.select_related('proyecto', 'usuario')
    serializer_class = ProyectoEquipoSerializer

    def get_queryset(self):
        qs = ProyectoEquipo.objects.select_related('proyecto', 'usuario')
        proyecto = self.request.query_params.get('proyecto')
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs


class ProyectoAreaViewSet(viewsets.ModelViewSet):
    queryset = ProyectoArea.objects.select_related('proyecto', 'area')
    serializer_class = ProyectoAreaSerializer

    def get_queryset(self):
        qs = ProyectoArea.objects.select_related('proyecto', 'area')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs


class EtapaViewSet(viewsets.ModelViewSet):
    queryset = Etapa.objects.select_related('proyecto')
    serializer_class = EtapaSerializer

    def get_queryset(self):
        qs = Etapa.objects.select_related('proyecto')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs


class ComentarioProyectoViewSet(viewsets.ModelViewSet):
    queryset = ComentarioProyecto.objects.select_related('proyecto', 'usuario')
    serializer_class = ComentarioProyectoSerializer

    def get_queryset(self):
        qs = ComentarioProyecto.objects.select_related('proyecto', 'usuario')
        proyecto = self.request.query_params.get("proyecto")
        if proyecto:
            qs = qs.filter(proyecto_id=proyecto)
        return qs
