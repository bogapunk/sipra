from decimal import Decimal

from rest_framework import serializers
from django.db.models import Avg
from areas.models import Area
from secretarias.models import Secretaria
from .upload_validators import validate_uploaded_file, validate_original_filename
from .models import (
    Eje, Plan, Programa, ObjetivoEstrategico,
    Proyecto, ProyectoArea, ProyectoSecretaria, ProyectoEquipo, ProyectoPresupuestoItem, Etapa, ComentarioProyecto, AdjuntoProyecto, Indicador,
    ComentarioAuditLog, AdjuntoAuditLog,
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


class ProyectoPresupuestoItemSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)

    class Meta:
        model = ProyectoPresupuestoItem
        fields = [
            'id',
            'categoria_gasto',
            'monto',
            'detalle',
            'orden',
        ]

    def validate(self, data):
        instance = getattr(self, 'instance', None)
        detalle = (data.get('detalle', getattr(instance, 'detalle', '')) or '').strip()
        monto = data.get('monto', getattr(instance, 'monto', Decimal('0')) or Decimal('0'))
        data['numero_expediente'] = ''
        data['es_viaticos'] = False
        data['dotacion_tipo'] = ''
        data['horas_hombre'] = None
        if Decimal(str(monto or 0)) <= 0 and not detalle:
            raise serializers.ValidationError({
                'detalle': 'Cada gasto debe tener un monto o un detalle u observacion.'
            })
        return data


