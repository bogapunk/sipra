/**
 * Asigna comentarios de tarea (ComentarioTarea) a cada registro de historial de avance
 * por ventanas de tiempo entre avances consecutivos (orden cronológico).
 * El último avance incluye también los comentarios posteriores a esa fecha.
 */

function ts(fecha: string | undefined | null): number {
  if (!fecha) return NaN
  const n = new Date(fecha).getTime()
  return Number.isFinite(n) ? n : NaN
}

export type ItemHistorial = { id: number; fecha: string }
export type ItemComentario = { id: number; fecha: string }

export function comentariosPorIdHistorial<T extends ItemComentario>(
  historial: ItemHistorial[],
  comentarios: T[]
): Map<number, T[]> {
  const map = new Map<number, T[]>()
  if (!historial.length) return map

  const A = [...historial]
    .filter((h) => h.id != null && h.fecha)
    .sort((a, b) => ts(a.fecha) - ts(b.fecha))

  const n = A.length
  for (const h of A) map.set(h.id, [])

  for (const c of comentarios) {
    const ct = ts(c.fecha)
    if (!Number.isFinite(ct)) continue

    for (let k = 0; k < n; k++) {
      const lower = k > 0 ? ts(A[k - 1].fecha) : -Infinity
      const tAvance = ts(A[k].fecha)
      if (!Number.isFinite(tAvance)) continue

      if (k < n - 1) {
        if (ct > lower && ct <= tAvance) {
          map.get(A[k].id)!.push(c)
          break
        }
      } else {
        if (ct > lower) {
          map.get(A[k].id)!.push(c)
        }
        break
      }
    }
  }

  for (const arr of map.values()) {
    arr.sort((a, b) => ts(a.fecha) - ts(b.fecha))
  }

  return map
}
