"""Búsqueda de tareas por varios términos y campos relacionados (proyecto, dependencias, responsables)."""
import unicodedata

from django.db.models import Exists, OuterRef, Q

from common.text_search import q_text_icontains

from projects.models import ProyectoArea, ProyectoEquipo, ProyectoSecretaria

from users.access import dedupe_queryset_by_pk


def _normalize_search(s: str) -> str:
    s = (s or '').strip()
    if s.startswith('\ufeff'):
        s = s[1:]
    return unicodedata.normalize('NFC', s)


def _sin_tildes(s: str) -> str:
    if not s:
        return ''
    return ''.join(c for c in unicodedata.normalize('NFKD', s) if unicodedata.category(c) != 'Mn')


def _q_term(term: str, *, multi_word: bool):
    """
    multi_word=False: joins directos en proyecto (una palabra; compatibilidad SQL Server).
    multi_word=True: Exists en vínculos M2M del proyecto para AND entre varias palabras.
    """
    from .models import ComentarioTarea, HistorialTarea

    term = (term or '').strip()
    if not term:
        return Q(pk__in=[])
    alt = _sin_tildes(term)

    tx = q_text_icontains('texto', term, alt)
    comentarios_exist = Exists(ComentarioTarea.objects.filter(tarea_id=OuterRef('pk')).filter(tx))

    hx = q_text_icontains('comentario', term, alt)
    historial_exist = Exists(HistorialTarea.objects.filter(tarea_id=OuterRef('pk')).filter(hx))

    term_q = (
        Q(titulo__icontains=term)
        | q_text_icontains('descripcion', term, alt)
        | Q(proyecto__nombre__icontains=term)
        | q_text_icontains('proyecto__descripcion', term, alt)
        | Q(responsable__nombre__icontains=term)
        | Q(responsable__apellido__icontains=term)
        | Q(area__nombre__icontains=term)
        | Q(secretaria__nombre__icontains=term)
        | Q(secretaria__codigo__icontains=term)
        | Q(proyecto__area__nombre__icontains=term)
        | Q(proyecto__secretaria__nombre__icontains=term)
        | Q(proyecto__secretaria__codigo__icontains=term)
        | Q(proyecto__usuario_responsable__nombre__icontains=term)
        | Q(proyecto__usuario_responsable__apellido__icontains=term)
        | Q(proyecto__creado_por__nombre__icontains=term)
        | Q(proyecto__creado_por__apellido__icontains=term)
        | Q(etapa__nombre__icontains=term)
        | Q(etapa__estado__icontains=term)
        | Q(tarea_padre__titulo__icontains=term)
        | comentarios_exist
        | historial_exist
    )

    if not multi_word:
        term_q |= (
            Q(proyecto__proyectoarea__area__nombre__icontains=term)
            | q_text_icontains('proyecto__proyectoarea__area__descripcion', term, alt)
            | Q(proyecto__proyectosecretaria_set__secretaria__nombre__icontains=term)
            | Q(proyecto__proyectosecretaria_set__secretaria__codigo__icontains=term)
            | Q(proyecto__equipo__usuario__nombre__icontains=term)
            | Q(proyecto__equipo__usuario__apellido__icontains=term)
        )
    else:
        pa_q = Q(area__nombre__icontains=term) | q_text_icontains('area__descripcion', term, alt)
        ps_q = Q(secretaria__nombre__icontains=term) | Q(secretaria__codigo__icontains=term)
        eq_q = Q(usuario__nombre__icontains=term) | Q(usuario__apellido__icontains=term)
        pa_exist = Exists(
            ProyectoArea.objects.filter(proyecto_id=OuterRef('proyecto_id')).filter(pa_q)
        )
        ps_exist = Exists(
            ProyectoSecretaria.objects.filter(proyecto_id=OuterRef('proyecto_id')).filter(ps_q)
        )
        eq_exist = Exists(
            ProyectoEquipo.objects.filter(proyecto_id=OuterRef('proyecto_id')).filter(eq_q)
        )
        term_q |= pa_exist | ps_exist | eq_exist

    if term.isdigit() and len(term) == 4:
        y = int(term)
        if 1900 <= y <= 2100:
            term_q |= (
                Q(fecha_inicio__year=y)
                | Q(fecha_vencimiento__year=y)
                | Q(proyecto__fecha_inicio__year=y)
                | Q(proyecto__fecha_fin_estimada__year=y)
            )
    return term_q


def aplicar_busqueda_tareas(qs, search: str):
    search = _normalize_search(search)
    if not search:
        return qs
    terms = [t for t in search.replace(',', ' ').split() if t.strip()]
    if not terms:
        return qs

    if len(terms) <= 1:
        return dedupe_queryset_by_pk(qs.filter(_q_term(terms[0], multi_word=False)))

    q_and = Q()
    for term in terms:
        q_and &= _q_term(term, multi_word=True)

    phrase_q = _q_term(search, multi_word=False)
    search_alt = _sin_tildes(search)
    if search_alt and search_alt != search:
        phrase_q |= Q(titulo__icontains=search_alt) | q_text_icontains('descripcion', search, search_alt)

    return dedupe_queryset_by_pk(qs.filter(q_and | phrase_q))
