from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db.models import Avg, Prefetch, Q
from django.utils import timezone
from collections import defaultdict
from tasks.models import Tarea, HistorialTarea
from projects.models import Proyecto, ProyectoArea, Eje, Plan, Programa, ObjetivoEstrategico, Indicador


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
        secretaria_id = request.query_params.get('secretaria')
        if secretaria_id:
            proyectos = proyectos.filter(secretaria_id=secretaria_id)
        from projects.serializers import ProyectoDashboardSerializer
        ids = list(proyectos.values_list('id', flat=True))
        avances, ultimos_historiales = _bulk_avances_historiales(ids)
        ctx = {'avances': avances, 'ultimos_historiales': ultimos_historiales}
        return Response(ProyectoDashboardSerializer(proyectos, many=True, context=ctx).data)


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
