from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from datetime import timedelta
from django.core.cache import cache
from django.db.models import Avg, Prefetch, Q
from django.utils import timezone
from collections import defaultdict
from hashlib import md5
from urllib.parse import urlencode
from tasks.models import Tarea, HistorialTarea
from projects.models import Proyecto, ProyectoArea, Eje, Plan, Programa, ObjetivoEstrategico, Indicador
from config.pagination import ProjectDashboardPagination


def _bulk_avances_historiales(proyecto_ids):
    """Precalcula avances y últimos historiales para muchos proyectos (evita N+1)."""
    if not proyecto_ids:
        return {}, {}
    from tasks.models import Tarea, HistorialTarea
    avances = dict(
        Tarea.objects.filter(proyecto_id__in=proyecto_ids)
        .values('proyecto_id')
        .annotate(avg=Avg('porcentaje_avance'))
        .values_list('proyecto_id', 'avg')
    )
    historiales = HistorialTarea.objects.filter(
        tarea__proyecto_id__in=proyecto_ids
    ).select_related('tarea__area', 'usuario').order_by('-fecha')
    ultimos = {}
    for h in historiales:
        pid = h.tarea.proyecto_id
        if pid not in ultimos:
            ultimos[pid] = h
    return avances, ultimos
from users.access import (
    ROL_ADMIN,
    ROL_VISUALIZACION,
    filter_projects_for_user,
    filter_tasks_for_user,
    require_roles,
)


class ProyectosPorUsuarioView(APIView):
    """Proyectos del usuario: a_cargo (responsable) y participacion (área/secretaría/equipo).
    Retorna { proyectos_a_cargo: [...], proyectos_participacion: [...] }"""
    def get(self, request, usuario_id):
        if request.user.id != usuario_id:
            require_roles(
                request.user,
                ROL_ADMIN,
                message='Solo el Administrador puede consultar proyectos de otros usuarios.'
            )
        from users.models import Usuario
        from projects.models import ProyectoArea, ProyectoEquipo
        usuario = Usuario.objects.filter(id=usuario_id).first()
        if not usuario:
            return Response({'proyectos_a_cargo': [], 'proyectos_participacion': [], 'proyectos': [], 'tareas_particulares': []})
        ids_a_cargo = set()
        ids_participacion = set()

        # Proyectos a cargo: usuario_responsable = usuario
        ids_a_cargo.update(
            Proyecto.objects.filter(usuario_responsable_id=usuario_id).values_list('id', flat=True)
        )
        # Fallback: proyectos creados por el usuario (si no hay responsable)
        ids_a_cargo.update(
            Proyecto.objects.filter(creado_por_id=usuario_id, usuario_responsable__isnull=True).values_list('id', flat=True)
        )

        # Participación: área, secretaría, equipo o tareas
        if usuario.area_id:
            ids_participacion.update(
                Proyecto.objects.filter(area_id=usuario.area_id).values_list('id', flat=True)
            )
            ids_participacion.update(
                ProyectoArea.objects.filter(area_id=usuario.area_id).values_list('proyecto_id', flat=True)
            )
        if usuario.secretaria_id:
            ids_participacion.update(
                Proyecto.objects.filter(secretaria_id=usuario.secretaria_id).values_list('id', flat=True)
            )
        ids_participacion.update(
            ProyectoEquipo.objects.filter(usuario_id=usuario_id).values_list('proyecto_id', flat=True)
        )
        ids_participacion.update(
            Tarea.objects.filter(responsable_id=usuario_id).values_list('proyecto_id', flat=True).distinct()
        )
        if usuario.area_id:
            ids_participacion.update(
                Tarea.objects.filter(area_id=usuario.area_id).values_list('proyecto_id', flat=True).distinct()
            )
        if usuario.secretaria_id:
            ids_participacion.update(
                Tarea.objects.filter(secretaria_id=usuario.secretaria_id).values_list('proyecto_id', flat=True).distinct()
            )

        ids_participacion -= ids_a_cargo  # No duplicar en participación si ya está a cargo
        ids_participacion.discard(None)

        base_qs = Proyecto.objects.select_related('creado_por', 'secretaria', 'usuario_responsable', 'area').prefetch_related(
            Prefetch('proyectoarea_set', queryset=ProyectoArea.objects.select_related('area')),
            Prefetch('equipo', queryset=ProyectoEquipo.objects.select_related('usuario'))
        )
        proyectos_a_cargo = base_qs.filter(id__in=ids_a_cargo).distinct() if ids_a_cargo else Proyecto.objects.none()
        proyectos_participacion = base_qs.filter(id__in=ids_participacion).distinct() if ids_participacion else Proyecto.objects.none()

        from projects.serializers import ProyectoDashboardSerializer
        from tasks.serializers import TareaSerializer
        todos_ids = list(ids_a_cargo | ids_participacion)
        avances, ultimos_historiales = _bulk_avances_historiales(todos_ids)
        ctx = {'avances': avances, 'ultimos_historiales': ultimos_historiales}
        a_cargo_data = ProyectoDashboardSerializer(proyectos_a_cargo, many=True, context=ctx).data
        participacion_data = ProyectoDashboardSerializer(proyectos_participacion, many=True, context=ctx).data
        # Marcar cada proyecto con es_responsable para el frontend
        for p in a_cargo_data:
            p['es_responsable'] = True
        for p in participacion_data:
            p['es_responsable'] = False
        todos = a_cargo_data + participacion_data

        # Tareas particulares (sin proyecto) asignadas al usuario (sin duplicados)
        tareas_particulares_qs = Tarea.objects.filter(proyecto__isnull=True)
        condiciones_tp = Q(responsable_id=usuario_id)
        if usuario.area_id:
            condiciones_tp |= Q(area_id=usuario.area_id)
        if usuario.secretaria_id:
            condiciones_tp |= Q(secretaria_id=usuario.secretaria_id)
        tareas_particulares_qs = tareas_particulares_qs.filter(condiciones_tp).distinct()
        tareas_particulares_data = TareaSerializer(tareas_particulares_qs.select_related('area', 'secretaria', 'responsable'), many=True).data

        return Response({
            'proyectos_a_cargo': a_cargo_data,
            'proyectos_participacion': participacion_data,
            'proyectos': todos,  # Compatibilidad: lista plana combinada
            'tareas_particulares': tareas_particulares_data,
        })


