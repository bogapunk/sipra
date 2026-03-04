/**
 * Extrae mensaje de error legible desde la respuesta de la API (Django REST Framework).
 */
export function extraerMensajeError(err: unknown, fallback = 'Error de conexión'): string {
  const e = err as { response?: { data?: unknown; status?: number }; message?: string }
  const data = e.response?.data
  if (!data) return e.message || fallback
  if (typeof data === 'string') return data
  if (data && typeof data === 'object') {
    const obj = data as Record<string, unknown>
    if ('detail' in obj && obj.detail) return String(obj.detail)
    const mensajes: string[] = []
    for (const [k, v] of Object.entries(obj)) {
      if (Array.isArray(v)) mensajes.push(...v.map(String))
      else if (v) mensajes.push(String(v))
    }
    if (mensajes.length) return mensajes.join('. ')
  }
  return fallback
}
