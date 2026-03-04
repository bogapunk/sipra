from rest_framework import serializers
from .models import Tarea, HistorialTarea


class TareaSerializer(serializers.ModelSerializer):
    area_nombre = serializers.SerializerMethodField()

    def get_area_nombre(self, obj):
        return obj.area.nombre if obj.area else ''
    secretaria_nombre = serializers.SerializerMethodField()
    proyecto_nombre = serializers.SerializerMethodField()
    responsable_nombre = serializers.SerializerMethodField()
    organizacion_nombre = serializers.SerializerMethodField()

    def get_secretaria_nombre(self, obj):
        return obj.secretaria.nombre if obj.secretaria else ''

    def get_proyecto_nombre(self, obj):
        return obj.proyecto.nombre if obj.proyecto else '-'

    def get_responsable_nombre(self, obj):
        return obj.responsable.nombre_completo if obj.responsable else '-'

    def get_organizacion_nombre(self, obj):
        if obj.area:
            return f"Área: {obj.area.nombre}"
        if obj.secretaria:
            return f"Secretaría: {obj.secretaria.nombre}"
        return '-'

    def validate(self, data):
        area = data.get('area')
        secretaria = data.get('secretaria')
        if self.instance:
            area = area if 'area' in data else self.instance.area
            secretaria = secretaria if 'secretaria' in data else self.instance.secretaria
        if area and secretaria:
            raise serializers.ValidationError('Seleccione solo un Área o una Secretaría, no ambos.')
        return data

    def update(self, instance, validated_data):
        pct = validated_data.get('porcentaje_avance', instance.porcentaje_avance)
        if pct == 100 and 'estado' not in validated_data:
            validated_data['estado'] = 'Finalizada'
        return super().update(instance, validated_data)

    class Meta:
        model = Tarea
        fields = ['id', 'proyecto', 'proyecto_nombre', 'etapa', 'area', 'area_nombre', 'secretaria', 'secretaria_nombre',
                  'organizacion_nombre', 'titulo', 'descripcion', 'responsable', 'responsable_nombre',
                  'fecha_inicio', 'fecha_vencimiento', 'estado', 'porcentaje_avance', 'prioridad', 'fecha_creacion']


class HistorialTareaSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)

    class Meta:
        model = HistorialTarea
        fields = ['id', 'tarea', 'usuario', 'usuario_nombre', 'comentario', 'porcentaje_anterior', 'porcentaje_avance', 'fecha']