class AlertasVencimientoView(APIView):
    """Alertas de vencimiento para Admin/Visualizador.
    Tareas: por fecha_vencimiento. Proyectos: por fecha_fin_estimada.
    Excluye tareas Finalizadas y proyectos Finalizados."""
    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar alertas de vencimiento.'
        )
        from tasks.serializers import TareaSerializer
        from datetime import timedelta

        hoy = timezone.now().date()
        limite_proximas = hoy + timedelta(days=7)

        # --- TAREAS: fecha_vencimiento (excluir Finalizada) ---
        tareas_base = Tarea.objects.exclude(estado='Finalizada').filter(
            fecha_vencimiento__isnull=False
        ).select_related('area', 'secretaria', 'proyecto', 'responsable').order_by('fecha_vencimiento')

        tareas_vencidas = tareas_base.filter(fecha_vencimiento__lt=hoy)
        tareas_proximas = tareas_base.filter(fecha_vencimiento__gte=hoy, fecha_vencimiento__lte=limite_proximas)
        tareas_dentro_plazo = tareas_base.filter(fecha_vencimiento__gt=limite_proximas)

        # --- PROYECTOS: fecha_fin_estimada (excluir Finalizado) ---
        proyectos_base = Proyecto.objects.exclude(estado='Finalizado').filter(
            fecha_fin_estimada__isnull=False
        ).select_related('usuario_responsable', 'creado_por').order_by('fecha_fin_estimada')

        proyectos_vencidos = proyectos_base.filter(fecha_fin_estimada__lt=hoy)
        proyectos_proximos = proyectos_base.filter(
            fecha_fin_estimada__gte=hoy, fecha_fin_estimada__lte=limite_proximas
        )
        proyectos_dentro_plazo = proyectos_base.filter(fecha_fin_estimada__gt=limite_proximas)

        def _proyecto_alerta(p):
            return {
                'id': p.id,
                'nombre': p.nombre,
                'fecha_vencimiento': p.fecha_fin_estimada,
                'responsable_nombre': (p.usuario_responsable.nombre_completo if p.usuario_responsable
                                       else (p.creado_por.nombre_completo if p.creado_por else '-')),
                'estado': p.estado,
                'tipo': 'proyecto',
            }

        return Response({
            'tareas_vencidas': TareaSerializer(tareas_vencidas, many=True).data,
            'tareas_proximas_vencer': TareaSerializer(tareas_proximas, many=True).data,
            'tareas_dentro_plazo': TareaSerializer(tareas_dentro_plazo, many=True).data,
            'proyectos_vencidos': [_proyecto_alerta(p) for p in proyectos_vencidos],
            'proyectos_proximos_vencer': [_proyecto_alerta(p) for p in proyectos_proximos],
            'proyectos_dentro_plazo': [_proyecto_alerta(p) for p in proyectos_dentro_plazo],
        })