class ProyectoSerializer(serializers.ModelSerializer):
    usuario_responsable_nombre = serializers.CharField(source='usuario_responsable.nombre_completo', read_only=True)
    area_nombre = serializers.CharField(source='area.nombre', read_only=True)
    equipo_nombres = serializers.SerializerMethodField()
    equipo = serializers.ListField(child=serializers.IntegerField(), write_only=True, required=False)
    presupuesto_items = ProyectoPresupuestoItemSerializer(many=True, required=False)
    presupuesto_cargado = serializers.SerializerMethodField()
    areas_ids = serializers.ListField(child=serializers.IntegerField(), write_only=True, required=False)
    secretarias_ids = serializers.ListField(child=serializers.IntegerField(), write_only=True, required=False)
    areas_asignadas_ids = serializers.SerializerMethodField(read_only=True)
    secretarias_asignadas_ids = serializers.SerializerMethodField(read_only=True)

    def get_equipo_nombres(self, obj):
        return [pe.usuario.nombre_completo for pe in obj.equipo.select_related('usuario').all()]

    def get_presupuesto_cargado(self, obj):
        items = getattr(obj, 'presupuesto_items', None)
        if items is not None:
            try:
                return float(round(sum(Decimal(str(item.monto or 0)) for item in items.all()), 2))
            except TypeError:
                pass
        total = sum(
            Decimal(str(item.monto or 0))
            for item in ProyectoPresupuestoItem.objects.filter(proyecto=obj).only('monto')
        )
        return float(round(total, 2))

    def get_areas_asignadas_ids(self, obj):
        ids = set()
        if obj.area_id:
            ids.add(obj.area_id)
        for pa in obj.proyectoarea_set.all():
            ids.add(pa.area_id)
        return sorted(ids)

    def get_secretarias_asignadas_ids(self, obj):
        ids = set()
        if obj.secretaria_id:
            ids.add(obj.secretaria_id)
        for ps in obj.proyectosecretaria_set.all():
            ids.add(ps.secretaria_id)
        return sorted(ids)

    def _sync_presupuesto_items(self, proyecto, items_data):
        if items_data is None:
            return

        existentes = {
            item.id: item
            for item in proyecto.presupuesto_items.all()
        }
        ids_conservados = set()

        for index, item_data in enumerate(items_data):
            item_id = item_data.pop('id', None)
            item_data['orden'] = item_data.get('orden', index)
            if item_id and item_id in existentes:
                item = existentes[item_id]
                for field, value in item_data.items():
                    setattr(item, field, value)
                item.save()
                ids_conservados.add(item_id)
                continue
            nuevo = ProyectoPresupuestoItem.objects.create(proyecto=proyecto, **item_data)
            ids_conservados.add(nuevo.id)

        proyecto.presupuesto_items.exclude(id__in=ids_conservados).delete()

    def _sync_areas_y_secretarias(self, proyecto, areas_ids, secretarias_ids):
        if areas_ids is not None:
            proyecto.proyectoarea_set.all().delete()
            seen = set()
            for aid in areas_ids:
                if aid in seen:
                    continue
                seen.add(aid)
                ProyectoArea.objects.get_or_create(proyecto=proyecto, area_id=aid)
            if areas_ids:
                first = Area.objects.filter(pk=areas_ids[0]).first()
                proyecto.area = first
                proyecto.secretaria = None
                proyecto.save(update_fields=['area', 'secretaria'])
        elif secretarias_ids is not None:
            proyecto.proyectosecretaria_set.all().delete()
            seen = set()
            for sid in secretarias_ids:
                if sid in seen:
                    continue
                seen.add(sid)
                ProyectoSecretaria.objects.get_or_create(proyecto=proyecto, secretaria_id=sid)
            if secretarias_ids:
                first = Secretaria.objects.filter(pk=secretarias_ids[0]).first()
                proyecto.secretaria = first
                proyecto.area = None
                proyecto.save(update_fields=['area', 'secretaria'])

    def create(self, validated_data):
        equipo_ids = validated_data.pop('equipo', [])
        items_data = validated_data.pop('presupuesto_items', [])
        areas_ids = validated_data.pop('areas_ids', None)
        secretarias_ids = validated_data.pop('secretarias_ids', None)
        if areas_ids is None and secretarias_ids is None:
            a = validated_data.get('area')
            s = validated_data.get('secretaria')
            if a:
                areas_ids = [a.id]
                validated_data.pop('area', None)
            elif s:
                secretarias_ids = [s.id]
                validated_data.pop('secretaria', None)
        proyecto = super().create(validated_data)
        if areas_ids is not None or secretarias_ids is not None:
            self._sync_areas_y_secretarias(proyecto, areas_ids, secretarias_ids)
        for uid in equipo_ids:
            ProyectoEquipo.objects.get_or_create(proyecto=proyecto, usuario_id=uid)
        self._sync_presupuesto_items(proyecto, items_data)
        from .dependencias import actualizar_bandera_transversal
        actualizar_bandera_transversal(proyecto)
        return proyecto

    def update(self, instance, validated_data):
        equipo_ids = validated_data.pop('equipo', None)
        items_data = validated_data.pop('presupuesto_items', None)
        areas_ids = validated_data.pop('areas_ids', None)
        secretarias_ids = validated_data.pop('secretarias_ids', None)
        if areas_ids is not None or secretarias_ids is not None:
            validated_data.pop('area', None)
            validated_data.pop('secretaria', None)
        if areas_ids is None and secretarias_ids is None:
            if validated_data.get('area'):
                areas_ids = [validated_data['area'].id]
                validated_data.pop('area', None)
            elif validated_data.get('secretaria'):
                secretarias_ids = [validated_data['secretaria'].id]
                validated_data.pop('secretaria', None)
        proyecto = super().update(instance, validated_data)
        if areas_ids is not None or secretarias_ids is not None:
            self._sync_areas_y_secretarias(proyecto, areas_ids, secretarias_ids)
        if equipo_ids is not None:
            proyecto.equipo.exclude(usuario_id__in=equipo_ids).delete()
            for uid in equipo_ids:
                ProyectoEquipo.objects.get_or_create(proyecto=proyecto, usuario_id=uid)
        self._sync_presupuesto_items(proyecto, items_data)
        from .dependencias import actualizar_bandera_transversal
        actualizar_bandera_transversal(proyecto)
        return proyecto

    def validate(self, data):
        initial = getattr(self, 'initial_data', {}) or {}
        area = data.get('area')
        secretaria = data.get('secretaria')
        if self.instance:
            area = area if 'area' in data else self.instance.area
            secretaria = secretaria if 'secretaria' in data else self.instance.secretaria
        has_areas_ids = 'areas_ids' in initial
        has_secretarias_ids = 'secretarias_ids' in initial
        if has_areas_ids and has_secretarias_ids:
            a_ids = initial.get('areas_ids') or []
            s_ids = initial.get('secretarias_ids') or []
            if a_ids and s_ids:
                raise serializers.ValidationError(
                    'No puede combinar áreas y secretarías en el mismo proyecto.'
                )
        if has_areas_ids:
            a_ids = initial.get('areas_ids') or []
            if not a_ids:
                raise serializers.ValidationError({'areas_ids': 'Seleccione al menos un área.'})
            data.pop('area', None)
            data.pop('secretaria', None)
        elif has_secretarias_ids:
            s_ids = initial.get('secretarias_ids') or []
            if not s_ids:
                raise serializers.ValidationError({'secretarias_ids': 'Seleccione al menos una secretaría.'})
            data.pop('area', None)
            data.pop('secretaria', None)
        elif area and secretaria:
            raise serializers.ValidationError(
                'Seleccione solo un Área o una Secretaría, no ambos.'
            )
        if self.instance is None and not has_areas_ids and not has_secretarias_ids:
            if not data.get('area') and not data.get('secretaria'):
                raise serializers.ValidationError(
                    'Debe asignar al menos un área o una secretaría.'
                )
        presupuesto_total = data.get(
            'presupuesto_total',
            getattr(self.instance, 'presupuesto_total', Decimal('0')),
        )
        fuente_financiamiento = data.get(
            'fuente_financiamiento',
            getattr(self.instance, 'fuente_financiamiento', Proyecto.FUENTE_PROVINCIAL),
        )
        items = data.get('presupuesto_items', None)
        if Decimal(str(presupuesto_total or 0)) < 0:
            raise serializers.ValidationError({
                'presupuesto_total': 'El presupuesto total no puede ser negativo.'
            })
        if (
            fuente_financiamiento == Proyecto.FUENTE_SIN_EROGACION
            and Decimal(str(presupuesto_total or 0)) != 0
        ):
            raise serializers.ValidationError({
                'presupuesto_total': 'Si la fuente es Sin Erogacion, el presupuesto total debe ser 0.'
            })
        if items is not None and len(items) > 0:
            total_items = sum(Decimal(str(item.get('monto') or 0)) for item in items)
            if total_items > Decimal(str(presupuesto_total or 0)):
                raise serializers.ValidationError({
                    'presupuesto_items': 'La suma de los gastos no puede superar el presupuesto total del proyecto.'
                })
        return data

    class Meta:
        model = Proyecto
        fields = [
            'id', 'nombre', 'descripcion', 'fecha_inicio', 'fecha_fin_estimada', 'fecha_fin_real',
            'estado', 'porcentaje_avance', 'presupuesto_total', 'fuente_financiamiento',
            'creado_por', 'fecha_creacion',
            'programa', 'objetivo_estrategico',
            'usuario_responsable', 'usuario_responsable_nombre',
            'area', 'area_nombre', 'secretaria',
            'areas_ids', 'secretarias_ids', 'areas_asignadas_ids', 'secretarias_asignadas_ids',
            'es_transversal',
            'equipo', 'equipo_nombres', 'presupuesto_items', 'presupuesto_cargado',
        ]
        read_only_fields = ['creado_por', 'fecha_creacion', 'es_transversal']


