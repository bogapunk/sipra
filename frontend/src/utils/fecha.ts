/**
 * Fecha corta es-AR (día/mes/año). Evita desfase por UTC en strings YYYY-MM-DD.
 */
export function formatFechaCorta(value: string | null | undefined): string {
  if (value == null || value === '') return '—'
  const s = String(value).trim()
  const part = s.split('T')[0]
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(part)
  if (m) {
    const y = Number(m[1])
    const mo = Number(m[2])
    const d = Number(m[3])
    const dt = new Date(y, mo - 1, d)
    return dt.toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric' })
  }
  const parsed = new Date(s)
  if (!Number.isNaN(parsed.getTime())) {
    return parsed.toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric' })
  }
  return s
}

/** Fecha y hora para historiales y registros de auditoría (es-AR). */
export function formatFechaHora(value: string | null | undefined): string {
  if (value == null || value === '') return '—'
  const s = String(value).trim()
  const d = new Date(s)
  if (Number.isNaN(d.getTime())) return s
  return d.toLocaleString('es-AR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
