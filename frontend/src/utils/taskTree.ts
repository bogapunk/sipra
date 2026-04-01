/** Utilidades compartidas para listados jerárquicos de tareas (panel proyectos / vínculos). */

import { api } from '@/services/api'

export function parseTareasApiList(data: unknown): Record<string, unknown>[] {
  if (Array.isArray(data)) return data as Record<string, unknown>[]
  if (data && typeof data === 'object' && 'results' in data) {
    const r = (data as { results?: unknown }).results
    return Array.isArray(r) ? (r as Record<string, unknown>[]) : []
  }
  return []
}

export interface TaskRowDepth {
  t: Record<string, unknown>
  depth: number
}

export function flattenTasksTree(flat: Record<string, unknown>[]): TaskRowDepth[] {
  const byPadre = new Map<number | null, Record<string, unknown>[]>()
  for (const t of flat) {
    let pid: number | null = null
    if (t.tarea_padre != null && t.tarea_padre !== '') {
      pid =
        typeof t.tarea_padre === 'object' && t.tarea_padre
          ? (t.tarea_padre as { id: number }).id
          : Number(t.tarea_padre)
    }
    if (!byPadre.has(pid)) byPadre.set(pid, [])
    byPadre.get(pid)!.push(t)
  }
  for (const arr of byPadre.values()) {
    arr.sort(
      (a, b) =>
        Number(a.orden ?? 0) - Number(b.orden ?? 0) || Number(a.id) - Number(b.id),
    )
  }
  const out: TaskRowDepth[] = []
  function walk(pid: number | null, depth: number) {
    for (const t of byPadre.get(pid) || []) {
      out.push({ t, depth })
      walk(t.id as number, depth + 1)
    }
  }
  walk(null, 0)
  return out
}

export async function fetchAllTareasProyecto(proyectoId: number): Promise<Record<string, unknown>[]> {
  const acum: Record<string, unknown>[] = []
  let page = 1
  while (true) {
    const res = await api.get('tareas/', { params: { proyecto: proyectoId, page, page_size: 200 } })
    const batch = parseTareasApiList(res.data)
    acum.push(...batch)
    const data = res.data as { next?: string | null }
    if (!data?.next || !batch.length) break
    page += 1
  }
  return acum
}
