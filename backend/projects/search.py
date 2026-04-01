"""Búsqueda de proyectos por varios términos y campos ampliados."""
import unicodedata

from django.db.models import Exists, OuterRef, Q

from common.text_search import q_text_icontains

from users.access import dedupe_queryset_by_pk


def _normalize_search(s: str) -> str:
    s = (s or '').strip()
    if s.startswith('\ufeff'):
        s = s[1:]
    return unicodedata.normalize('NFC', s)


def _sin_tildes(s: str) -> str:
    """Versión aproximada sin marcas diacríticas para coincidir con textos guardados sin acentos."""
    if not s:
        return ''
    return ''.join(c for c in unicodedata.normalize('NFKD', s) if unicodedata.category(c) != 'Mn')


def _q_term(term: str, *, multi_word: bool):
    """
    multi_word=False: joins directos (mejor compatibilidad SQL Server en una sola palabra).
    multi_word=True: Exists en tareas y vínculos M2M para AND entre términos.
    """
    from tasks.models import Tarea

    from .models import ProyectoArea, ProyectoEquipo, ProyectoSecretaria

    term = (term or '').strip()
    if not term:
        return Q(pk__in=[])
    alt = _sin_tildes(term)

    term_q = (
        Q(nombre__icontains=term)
        | q_text_icontains('descripcion', term, alt)
        | Q(area__nombre__icontains=term)
        | q_text_icontains('area__descripcion', term, alt)
        | Q(secretaria__nombre__icontains=term)
        | Q(secretaria__codigo__icontains=term)
        | Q(usuario_responsable__nombre__icontains=term)
        | Q(usuario_responsable__apellido__icontains=term)
        | Q(creado_por__nombre__icontains=term)
        | Q(creado_por__apellido__icontains=term)
        | Q(programa__nombre_programa__icontains=term)
        | q_text_icontains('objetivo_estrategico__descripcion', term, alt)
        | q_text_icontains('indicadores__descripcion', term, alt)
        | Q(etapas__nombre__icontains=term)
        | q_text_icontains('comentarios__texto', term, alt)
    )

    if not multi_word:
        term_q |= (
            Q(proyectoarea__area__nombre__icontains=term)
            | q_text_icontains('proyectoarea__area__descripcion', term, alt)
            | Q(proyectosecretaria_set__secretaria__nombre__icontains=term)
            | Q(proyectosecretaria_set__secretaria__codigo__icontains=term)
            | Q(equipo__usuario__nombre__icontains=term)
            | Q(equipo__usuario__apellido__icontains=term)
            | Q(tareas__titulo__icontains=term)
            | q_text_icontains('tareas__descripcion', term, alt)
        )
    else:
        tq = Q(titulo__icontains=term) | q_text_icontains('descripcion', term, alt)
        tareas_exist = Exists(Tarea.objects.filter(proyecto_id=OuterRef('pk')).filter(tq))

        pa_q = Q(area__nombre__icontains=term) | q_text_icontains('area__descripcion', term, alt)
        ps_q = Q(secretaria__nombre__icontains=term) | Q(secretaria__codigo__icontains=term)
        eq_q = Q(usuario__nombre__icontains=term) | Q(usuario__apellido__icontains=term)
        pa_exist = Exists(ProyectoArea.objects.filter(proyecto_id=OuterRef('pk')).filter(pa_q))
        ps_exist = Exists(ProyectoSecretaria.objects.filter(proyecto_id=OuterRef('pk')).filter(ps_q))
        eq_exist = Exists(ProyectoEquipo.objects.filter(proyecto_id=OuterRef('pk')).filter(eq_q))

        term_q |= pa_exist | ps_exist | eq_exist | tareas_exist

    if term.isdigit() and len(term) == 4:
        y = int(term)
        if 1900 <= y <= 2100:
            term_q |= (
                Q(fecha_inicio__year=y)
                | Q(fecha_fin_estimada__year=y)
                | Q(fecha_fin_real__year=y)
            )
    return term_q


def aplicar_busqueda_proyectos(qs, search: str):
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
        phrase_q |= Q(nombre__icontains=search_alt) | q_text_icontains('descripcion', search, search_alt)

    return dedupe_queryset_by_pk(qs.filter(q_and | phrase_q))