class ProyectosDashboardView(APIView):
    """Lista de proyectos con avance actualizado y fecha última actualización (para Admin/Visualizador)."""
    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar el dashboard general.'
        )
        from projects.models import ProyectoEquipo
        proyectos = Proyecto.objects.select_related('creado_por', 'secretaria', 'usuario_responsable', 'area').prefetch_related(
            Prefetch('proyectoarea_set', queryset=ProyectoArea.objects.select_related('area')),
            Prefetch('equipo', queryset=ProyectoEquipo.objects.select_related('usuario'))
        ).order_by('id')
        area_id = request.query_params.get('area')
        secretaria_id = request.query_params.get('secretaria')
        estado = request.query_params.get('estado')
        search = (request.query_params.get('search') or '').strip()
        vencimiento = request.query_params.get('vencimiento')
        if area_id:
            proyectos = proyectos.filter(area_id=area_id)
        if secretaria_id:
            proyectos = proyectos.filter(secretaria_id=secretaria_id)
        if estado:
            proyectos = proyectos.filter(estado=estado)
        if search:
            proyectos = proyectos.filter(
                Q(nombre__icontains=search) |
                Q(descripcion__icontains=search) |
                Q(area__nombre__icontains=search) |
                Q(secretaria__nombre__icontains=search) |
                Q(usuario_responsable__nombre__icontains=search) |
                Q(usuario_responsable__apellido__icontains=search) |
                Q(creado_por__nombre__icontains=search) |
                Q(creado_por__apellido__icontains=search)
            )
        if vencimiento:
            hoy = timezone.now().date()
            limite = hoy + timedelta(days=7)
            if vencimiento == 'vencidos':
                proyectos = proyectos.exclude(estado='Finalizado').filter(fecha_fin_estimada__lt=hoy)
            elif vencimiento == 'proximos':
                proyectos = proyectos.exclude(estado='Finalizado').filter(
                    fecha_fin_estimada__gte=hoy,
                    fecha_fin_estimada__lte=limite,
                )
            elif vencimiento == 'en-plazo':
                proyectos = proyectos.exclude(estado='Finalizado').filter(fecha_fin_estimada__gt=limite)
        from projects.serializers import ProyectoDashboardSerializer
        cache_query = request.query_params.copy()
        cache_key_raw = f"{request.user.id}|{urlencode(sorted(cache_query.items()), doseq=True)}"
        cache_key = f"dashboard_proyectos:{md5(cache_key_raw.encode('utf-8')).hexdigest()}"
        cached_payload = cache.get(cache_key)
        if cached_payload is not None:
            return Response(cached_payload)
        paginator = ProjectDashboardPagination()
        page = paginator.paginate_queryset(proyectos, request)
        page_items = page if page is not None else proyectos
        ids = [p.id for p in page_items] if page is not None else list(page_items.values_list('id', flat=True))
        avances, ultimos_historiales = _bulk_avances_historiales(ids)
        ctx = {'avances': avances, 'ultimos_historiales': ultimos_historiales}
        data = ProyectoDashboardSerializer(page_items, many=True, context=ctx).data
        if page is not None:
            payload = paginator.get_paginated_response(data).data
        else:
            payload = data
        cache.set(cache_key, payload, 30)
        return Response(payload)


