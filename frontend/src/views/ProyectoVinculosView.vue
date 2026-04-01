<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, invalidateApiCache } from '@/services/api'
import { getProyecto } from '@/services/proyectos'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import { extraerMensajeError } from '@/utils/apiError'
import { formatFechaCorta } from '@/utils/fecha'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import { exportToCsv } from '@/utils/exportCsv'
import { flattenTasksTree, fetchAllTareasProyecto } from '@/utils/taskTree'
import PieChart from '@/components/PieChart.vue'
import BarChart from '@/components/BarChart.vue'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconEye from '@/components/icons/IconEye.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import { useAuth } from '@/composables/useAuth'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const { isVisualizador } = useAuth()
const { confirmDelete } = useConfirmDelete()

const proyectoId = computed(() => Number(route.params.id))
const carga = ref(true)
const cargaTareas = ref(false)
const errorCarga = ref('')
const proyecto = ref<Record<string, unknown> | null>(null)
const areasCat = ref<Record<string, unknown>[]>([])
const secretariasCat = ref<Record<string, unknown>[]>([])
const tareasFlat = ref<Record<string, unknown>[]>([])

const filtroDepKey = ref('')
const buscarTarea = ref('')

function nombreArea(id: number) {
  const a = areasCat.value.find((x) => (x.id as number) === id)
  return (a?.nombre as string) || `Área ${id}`
}

function nombreSec(id: number) {
  const s = secretariasCat.value.find((x) => (x.id as number) === id)
  return (s?.nombre as string) || `Secretaría ${id}`
}

const idsAreas = computed(() => {
  const p = proyecto.value
  if (!p) return []
  const raw = p.areas_asignadas_ids
  if (Array.isArray(raw) && raw.length) return raw.map((x) => Number(x))
  const a = p.area
  const aid = a != null && typeof a === 'object' && !Array.isArray(a) ? (a as { id?: number }).id : a
  return aid != null ? [Number(aid)] : []
})

const idsSecretarias = computed(() => {
  const p = proyecto.value
  if (!p) return []
  const raw = p.secretarias_asignadas_ids
  if (Array.isArray(raw) && raw.length) return raw.map((x) => Number(x))
  const s = p.secretaria
  const sid = s != null && typeof s === 'object' && !Array.isArray(s) ? (s as { id?: number }).id : s
  return sid != null ? [Number(sid)] : []
})

const opcionesFiltroDep = computed(() => {
  const opts: { key: string; label: string }[] = []
  for (const id of idsAreas.value) {
    opts.push({ key: `area:${id}`, label: `Área: ${nombreArea(id)}` })
  }
  for (const id of idsSecretarias.value) {
    opts.push({ key: `sec:${id}`, label: `Secretaría: ${nombreSec(id)}` })
  }
  return opts
})

const tareasFiltradas = computed(() => {
  let list = tareasFlat.value
  const q = buscarTarea.value.trim().toLowerCase()
  if (q) {
    list = list.filter((t) => String(t.titulo || '').toLowerCase().includes(q))
  }
  const fk = filtroDepKey.value
  if (!fk) return list
  const [tipo, idStr] = fk.split(':')
  const id = Number(idStr)
  if (!Number.isFinite(id)) return list
  return list.filter((t) => {
    if (tipo === 'area') {
      const aid = t.area
        ? typeof t.area === 'object'
          ? (t.area as { id: number }).id
          : Number(t.area)
        : null
      return aid === id
    }
    if (tipo === 'sec') {
      const sid = t.secretaria
        ? typeof t.secretaria === 'object'
          ? (t.secretaria as { id: number }).id
          : Number(t.secretaria)
        : null
      return sid === id
    }
    return true
  })
})

const gruposTareas = computed(() => {
  const map = new Map<string, Record<string, unknown>[]>()
  for (const t of tareasFiltradas.value) {
    const key = String(t.organizacion_nombre || 'Sin dependencia')
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(t)
  }
  return [...map.entries()].sort((a, b) => a[0].localeCompare(b[0], 'es'))
})