class ProyectoDashboardSerializer(serializers.ModelSerializer):
    """Incluye avance calculado desde tareas, fecha de última actualización, área y usuario que actualizó.
    Usa context['avances'] y context['ultimos_historiales'] si se pasan para evitar N+1."""
    porcentaje_avance = serializers.SerializerMethodField()
    fecha_ultima_actualizacion = serializers.SerializerMethodField()
    area_ultima_actualizacion = serializers.SerializerMethodField()
    usuario_ultima_actualizacion = serializers.SerializerMethodField()
    responsable_nombre = serializers.SerializerMethodField()
    secretaria_nombre = serializers.SerializerMethodField()
    areas_asignadas = serializers.SerializerMethodField()
    secretarias_asignadas = serializers.SerializerMethodField()
    area_nombre = serializers.SerializerMethodField()
    equipo_nombres = serializers.SerializerMethodField()

    class Meta:
        model = Proyecto
        fields = ['id', 'nombre', 'descripcion', 'estado', 'porcentaje_avance', 'fecha_ultima_actualizacion',
                  'area_ultima_actualizacion', 'usuario_ultima_actualizacion', 'responsable_nombre',
                  'usuario_responsable', 'secretaria', 'secretaria_nombre', 'area', 'area_nombre',
                  'areas_asignadas', 'secretarias_asignadas', 'es_transversal', 'equipo_nombres', 'creado_por',
                  'fecha_inicio', 'fecha_fin_estimada']

    def _get_avance(self, obj):
        avances = self.context.get('avances')
        if avances is not None:
            return round(float(avances.get(obj.id) or 0), 2)
        from tasks.models import Tarea
        result = Tarea.objects.filter(proyecto=obj).aggregate(avg=Avg('porcentaje_avance'))
        return round(float(result['avg'] or 0), 2)

    def get_porcentaje_avance(self, obj):
        return self._get_avance(obj)

    def _get_ultimo_historial(self, obj):
        ultimos = self.context.get('ultimos_historiales')
        if ultimos is not None:
            return ultimos.get(obj.id)
        if not hasattr(obj, '_cache_ultimo_historial'):
            from tasks.models import Tarea, HistorialTarea
            tarea_ids = Tarea.objects.filter(proyecto=obj).values_list('id', flat=True)
            obj._cache_ultimo_historial = HistorialTarea.objects.filter(
                tarea_id__in=tarea_ids
            ).select_related('tarea__area', 'usuario').order_by('-fecha').first()
        return getattr(obj, '_cache_ultimo_historial', None)

    def get_fecha_ultima_actualizacion(self, obj):
        last = self._get_ultimo_historial(obj)
        if last:
            return last.fecha
        return obj.fecha_creacion

    def get_area_ultima_actualizacion(self, obj):
        last = self._get_ultimo_historial(obj)
        if last and last.tarea and last.tarea.area:
            return last.tarea.area.nombre
        if obj.area_id and obj.area:
            return obj.area.nombre
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
        nombres = []
        vistos = set()
        if obj.area_id and obj.area:
            n = obj.area.nombre
            if n and n not in vistos:
                nombres.append(n)
                vistos.add(n)
        for pa in obj.proyectoarea_set.all():
            if pa.area and pa.area.nombre and pa.area.nombre not in vistos:
                nombres.append(pa.area.nombre)
                vistos.add(pa.area.nombre)
        return nombres

    def get_secretarias_asignadas(self, obj):
        nombres = []
        vistos = set()
        if obj.secretaria_id and obj.secretaria:
            n = obj.secretaria.nombre
            if n and n not in vistos:
                nombres.append(n)
                vistos.add(n)
        for ps in obj.proyectosecretaria_set.all():
            if ps.secretaria and ps.secretaria.nombre and ps.secretaria.nombre not in vistos:
                nombres.append(ps.secretaria.nombre)
                vistos.add(ps.secretaria.nombre)
        return nombres

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


class ProyectoSecretariaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProyectoSecretaria
        fields = "__all__"


class EtapaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Etapa
        fields = "__all__"


class ComentarioAuditLogSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)

    class Meta:
        model = ComentarioAuditLog
        fields = ['id', 'tipo', 'comentario_id', 'accion', 'usuario', 'usuario_nombre', 'fecha',
                  'texto_anterior', 'texto_nuevo', 'proyecto_id', 'tarea_id']


class ComentarioProyectoSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)
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

    proyecto_nombre = serializers.CharField(source='proyecto.nombre', read_only=True)

    class Meta:
        model = ComentarioProyecto
        fields = ['id', 'proyecto', 'proyecto_nombre', 'usuario', 'usuario_nombre', 'texto', 'fecha', 'fecha_edicion', 'editado_por', 'editado_por_nombre', 'editado_leyenda']


class AdjuntoAuditLogSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)

    class Meta:
        model = AdjuntoAuditLog
        fields = ['id', 'tipo', 'adjunto_id', 'accion', 'usuario', 'usuario_nombre', 'fecha',
                  'nombre_archivo', 'nombre_anterior', 'nombre_nuevo', 'proyecto_id', 'tarea_id']


class AdjuntoProyectoSerializer(serializers.ModelSerializer):
    subido_por_nombre = serializers.CharField(source='subido_por.nombre_completo', read_only=True)
    proyecto_nombre = serializers.CharField(source='proyecto.nombre', read_only=True)
    url = serializers.SerializerMethodField()

    def get_url(self, obj):
        return obj.archivo.url if obj.archivo else None

    def validate_archivo(self, value):
        return validate_uploaded_file(value)

    def validate_nombre_original(self, value):
        return validate_original_filename(value)

    class Meta:
        model = AdjuntoProyecto
        fields = ['id', 'proyecto', 'proyecto_nombre', 'archivo', 'nombre_original', 'subido_por', 'subido_por_nombre', 'fecha', 'url']
        read_only_fields = ['subido_por', 'fecha']
