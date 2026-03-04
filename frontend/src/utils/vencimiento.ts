/**
 * Utilidad para determinar el estado de vencimiento de tareas y proyectos.
 * - vencida: fecha pasada (rojo)
 * - proxima: vence en los próximos 7 días (amarillo)
 * - dentro-plazo: vence en más de 7 días (verde)
 * - sin-fecha: sin fecha de vencimiento (neutral)
 */
export type EstadoVencimiento = 'vencida' | 'proxima' | 'dentro-plazo' | 'sin-fecha'

const DIAS_PROXIMA_VENCER = 7

/**
 * Parsea una fecha en formato ISO (YYYY-MM-DD) o similar.
 */
function parsearFecha(fecha: string | null | undefined): Date | null {
  if (!fecha || typeof fecha !== 'string') return null
  const d = new Date(fecha)
  return isNaN(d.getTime()) ? null : d
}

/**
 * Obtiene la fecha de hoy a medianoche (solo día, sin hora).
 */
function hoy(): Date {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  return d
}

/**
 * Determina el estado de vencimiento según la fecha.
 * Para tareas/proyectos finalizados se considera "dentro-plazo" (verde).
 */
export function estadoVencimiento(
  fecha: string | null | undefined,
  estado?: string | null
): EstadoVencimiento {
  if (estado === 'Finalizada' || estado === 'Finalizado') {
    return 'dentro-plazo'
  }
  const fechaDate = parsearFecha(fecha)
  if (!fechaDate) return 'sin-fecha'

  const hoyDate = hoy()
  fechaDate.setHours(0, 0, 0, 0)

  const limiteProximas = new Date(hoyDate)
  limiteProximas.setDate(limiteProximas.getDate() + DIAS_PROXIMA_VENCER)

  if (fechaDate < hoyDate) return 'vencida'
  if (fechaDate <= limiteProximas) return 'proxima'
  return 'dentro-plazo'
}

/**
 * Retorna la clase CSS para el indicador de vencimiento.
 */
export function claseVencimiento(estado: EstadoVencimiento): string {
  if (estado === 'sin-fecha') return ''
  return `vencimiento-${estado}`
}