const avancePromedio = computed(() => {
  const list = tareasFiltradas.value
  if (!list.length) return 0
  const sum = list.reduce((s, t) => s + Number(t.porcentaje_avance ?? 0), 0)
  return Math.round((sum / list.length) * 100) / 100
})

const barrasPorEstado = computed(() => {
  const list = tareasFiltradas.value
  const n = list.length || 1
  const counts: Record<string, number> = {}
  for (const t of list) {
    const e = String(t.estado || '—')
    counts[e] = (counts[e] || 0) + 1
  }
  return Object.entries(counts).map(([label, c]) => ({
    label,
    value: Math.round((c / n) * 1000) / 10,
  }))
})

const barrasPorDependencia = computed(() => {
  const map = new Map<string, { sum: number; n: number }>()
  for (const t of tareasFiltradas.value) {
    const key = String(t.organizacion_nombre || 'Sin dependencia')
    const prev = map.get(key) || { sum: 0, n: 0 }
    prev.sum += Number(t.porcentaje_avance ?? 0)
    prev.n += 1
    map.set(key, prev)
  }
  return [...map.entries()]
    .map(([label, { sum, n }]) => ({
      label,
      value: n ? Math.round((sum / n) * 100) / 100 : 0,
    }))
    .sort((a, b) => b.value - a.value)
})

async function cargarTodo() {
  if (!Number.isFinite(proyectoId.value)) {
    errorCarga.value = 'Identificador de proyecto no válido.'
    carga.value = false
    return
  }
  carga.value = true
  errorCarga.value = ''
  try {
    const [proyRes, aRes, sRes] = await Promise.all([
      getProyecto(proyectoId.value),
      api.get('areas/').catch(() => ({ data: [] })),
      api.get('secretarias/').catch(() => ({ data: [] })),
    ])
    proyecto.value = proyRes.data as Record<string, unknown>
    areasCat.value = Array.isArray(aRes.data) ? aRes.data : []
    secretariasCat.value = Array.isArray(sRes.data) ? sRes.data : []
  } catch (e) {
    errorCarga.value = extraerMensajeError(e, 'No se pudo cargar el proyecto.')
    proyecto.value = null
    return
  } finally {
    carga.value = false
  }
  await cargarTareasLista()
}

async function cargarTareasLista() {
  cargaTareas.value = true
  try {
    tareasFlat.value = await fetchAllTareasProyecto(proyectoId.value)
  } catch {
    tareasFlat.value = []
    toast.error('No se pudieron cargar las tareas del proyecto.')
  } finally {
    cargaTareas.value = false
  }
}

function filasGrupo(tareasGrupo: Record<string, unknown>[]) {
  return flattenTasksTree(tareasGrupo)
}

function irVerTarea(tareaId: number) {
  router.push({
    path: '/tareas',
    query: { proyecto: String(proyectoId.value), ver: String(tareaId) },
  })
}

function irEditarTarea(tareaId: number) {
  router.push({
    path: '/tareas',
    query: { proyecto: String(proyectoId.value), editar: String(tareaId) },
  })
}

async function eliminarTarea(tareaId: number) {
  if (!(await confirmDelete())) return
  try {
    await api.delete(`tareas/${tareaId}/`)
    invalidateApiCache('tareas')
    toast.success('Tarea eliminada.')
    await cargarTareasLista()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'No se pudo eliminar la tarea.'))
  }
}