class EvolucionProyectoView(APIView):
    """Retorna la evolución temporal del avance de un proyecto (serie temporal para gráfica línea)."""
    def get(self, request, proyecto_id):
        proyecto = filter_projects_for_user(Proyecto.objects.filter(id=proyecto_id), request.user).first()
        if not proyecto:
            return Response({"error": "Proyecto no encontrado"}, status=404)

        tareas = list(Tarea.objects.filter(proyecto_id=proyecto_id).values_list('id', flat=True))
        if not tareas:
            return Response([{"fecha": proyecto.fecha_creacion.isoformat(), "porcentaje": 0}])

        historiales = list(HistorialTarea.objects.filter(tarea_id__in=tareas).order_by('fecha').values(
            'tarea_id', 'fecha', 'porcentaje_avance'
        ))

        if not historiales:
            avg = Tarea.objects.filter(proyecto_id=proyecto_id).aggregate(a=Avg('porcentaje_avance'))
            pct = round(float(avg['a'] or 0), 2)
            return Response([
                {"fecha": proyecto.fecha_inicio.isoformat(), "porcentaje": 0},
                {"fecha": timezone.now().isoformat(), "porcentaje": pct},
            ])

        task_current = {tid: 0 for tid in tareas}
        evento_inicial = {"fecha": proyecto.fecha_inicio.isoformat(), "porcentaje": 0}
        resultado = [evento_inicial]
        for h in historiales:
            tid, fecha, pct = h['tarea_id'], h['fecha'], h['porcentaje_avance']
            task_current[tid] = pct
            avg = sum(task_current.values()) / len(tareas)
            resultado.append({"fecha": fecha.isoformat(), "porcentaje": round(avg, 2)})
        return Response(resultado)


class PlanificacionArbolView(APIView):
    """Retorna la estructura jerárquica: Eje → Plan → Programa → Objetivo → Proyecto → Indicador."""
    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar la planificación.'
        )
        ejes = Eje.objects.prefetch_related(
            'planes__programas__objetivos_estrategicos__proyectos__indicadores'
        ).all()
        resultado = []
        for eje in ejes:
            eje_data = {
                'id': eje.id_eje,
                'nombre': eje.nombre_eje,
                'planes': []
            }
            for plan in eje.planes.all():
                plan_data = {
                    'id': plan.id_plan,
                    'nombre': plan.nombre_plan,
                    'programas': []
                }
                for prog in plan.programas.all():
                    prog_data = {
                        'id': prog.id_programa,
                        'nombre': prog.nombre_programa,
                        'objetivos': []
                    }
                    for obj in prog.objetivos_estrategicos.all():
                        proyectos_data = []
                        for p in obj.proyectos.all():
                            proy_dict = {'id': p.id, 'nombre': p.nombre, 'estado': p.estado, 'porcentaje_avance': p.porcentaje_avance}
                            proy_dict['indicadores'] = [
                                {'id': i.id, 'descripcion': i.descripcion, 'unidad_medida': i.unidad_medida, 'frecuencia': i.frecuencia}
                                for i in p.indicadores.all()
                            ]
                            proyectos_data.append(proy_dict)
                        obj_data = {'id': obj.id, 'descripcion': obj.descripcion, 'proyectos': proyectos_data}
                        prog_data['objetivos'].append(obj_data)
                    plan_data['programas'].append(prog_data)
                eje_data['planes'].append(plan_data)
            resultado.append(eje_data)
        return Response(resultado)


class AvancesPorAreaView(APIView):
    """Retorna tareas agrupadas por área o secretaría con avance actual, último incremento y fecha de actualización.
    Query param 'area': filtrar por nombre de área (ej. Presidencia para Visualizador)."""
    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar avances por área.'
        )
        try:
            tareas = Tarea.objects.select_related('area', 'secretaria', 'proyecto').prefetch_related(
                Prefetch('historial', queryset=HistorialTarea.objects.order_by('-fecha'))
            ).all()
            area_filtro = request.query_params.get('area', '').strip()
            if area_filtro:
                tareas = tareas.filter(area__nombre__iexact=area_filtro)
            resultado = defaultdict(lambda: {'area': '', 'tareas': []})

            for t in tareas:
                hist = list(t.historial.all())[:2]
                ultimo_incremento = None
                fecha_ultima = None
                if hist:
                    fecha_ultima = hist[0].fecha
                    if len(hist) >= 2:
                        ultimo_incremento = hist[0].porcentaje_avance - hist[1].porcentaje_avance
                    else:
                        ultimo_incremento = hist[0].porcentaje_avance

                area_nombre = t.area.nombre if t.area else (t.secretaria.nombre if t.secretaria else 'Sin asignar')
                proyecto_nombre = t.proyecto.nombre if t.proyecto else ''
                resultado[area_nombre]['area'] = area_nombre
                resultado[area_nombre]['tareas'].append({
                    'id': t.id,
                    'titulo': t.titulo or '',
                    'proyecto_nombre': proyecto_nombre,
                    'estado': t.estado or 'Pendiente',
                    'porcentaje_avance': t.porcentaje_avance or 0,
                    'ultimo_incremento': ultimo_incremento,
                    'fecha_ultima_actualizacion': fecha_ultima.isoformat() if fecha_ultima else None,
                })

            areas_ordenadas = sorted(resultado.values(), key=lambda x: x['area'])
            return Response({'areas': areas_ordenadas})
        except Exception:
            return Response({'areas': []})


