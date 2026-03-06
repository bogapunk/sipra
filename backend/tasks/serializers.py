from rest_framework import serializers
from .models import Tarea, HistorialTarea, ComentarioTarea, AdjuntoTarea


class TareaSerializer(serializers.ModelSerializer):
    area_nombre = serializers.SerializerMethodField()
    tarea_padre_nombre = serializers.SerializerMethodField()
    subtareas = serializers.SerializerMethodField()

    def get_area_nombre(self, obj):
        return obj.area.nombre if obj.area else ''
    secretaria_nombre = serializers.SerializerMethodField()
    proyecto_nombre = serializers.SerializerMethodField()
    responsable_nombre = serializers.SerializerMethodField()
    organizacion_nombre = serializers.SerializerMethodField()

    def get_tarea_padre_nombre(self, obj):
        return obj.tarea_padre.titulo if obj.tarea_padre else None

    def get_subtareas(self, obj):
        if self.context.get('subtarea'):
            return []
        hijos = obj.subtareas.select_related('area', 'secretaria', 'proyecto', 'responsable').order_by('orden', 'id')
        return TareaSerializer(hijos, many=True, context={'subtarea': True}).data

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
        tarea_padre = data.get('tarea_padre')
        if self.instance:
            area = area if 'area' in data else self.instance.area
            secretaria = secretaria if 'secretaria' in data else self.instance.secretaria
        if area and secretaria:
            raise serializers.ValidationError('Seleccione solo un Área o una Secretaría, no ambos.')
        padre = tarea_padre
        if isinstance(tarea_padre, int):
            padre = Tarea.objects.filter(pk=tarea_padre).first()
        if padre and self.instance and padre.id == self.instance.id:
            raise serializers.ValidationError({'tarea_padre': 'Una tarea no puede ser padre de sí misma.'})
        if padre and getattr(padre, 'tarea_padre_id', None):
            raise serializers.ValidationError({'tarea_padre': 'Solo se permite un nivel de subtareas. La tarea padre no puede ser a su vez subtarea.'})
        return data

    def update(self, instance, validated_data):
        pct = validated_data.get('porcentaje_avance', instance.porcentaje_avance)
        if pct == 100 and 'estado' not in validated_data:
            validated_data['estado'] = 'Finalizada'
        return super().update(instance, validated_data)

    class Meta:
        model = Tarea
        fields = ['id', 'proyecto', 'proyecto_nombre', 'tarea_padre', 'tarea_padre_nombre', 'subtareas',
                  'etapa', 'area', 'area_nombre', 'secretaria', 'secretaria_nombre',
                  'organizacion_nombre', 'titulo', 'descripcion', 'responsable', 'responsable_nombre',
                  'fecha_inicio', 'fecha_vencimiento', 'estado', 'porcentaje_avance', 'prioridad', 'orden', 'fecha_creacion']


class HistorialTareaSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)

    class Meta:
        model = HistorialTarea
        fields = ['id', 'tarea', 'usuario', 'usuario_nombre', 'comentario', 'porcentaje_anterior', 'porcentaje_avance', 'fecha']


class ComentarioTareaSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)
    usuario = serializers.PrimaryKeyRelatedField(read_only=True)
    editado_por_nombre = serializers.SerializerMethodField()
    editado_leyenda = serializers.SerializerMethodField()

    def get_editado_por_nombre(self, obj):
        return obj.editado_por.nombre_completo if obj.editado_por else None

    def get_editado_leyenda(self, obj):
        if not obj.fecha_edicion:
            return None
        from django.utils.formats import date_format
        from django.utils import timezone
        fecha_str = date_format(timezone.localtime(obj.fecha_edicion), 'd/m/Y H:i')
        quien = obj.editado_por.nombre_completo if obj.editado_por else 'Sistema'
        return f"Editado el {fecha_str} por {quien}"

    tarea_nombre = serializers.CharField(source='tarea.titulo', read_only=True)

    class Meta:
        model = ComentarioTarea
        fields = ['id', 'tarea', 'tarea_nombre', 'usuario', 'usuario_nombre', 'texto', 'fecha', 'fecha_edicion', 'editado_por', 'editado_por_nombre', 'editado_leyenda']


class AdjuntoTareaSerializer(serializers.ModelSerializer):
    subido_por_nombre = serializers.CharField(source='subido_por.nombre_completo', read_only=True)
    tarea_nombre = serializers.CharField(source='tarea.titulo', read_only=True)
    url = serializers.SerializerMethodField()

    def get_url(self, obj):
        return obj.archivo.url if obj.archivo else None

    class Meta:
        model = AdjuntoTarea
        fields = ['id', 'tarea', 'tarea_nombre', 'archivo', 'nombre_original', 'subido_por', 'subido_por_nombre', 'fecha', 'url']
        read_only_fields = ['subido_por', 'fecha']