async function exportarExcel() {
  const headers = [
    'Dependencia',
    'Nivel',
    'Orden',
    'Título',
    'Estado',
    'Avance %',
    'Vencimiento',
    'Responsable',
  ]
  const rows: string[][] = []
  for (const [, tareasGrupo] of gruposTareas.value) {
    for (const { t, depth } of filasGrupo(tareasGrupo)) {
      rows.push([
        String(t.organizacion_nombre || ''),
        String(depth),
        String(t.orden ?? ''),
        String(t.titulo || ''),
        String(t.estado || ''),
        String(t.porcentaje_avance ?? ''),
        formatFechaCorta(t.fecha_vencimiento as string | undefined),
        String(t.responsable_nombre || ''),
      ])
    }
  }
  const slug = String(proyecto.value?.nombre || 'proyecto')
    .replace(/[^\w\s-]/g, '')
    .slice(0, 40)
  await exportToCsv(headers, rows, `vinculos-${slug}-${proyectoId.value}.xlsx`)
  toast.success('Archivo generado.')
}

function volverProyecto() {
  router.push(`/proyectos/${proyectoId.value}`)
}

onMounted(() => {
  void cargarTodo()
})

watch(proyectoId, () => {
  void cargarTodo()
})
</script>

<template>
  <div class="page vinculos-page">
    <nav class="nav-volver" aria-label="Navegación">
      <button type="button" class="btn-volver" @click="volverProyecto">← Volver al proyecto</button>
      <router-link to="/proyectos" class="btn-volver">← Volver al listado</router-link>
    </nav>

    <LoaderSpinner v-if="carga" texto="Cargando vínculos..." />

    <div v-else-if="errorCarga" class="state-error-box">
      <p>{{ errorCarga }}</p>
      <router-link to="/proyectos" class="link-inline">Ir a proyectos</router-link>
    </div>

    <template v-else-if="proyecto">
      <div class="page-hero">
        <h1>Vínculos del proyecto</h1>
        <p class="page-subtitle">{{ proyecto.nombre }}</p>
      </div>

      <div class="toolbar-vinculos">
        <div class="filtros-row">
          <label class="filtro-label">
            <span>Área o secretaría</span>
            <select v-model="filtroDepKey" class="input-select">
              <option value="">Todas</option>
              <option v-for="op in opcionesFiltroDep" :key="op.key" :value="op.key">{{ op.label }}</option>
            </select>
          </label>
          <label class="filtro-label grow">
            <span>Buscar en título</span>
            <input v-model="buscarTarea" type="search" class="input-search" placeholder="Texto en el título de la tarea…" />
          </label>
          <button type="button" class="btn-export" :disabled="!tareasFiltradas.length" @click="exportarExcel">
            <IconDownload class="btn-icon-sm" />
            Exportar Excel
          </button>
        </div>
      </div>

      <section class="charts-grid">
        <article class="chart-card">
          <h3>Avance promedio (tareas filtradas)</h3>
          <PieChart :value="Math.min(100, avancePromedio)" label="Promedio" :size="140" />
        </article>
        <article class="chart-card">
          <h3>Distribución por estado</h3>
          <BarChart v-if="barrasPorEstado.length" :items="barrasPorEstado" :max-items="8" bar-color="#6366f1" />
          <p v-else class="chart-empty">Sin datos</p>
        </article>
        <article class="chart-card chart-card-wide">
          <h3>Avance promedio por dependencia</h3>
          <BarChart v-if="barrasPorDependencia.length" :items="barrasPorDependencia" :max-items="16" />
          <p v-else class="chart-empty">Sin datos</p>
        </article>
      </section>

      <p v-if="proyecto.es_transversal" class="hint-banner">
        Proyecto transversal: las tareas se agrupan por área o secretaría. Use los filtros para acotar la vista.
      </p>
      <p class="hint-subtareas">
        Las <strong>subtareas</strong> se identifican con el símbolo ↳, la etiqueta «Subtarea» e indentación respecto a la tarea padre.
      </p>

      <LoaderSpinner v-if="cargaTareas" texto="Actualizando tareas..." />

      <div v-else-if="!gruposTareas.length" class="empty-deps">
        No hay tareas que coincidan con los filtros, o el proyecto aún no tiene tareas registradas.
      </div>

      <section v-for="([depNombre, tareasGrupo], gi) in gruposTareas" :key="'g-' + gi" class="bloque-dep">
        <h2 class="bloque-dep-titulo">{{ depNombre }}</h2>
        <div class="table-wrap">
          <table class="table tareas-vinculos-table">
            <thead>
              <tr>
                <th class="col-orden">Orden</th>
                <th class="col-titulo">Título</th>
                <th class="col-estado">Estado</th>
                <th class="col-avance">Avance</th>
                <th class="col-inicio">Fecha de inicio</th>
                <th class="col-dep">Área / Secretaría</th>
                <th class="col-venc">Vencimiento</th>
                <th v-if="!isVisualizador" class="col-acciones">Acciones</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="{ t, depth } in filasGrupo(tareasGrupo)"
                :key="'t-' + (t.id as number)"
                :class="[
                  'fila-tarea',
                  claseVencimiento(estadoVencimiento(t.fecha_vencimiento as string, t.estado as string)),
                  depth > 0 ? 'fila-subtarea' : '',
                ]"
              >
                <td class="col-orden">{{ t.orden ?? '—' }}</td>
                <td class="col-titulo">
                  <div
                    class="vinc-titulo-cell"
                    :class="{ 'vinc-titulo-es-sub': depth > 0 }"
                    :style="{ paddingLeft: `${12 + depth * 16}px` }"
                  >
                    <span v-if="depth > 0" class="vinc-subtarea-icon" aria-hidden="true">↳</span>
                    <span v-if="depth > 0" class="badge-subtarea-vinc">Subtarea</span>
                    <span class="vinc-titulo-texto">{{ t.titulo || '—' }}</span>
                  </div>
                </td>
                <td class="col-estado">{{ t.estado || '—' }}</td>
                <td class="col-avance">{{ Number(t.porcentaje_avance) ?? 0 }}%</td>
                <td class="col-inicio">{{ formatFechaCorta(t.fecha_inicio as string | undefined) }}</td>
                <td class="col-dep">{{ t.organizacion_nombre || '—' }}</td>
                <td class="col-venc">{{ formatFechaCorta(t.fecha_vencimiento as string | undefined) }}</td>
                <td v-if="!isVisualizador" class="col-acciones">
                  <button type="button" class="btn-mini btn-ver" title="Ver" @click="irVerTarea(t.id as number)">
                    <IconEye class="ico" /> Ver
                  </button>
                  <button type="button" class="btn-mini btn-edit" title="Editar" @click="irEditarTarea(t.id as number)">
                    <IconEdit class="ico" /> Editar
                  </button>
                  <button type="button" class="btn-mini btn-del" title="Eliminar" @click="eliminarTarea(t.id as number)">
                    <IconTrash class="ico" /> Eliminar
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.vinculos-page {
  max-width: 1200px;
}
.nav-volver {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 1rem;
}
.btn-volver {
  display: inline-flex;
  align-items: center;
  padding: 0.35rem 0.65rem;
  font-size: 0.9rem;
  color: #1d4ed8;
  background: transparent;
  border: none;
  cursor: pointer;
  text-decoration: underline;
  font-family: inherit;
}
.page-hero h1 {
  margin: 0 0 0.35rem;
  font-size: 1.35rem;
}
.page-subtitle {
  margin: 0 0 1rem;
  color: #475569;
}
.toolbar-vinculos {
  margin-bottom: 1.25rem;
}
.filtros-row {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-end;
}
.filtro-label {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  font-size: 0.85rem;
  color: #475569;
}
.filtro-label.grow {
  flex: 1;
  min-width: 200px;
}
.input-select,
.input-search {
  padding: 0.45rem 0.6rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.9rem;
}
.btn-export {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 0.85rem;
  border-radius: 8px;
  border: 1px solid #cbd5e1;
  background: #fff;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-export:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.charts-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1.5rem;
}
@media (max-width: 900px) {
  .charts-grid {
    grid-template-columns: 1fr;
  }
}
.chart-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
}
.chart-card-wide {
  grid-column: 1 / -1;
}
.chart-card h3 {
  margin: 0 0 0.75rem;
  font-size: 0.95rem;
  color: #0f172a;
}
.chart-empty {
  margin: 0;
  color: #94a3b8;
  font-size: 0.9rem;
}
.hint-banner {
  padding: 0.75rem 1rem;
  border-radius: 8px;
  background: #eef2ff;
  color: #312e81;
  font-size: 0.92rem;
  margin-bottom: 1rem;
}
.hint-subtareas {
  margin: -0.35rem 0 1rem;
  padding: 0.5rem 0.75rem;
  font-size: 0.82rem;
  color: #64748b;
  border-left: 3px solid #94a3b8;
  background: #f8fafc;
  border-radius: 0 6px 6px 0;
}
.state-error-box {
  padding: 1rem;
  border-radius: 8px;
  background: #fef2f2;
  color: #991b1b;
}
.link-inline {
  color: #1d4ed8;
}
.empty-deps {
  color: #64748b;
  padding: 1rem 0;
}
.bloque-dep {
  margin-bottom: 2rem;
}
.bloque-dep-titulo {
  margin: 0 0 0.65rem;
  font-size: 1.05rem;
  color: #0f172a;
}
.table-wrap {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}
.tareas-vinculos-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.88rem;
}
.tareas-vinculos-table th,
.tareas-vinculos-table td {
  padding: 0.5rem 0.65rem;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}
