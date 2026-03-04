from rest_framework import serializers
from django.db.models import Avg
from .models import (
    Eje, Plan, Programa, ObjetivoEstrategico,
    Proyecto, ProyectoArea, ProyectoEquipo, Etapa, ComentarioProyecto, Indicador,
)


class EjeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Eje
        fields = '__all__'


class PlanSerializer(serializers.ModelSerializer):
    eje_nombre = serializers.CharField(source='eje.nombre_eje', read_only=True)

    class Meta:
        model = Plan
        fields = '__all__'


class ProgramaSerializer(serializers.ModelSerializer):
    plan_nombre = serializers.CharField(source='plan.nombre_plan', read_only=True)

    class Meta:
        model = Programa
        fields = '__all__'


class ObjetivoEstrategicoSerializer(serializers.ModelSerializer):
    programa_nombre = serializers.CharField(source='programa.nombre_programa', read_only=True)

    class Meta:
        model = ObjetivoEstrategico
        fields = '__all__'


class IndicadorSerializer(serializers.ModelSerializer):
    proyecto_nombre = serializers.CharField(source='proyecto.nombre', read_only=True)

    class Meta:
        model = Indicador
        fields = '__all__'


class ProyectoEquipoSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)

    class Meta:
        model = ProyectoEquipo
        fields = ['id', 'proyecto', 'usuario', 'usuario_nombre']


class ProyectoSerializer(serializers.ModelSerializer):
    usuario_responsable_nombre = serializers.CharField(source='usuario_responsable.nombre_completo', read_only=True)
    area_nombre = serializers.CharField(source='area.nombre', read_only=True)
    equipo_nombres = serializers.SerializerMethodField()
    equipo = serializers.ListField(child=serializers.IntegerField(), write_only=True, required=False)

    def get_equipo_nombres(self, obj):
        return [pe.usuario.nombre_completo for pe in obj.equipo.select_related('usuario').all()]

    def create(self, validated_data):
        equipo_ids = validated_data.pop('equipo', [])
        proyecto = super().create(validated_data)
        for uid in equipo_ids:
            ProyectoEquipo.objects.get_or_create(proyecto=proyecto, usuario_id=uid)
        return proyecto

    def update(self, instance, validated_data):
        equipo_ids = validated_data.pop('equipo', None)
        proyecto = super().update(instance, validated_data)
        if equipo_ids is not None:
            proyecto.equipo.exclude(usuario_id__in=equipo_ids).delete()
            for uid in equipo_ids:
                ProyectoEquipo.objects.get_or_create(proyecto=proyecto, usuario_id=uid)
        return proyecto

    class Meta:
        model = Proyecto
        fields = [
            'id', 'nombre', 'descripcion', 'fecha_inicio', 'fecha_fin_estimada', 'fecha_fin_real',
            'estado', 'porcentaje_avance', 'creado_por', 'fecha_creacion',
            'programa', 'objetivo_estrategico',
            'usuario_responsable', 'usuario_responsable_nombre',
            'area', 'area_nombre', 'secretaria',
            'equipo', 'equipo_nombres',
        ]


class ProyectoDashboardSerializer(serializers.ModelSerializer):
    """Incluye avance calculado desde tareas, fecha de última actualización, área y usuario que actualizó."""
    porcentaje_avance = serializers.SerializerMethodField()
    fecha_ultima_actualizacion = serializers.SerializerMethodField()
    area_ultima_actualizacion = serializers.SerializerMethodField()
    usuario_ultima_actualizacion = serializers.SerializerMethodField()
    responsable_nombre = serializers.SerializerMethodField()
    secretaria_nombre = serializers.SerializerMethodField()
    areas_asignadas = serializers.SerializerMethodField()
    area_nombre = serializers.SerializerMethodField()
    equipo_nombres = serializers.SerializerMethodField()

    class Meta:
        model = Proyecto
        fields = ['id', 'nombre', 'descripcion', 'estado', 'porcentaje_avance', 'fecha_ultima_actualizacion',
                  'area_ultima_actualizacion', 'usuario_ultima_actualizacion', 'responsable_nombre',
                  'usuario_responsable', 'secretaria', 'secretaria_nombre', 'area', 'area_nombre',
                  'areas_asignadas', 'equipo_nombres', 'creado_por', 'fecha_inicio', 'fecha_fin_estimada']

    def get_porcentaje_avance(self, obj):
        from tasks.models import Tarea
        result = Tarea.objects.filter(proyecto=obj).aggregate(avg=Avg('porcentaje_avance'))
        return round(float(result['avg'] or 0), 2)

    def _get_ultimo_historial(self, obj):
        if not hasattr(obj, '_cache_ultimo_historial'):
            from tasks.models import Tarea, HistorialTarea
            tarea_ids = Tarea.objects.filter(proyecto=obj).values_list('id', flat=True)
            obj._cache_ultimo_historial = HistorialTarea.objects.filter(
                tarea_id__in=tarea_ids
            ).select_related('tarea__area', 'usuario').order_by('-fecha').first()
        return obj._cache_ultimo_historial

    def get_fecha_ultima_actualizacion(self, obj):
        last = self._get_ultimo_historial(obj)
        if last:
            return last.fecha
        return obj.fecha_creacion

    def get_area_ultima_actualizacion(self, obj):
        last = self._get_ultimo_historial(obj)
        if last and last.tarea and last.tarea.area:
            return last.tarea.area.nombre
        from tasks.models import Tarea
        primera_tarea = Tarea.objects.filter(proyecto=obj).select_related('area').first()
        if primera_tarea and primera_tarea.area:
            return primera_tarea.area.nombre
        return '-'

    def get_usuario_ultima_actualizacion(self, obj):
        last = self._get_ultimo_historial(obj)
        if last and last.usuario:
            return last.usuario.nombre_completo
        return '-'

    def get_responsable_nombre(self, obj):
        return obj.usuario_responsable.nombre_completo if obj.usuario_responsable else (obj.creado_por.nombre_completo if obj.creado_por else '-')

    def get_secretaria_nombre(self, obj):
        return obj.secretaria.nombre if obj.secretaria else None

    def get_area_nombre(self, obj):
        return obj.area.nombre if obj.area else None

    def get_areas_asignadas(self, obj):
        if obj.area_id:
            return [obj.area.nombre] if obj.area else []
        return [pa.area.nombre for pa in obj.proyectoarea_set.all() if pa.area]

    def get_equipo_nombres(self, obj):
        equipo_rel = getattr(obj, 'equipo', None)
        if not equipo_rel:
            return []
        try:
            return [pe.usuario.nombre_completo for pe in equipo_rel.all() if pe.usuario]
        except (TypeError, AttributeError):
            return []


class ProyectoAreaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProyectoArea
        fields = "__all__"


class EtapaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Etapa
        fields = "__all__"


class ComentarioProyectoSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)

    class Meta:
        model = ComentarioProyecto
        fields = ['id', 'proyecto', 'usuario', 'usuario_nombre', 'texto', 'fecha']