class AvancesPorSecretariaView(APIView):
    """Retorna tareas agrupadas por secretaría con avance actual, último incremento y fecha de actualización.
    Solo incluye tareas vinculadas a una secretaría. Query param 'secretaria': filtrar por ID de secretaría."""
    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar avances por secretaría.'
        )
        try:
            tareas = Tarea.objects.select_related('secretaria', 'proyecto').prefetch_related(
                Prefetch('historial', queryset=HistorialTarea.objects.order_by('-fecha'))
            ).filter(secretaria__isnull=False)
            secretaria_filtro = request.query_params.get('secretaria', '').strip()
            if secretaria_filtro:
                tareas = tareas.filter(secretaria_id=secretaria_filtro)
            resultado = defaultdict(lambda: {'secretaria': '', 'tareas': []})

            for t in tareas:
                hist = list(t.historial.all())[:2]
                ultimo_incremento = None
                fecha_ultima = None
                if hist:
                    fecha_ultima = hist[0].fecha
                    if len(hist) >= 2:
                        ultimo_incremento = hist[0].porcentaje_avance - hist[1].porcentaje_avance
                    else:
                        ultimo_incremento = hist[0].porcentaje_avance

                secretaria_nombre = t.secretaria.nombre if t.secretaria else 'Sin asignar'
                proyecto_nombre = t.proyecto.nombre if t.proyecto else ''
                resultado[secretaria_nombre]['secretaria'] = secretaria_nombre
                resultado[secretaria_nombre]['tareas'].append({
                    'id': t.id,
                    'titulo': t.titulo or '',
                    'proyecto_nombre': proyecto_nombre,
                    'estado': t.estado or 'Pendiente',
                    'porcentaje_avance': t.porcentaje_avance or 0,
                    'ultimo_incremento': ultimo_incremento,
                    'fecha_ultima_actualizacion': fecha_ultima.isoformat() if fecha_ultima else None,
                })

            secretarias_ordenadas = sorted(resultado.values(), key=lambda x: x['secretaria'])
            return Response({'secretarias': secretarias_ordenadas})
        except Exception:
            return Response({'secretarias': []})


class DashboardEjecutivoView(APIView):
    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            message='Solo el Administrador puede consultar el dashboard ejecutivo.'
        )
        from django.db.models import Count, Q
        # Una sola consulta para proyectos
        proy_stats = Proyecto.objects.aggregate(
            total=Count('id'),
            activos=Count('id', filter=Q(estado='Activo')),
        )
        total_proyectos = proy_stats['total'] or 0
        proyectos_activos = proy_stats['activos'] or 0

        # Una sola consulta para tareas (con proyecto)
        tarea_stats = Tarea.objects.filter(proyecto__isnull=False).aggregate(
            total=Count('id'),
            finalizadas=Count('id', filter=Q(estado='Finalizada')),
            bloqueadas=Count('id', filter=Q(estado='Bloqueada')),
        )
        total_tareas = tarea_stats['total'] or 0
        tareas_finalizadas = tarea_stats['finalizadas'] or 0
        tareas_bloqueadas = tarea_stats['bloqueadas'] or 0

        # Una consulta para tareas particulares
        tp_stats = Tarea.objects.filter(proyecto__isnull=True).aggregate(
            total=Count('id'),
            finalizadas=Count('id', filter=Q(estado='Finalizada')),
        )
        tareas_particulares = tp_stats['total'] or 0
        tareas_particulares_finalizadas = tp_stats['finalizadas'] or 0
        total_tareas += tareas_particulares
        tareas_finalizadas += tareas_particulares_finalizadas

        avance_global = (tareas_finalizadas / total_tareas * 100) if total_tareas > 0 else 0
        avance_particulares = (tareas_particulares_finalizadas / tareas_particulares * 100) if tareas_particulares > 0 else 0

        data = {
            "total_proyectos": total_proyectos,
            "proyectos_activos": proyectos_activos,
            "total_tareas": total_tareas,
            "tareas_finalizadas": tareas_finalizadas,
            "tareas_bloqueadas": tareas_bloqueadas,
            "tareas_particulares": tareas_particulares,
            "tareas_particulares_finalizadas": tareas_particulares_finalizadas,
            "avance_particulares": round(avance_particulares, 2),
            "avance_global": round(avance_global, 2),
        }
        return Response(data)