.tareas-vinculos-table th {
  background: #f8fafc;
  font-weight: 600;
  color: #334155;
}
.col-orden {
  width: 3.5rem;
}
.col-titulo {
  min-width: 180px;
}
.col-avance {
  width: 4rem;
}
.col-inicio {
  width: 6.5rem;
  white-space: nowrap;
}
.col-venc {
  width: 7rem;
}
.col-dep {
  min-width: 140px;
}
.col-acciones {
  width: 1%;
  white-space: nowrap;
}
.btn-mini {
  display: inline-flex;
  align-items: center;
  gap: 0.2rem;
  margin-right: 0.35rem;
  padding: 0.25rem 0.45rem;
  font-size: 0.75rem;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background: #fff;
  cursor: pointer;
}
.btn-mini .ico {
  width: 14px;
  height: 14px;
}
.btn-del {
  border-color: #fecaca;
  color: #b91c1c;
}
.fila-tarea.vencimiento-vencida {
  background: #fff7ed;
}
.fila-tarea.vencimiento-proxima {
  background: #fffbeb;
}
.fila-tarea.vencimiento-dentro-plazo {
  background: #f0fdf4;
}
.tareas-vinculos-table tr.fila-subtarea td {
  background: rgba(248, 250, 252, 0.97);
}
.tareas-vinculos-table tr.fila-subtarea:hover td {
  background: #f1f5f9;
}
.tareas-vinculos-table tr.fila-subtarea.fila-tarea.vencimiento-vencida td {
  background: rgba(255, 247, 237, 0.95);
}
.tareas-vinculos-table tr.fila-subtarea.fila-tarea.vencimiento-proxima td {
  background: rgba(255, 251, 235, 0.95);
}
.tareas-vinculos-table tr.fila-subtarea.fila-tarea.vencimiento-dentro-plazo td {
  background: rgba(240, 253, 244, 0.95);
}
.vinc-titulo-cell {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.35rem;
  line-height: 1.4;
}
.vinc-titulo-es-sub .vinc-titulo-texto {
  font-weight: 500;
  color: #334155;
}
.vinc-subtarea-icon {
  color: #64748b;
  font-size: 1rem;
  line-height: 1;
  flex-shrink: 0;
}
.badge-subtarea-vinc {
  display: inline-block;
  font-size: 0.62rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #475569;
  background: #e2e8f0;
  padding: 0.12rem 0.4rem;
  border-radius: 4px;
  flex-shrink: 0;
}
.vinc-titulo-texto {
  min-width: 0;
  flex: 1 1 120px;
}
</style>
