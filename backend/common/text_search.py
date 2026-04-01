"""Búsqueda tolerante a mayúsculas en campos TextField bajo SQL Server.

En columnas TEXT/NTEXT legacy, T-SQL no admite UPPER(columna); Django usa UPPER para __icontains,
lo que provoca error 8116 y resultados vacíos. Aquí se usa __contains con variantes de texto.
"""
from django.db.models import Q


def q_text_icontains(field_path: str, term: str, alt: str) -> Q:
    """
    Equivale a icontains para texto largo sin aplicar UPPER al campo.
    `alt` es la variante sin tildes del término (puede igualar `term`).
    """
    if not (term or '').strip():
        return Q(pk__in=[])
    t = term.strip()
    q = Q(**{f'{field_path}__contains': t}) | Q(**{f'{field_path}__contains': t.lower()})
    if t.lower() != t.upper():
        q |= Q(**{f'{field_path}__contains': t.upper()})
    if alt and alt.strip() and alt != t:
        q |= Q(**{f'{field_path}__contains': alt.strip()})
    return q