class DashboardAnaliticoView(APIView):
    """Dashboard agregado para gráficos ejecutivos con KPIs y drill-down."""

    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar el dashboard analítico.',
        )
        from datetime import timedelta
        from collections import defaultdict
        from django.db.models import Count
        from django.db.models.functions import TruncMonth

        hoy = timezone.now().date()
        limite_proximo = hoy + timedelta(days=7)

        secretaria_id = request.query_params.get('secretaria')
        area_id = request.query_params.get('area')
        estado_filtro = request.query_params.get('estado')

        proyectos_qs = filter_projects_for_user(
            Proyecto.objects.select_related('secretaria', 'area', 'usuario_responsable', 'creado_por'),
            request.user,
        )
        if secretaria_id:
            proyectos_qs = proyectos_qs.filter(secretaria_id=secretaria_id)
        if area_id:
            proyectos_qs = proyectos_qs.filter(Q(area_id=area_id) | Q(proyectoarea__area_id=area_id)).distinct()
        if estado_filtro:
            proyectos_qs = proyectos_qs.filter(estado=estado_filtro)

        proyectos = list(
            proyectos_qs.values(
                'id',
                'nombre',
                'estado',
                'fecha_inicio',
                'fecha_fin_estimada',
                'fecha_fin_real',
                'porcentaje_avance',
                'secretaria_id',
                'secretaria__nombre',
                'area_id',
                'area__nombre',
                'usuario_responsable_id',
                'usuario_responsable__nombre',
                'usuario_responsable__apellido',
                'creado_por__nombre',
                'creado_por__apellido',
            )
        )
        proyecto_ids = [p['id'] for p in proyectos]

        if proyecto_ids:
            tareas_qs = filter_tasks_for_user(
                Tarea.objects.filter(proyecto_id__in=proyecto_ids).select_related('responsable', 'proyecto'),
                request.user,
            )
        else:
            tareas_qs = Tarea.objects.none()

        tareas = list(
            tareas_qs.values(
                'id',
                'titulo',
                'estado',
                'fecha_vencimiento',
                'porcentaje_avance',
                'proyecto_id',
                'proyecto__nombre',
                'responsable_id',
                'responsable__nombre',
                'responsable__apellido',
            )
        )

        avance_promedio = round(float(tareas_qs.aggregate(avg=Avg('porcentaje_avance')).get('avg') or 0), 2)
        tareas_bloqueadas = sum(1 for t in tareas if t['estado'] == 'Bloqueada')
        tareas_activas = sum(1 for t in tareas if t['estado'] != 'Finalizada')

        def _nombre_persona(nombre, apellido):
            base = f"{nombre or ''} {apellido or ''}".strip()
            return base or 'Sin responsable'

        def _nombre_responsable_proyecto(proyecto):
            if proyecto['usuario_responsable_id']:
                return _nombre_persona(
                    proyecto.get('usuario_responsable__nombre'),
                    proyecto.get('usuario_responsable__apellido'),
                )
            return _nombre_persona(
                proyecto.get('creado_por__nombre'),
                proyecto.get('creado_por__apellido'),
            )

        tareas_por_proyecto = defaultdict(list)
        carga_por_responsable = defaultdict(
            lambda: {'id': None, 'name': 'Sin responsable', 'proyectos': set(), 'tareas': 0, 'bloqueadas': 0}
        )
        tareas_criticas = []
        vencimientos = {
            'Vencidos': {'proyectos': 0, 'tareas': 0},
            'Proximos 7 dias': {'proyectos': 0, 'tareas': 0},
            'En plazo': {'proyectos': 0, 'tareas': 0},
        }

        for tarea in tareas:
            tareas_por_proyecto[tarea['proyecto_id']].append(tarea)
            responsable_id = tarea['responsable_id']
            if responsable_id:
                nombre = _nombre_persona(tarea.get('responsable__nombre'), tarea.get('responsable__apellido'))
                item = carga_por_responsable[responsable_id]
                item['id'] = responsable_id
                item['name'] = nombre
                item['tareas'] += 1
                if tarea['estado'] == 'Bloqueada':
                    item['bloqueadas'] += 1

            fecha_venc = tarea.get('fecha_vencimiento')
            if tarea['estado'] != 'Finalizada' and fecha_venc:
                if fecha_venc < hoy:
                    vencimientos['Vencidos']['tareas'] += 1
                elif fecha_venc <= limite_proximo:
                    vencimientos['Proximos 7 dias']['tareas'] += 1
                else:
                    vencimientos['En plazo']['tareas'] += 1

                dias_restantes = (fecha_venc - hoy).days
                if fecha_venc < hoy or tarea['estado'] == 'Bloqueada' or dias_restantes <= 7:
                    tareas_criticas.append({
                        'id': tarea['id'],
                        'titulo': tarea['titulo'],
                        'proyecto_id': tarea['proyecto_id'],
                        'proyecto_nombre': tarea.get('proyecto__nombre') or '-',
                        'responsable_nombre': _nombre_persona(
                            tarea.get('responsable__nombre'),
                            tarea.get('responsable__apellido'),
                        ),
                        'estado': tarea['estado'],
                        'fecha_vencimiento': fecha_venc,
                        'porcentaje_avance': tarea['porcentaje_avance'] or 0,
                        'dias_restantes': dias_restantes,
                    })

        proyectos_por_estado_map = {'Activo': 0, 'En pausa': 0, 'Finalizado': 0}
        proyectos_por_dependencia_map = defaultdict(
            lambda: {'id': None, 'name': 'Sin dependencia', 'value': 0, 'filter_type': None}
        )
        top_proyectos_atrasados = []
        proyectos_riesgo = []

        for proyecto in proyectos:
            proyectos_por_estado_map[proyecto['estado']] = proyectos_por_estado_map.get(proyecto['estado'], 0) + 1
            secretaria_nombre = proyecto.get('secretaria__nombre')
            area_nombre = proyecto.get('area__nombre')
            if secretaria_nombre:
                dep_key = f"secretaria:{proyecto.get('secretaria_id')}"
                dep_name = f"Secretaria: {secretaria_nombre}"
                dep_type = 'secretaria'
                dep_id = proyecto.get('secretaria_id')
            elif area_nombre:
                dep_key = f"area:{proyecto.get('area_id')}"
                dep_name = f"Area: {area_nombre}"
                dep_type = 'area'
                dep_id = proyecto.get('area_id')
            else:
                dep_key = 'sin-dependencia'
                dep_name = 'Sin dependencia'
                dep_type = None
                dep_id = None
            dep_item = proyectos_por_dependencia_map[dep_key]
            dep_item['id'] = dep_id
            dep_item['name'] = dep_name
            dep_item['filter_type'] = dep_type
            dep_item['value'] += 1

            responsable_nombre = _nombre_responsable_proyecto(proyecto)
            if proyecto['usuario_responsable_id']:
                carga_item = carga_por_responsable[proyecto['usuario_responsable_id']]
                carga_item['id'] = proyecto['usuario_responsable_id']
                carga_item['name'] = responsable_nombre
                carga_item['proyectos'].add(proyecto['id'])

            tareas_proyecto = tareas_por_proyecto.get(proyecto['id'], [])
            if tareas_proyecto:
                avance_real = round(
                    sum((t['porcentaje_avance'] or 0) for t in tareas_proyecto) / len(tareas_proyecto),
                    2,
                )
            else:
                avance_real = round(float(proyecto.get('porcentaje_avance') or 0), 2)

            fecha_fin = proyecto.get('fecha_fin_estimada')
            dias_atraso = 0
            if fecha_fin and proyecto['estado'] != 'Finalizado' and fecha_fin < hoy:
                dias_atraso = (hoy - fecha_fin).days
                top_proyectos_atrasados.append({
                    'id': proyecto['id'],
                    'name': proyecto['nombre'],
                    'value': dias_atraso,
                    'avance': avance_real,
                    'responsable_nombre': responsable_nombre,
                    'fecha_fin_estimada': fecha_fin,
                    'estado': proyecto['estado'],
                })

            if fecha_fin and proyecto['estado'] != 'Finalizado':
                if fecha_fin < hoy:
                    vencimientos['Vencidos']['proyectos'] += 1
                elif fecha_fin <= limite_proximo:
                    vencimientos['Proximos 7 dias']['proyectos'] += 1
                else:
                    vencimientos['En plazo']['proyectos'] += 1

            tareas_bloqueadas_proyecto = sum(1 for t in tareas_proyecto if t['estado'] == 'Bloqueada')
            proximo_a_vencer = bool(fecha_fin and hoy <= fecha_fin <= limite_proximo)
            en_riesgo = (
                dias_atraso > 0
                or tareas_bloqueadas_proyecto > 0
                or (proximo_a_vencer and avance_real < 80)
            )
            if en_riesgo:
                proyectos_riesgo.append({
                    'id': proyecto['id'],
                    'nombre': proyecto['nombre'],
                    'estado': proyecto['estado'],
                    'responsable_nombre': responsable_nombre,
                    'secretaria_nombre': proyecto.get('secretaria__nombre') or proyecto.get('area__nombre') or '-',
                    'fecha_fin_estimada': fecha_fin,
                    'porcentaje_avance': avance_real,
                    'tareas_bloqueadas': tareas_bloqueadas_proyecto,
                    'dias_atraso': dias_atraso,
                })

        tendencia_qs = (
            HistorialTarea.objects.filter(tarea__proyecto_id__in=proyecto_ids)
            .annotate(periodo=TruncMonth('fecha'))
            .values('periodo')
            .annotate(
                avance_promedio=Avg('porcentaje_avance'),
                actualizaciones=Count('id'),
            )
            .order_by('periodo')
        )
        tendencia = [
            {
                'periodo': row['periodo'].date().isoformat(),
                'label': row['periodo'].strftime('%b %Y'),
                'valor': round(float(row['avance_promedio'] or 0), 2),
                'actualizaciones': row['actualizaciones'],
            }
            for row in tendencia_qs
            if row['periodo']
        ]
        if len(tendencia) > 12:
            tendencia = tendencia[-12:]

        proyectos_por_estado = [
            {'name': estado, 'value': valor}
            for estado, valor in proyectos_por_estado_map.items()
            if valor > 0
        ]
        proyectos_por_dependencia = sorted(
            proyectos_por_dependencia_map.values(),
            key=lambda item: (-item['value'], item['name']),
        )[:10]
        top_proyectos_atrasados = sorted(
            top_proyectos_atrasados,
            key=lambda item: (-item['value'], item['name']),
        )[:8]
        proyectos_riesgo = sorted(
            proyectos_riesgo,
            key=lambda item: (-item['dias_atraso'], -item['tareas_bloqueadas'], item['nombre']),
        )[:8]
        tareas_criticas = sorted(
            tareas_criticas,
            key=lambda item: (
                0 if item['dias_restantes'] < 0 else 1,
                item['dias_restantes'],
                item['titulo'],
            ),
        )[:8]
        carga_responsables = sorted(
            (
                {
                    'id': item['id'],
                    'name': item['name'],
                    'proyectos': len(item['proyectos']),
                    'tareas': item['tareas'],
                    'bloqueadas': item['bloqueadas'],
                    'value': len(item['proyectos']) + item['tareas'],
                }
                for item in carga_por_responsable.values()
                if item['id']
            ),
            key=lambda item: (-item['value'], -item['bloqueadas'], item['name']),
        )[:10]

        return Response({
            'kpis': {
                'total_proyectos': len(proyectos),
                'proyectos_activos': sum(1 for p in proyectos if p['estado'] == 'Activo'),
                'proyectos_finalizados': sum(1 for p in proyectos if p['estado'] == 'Finalizado'),
                'avance_promedio': avance_promedio,
                'proyectos_en_riesgo': len(proyectos_riesgo),
                'tareas_bloqueadas': tareas_bloqueadas,
                'tareas_activas': tareas_activas,
            },
            'charts': {
                'proyectos_por_estado': proyectos_por_estado,
                'proyectos_por_dependencia': proyectos_por_dependencia,
                'tendencia_avance': tendencia,
                'vencimientos': [
                    {
                        'categoria': categoria,
                        'proyectos': valores['proyectos'],
                        'tareas': valores['tareas'],
                    }
                    for categoria, valores in vencimientos.items()
                ],
                'top_proyectos_atrasados': top_proyectos_atrasados,
                'carga_por_responsable': carga_responsables,
            },
            'highlights': {
                'proyectos_riesgo': proyectos_riesgo,
                'tareas_criticas': tareas_criticas,
            },
            'filtros': {
                'secretaria': secretaria_id,
                'area': area_id,
                'estado': estado_filtro,
            },
        })
