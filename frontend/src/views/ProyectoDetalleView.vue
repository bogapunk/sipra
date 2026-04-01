<script setup lang="ts">
import { ref, onMounted, onActivated, onDeactivated, onBeforeUnmount, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getProyecto } from '@/services/proyectos'
import { getTareas } from '@/services/tareas'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import PieChart from '@/components/PieChart.vue'
import BarChart from '@/components/BarChart.vue'
import { exportarProyectoDetalle } from '@/utils/exportProyectoDetalle'
import { extraerMensajeError } from '@/utils/apiError'
import { formatFechaCorta } from '@/utils/fecha'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const { user, isAdmin, isVisualizador } = useAuth()
const { confirmDelete } = useConfirmDelete()
const proyecto = ref<Record<string, unknown> | null>(null)
const areasCatalogo = ref<Record<string, unknown>[]>([])
const secretariasCatalogo = ref<Record<string, unknown>[]>([])
const carga = ref(true)
const errorCarga = ref('')
const tareas = ref<Record<string, unknown>[]>([])
const etapas = ref<Record<string, unknown>[]>([])
const indicadores = ref<Record<string, unknown>[]>([])
const adjuntos = ref<Record<string, unknown>[]>([])
const archivoProyecto = ref<HTMLInputElement | null>(null)
const subiendoAdjunto = ref(false)
const adjuntoEditando = ref<number | null>(null)
const nombreAdjuntoEditando = ref('')
const AUTO_REFRESH_MS = 12000
let autoRefreshTimer: ReturnType<typeof setInterval> | null = null
const modoOrden = ref(false)
const guardandoOrden = ref(false)
const draggedTaskId = ref<number | null>(null)
const dragOverTaskId = ref<number | null>(null)
const currencyFormatter = new Intl.NumberFormat('es-AR', {
  style: 'currency',
  currency: 'ARS',
  maximumFractionDigits: 2,
})

function puedeModificarAdjunto(a: Record<string, unknown>): boolean {
  if (!user.value) return false
  if (isAdmin.value) return true
  return (a.subido_por as number) === user.value.id
}

const proyectoId = computed(() => Number(route.params.id))

function parseListResponse(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

function formatCurrency(value: unknown): string {
  const amount = Number(value || 0)
  return currencyFormatter.format(Number.isFinite(amount) ? amount : 0)
}

/** Área o secretaría asignada a la tarea (API: organizacion_nombre o nombres sueltos). */
function dependenciaTarea(t: Record<string, unknown>): string {
  const o = t.organizacion_nombre
  if (typeof o === 'string' && o.trim()) return o.trim()
  const an = t.area_nombre
  const sn = t.secretaria_nombre
  if (typeof an === 'string' && an.trim()) return `Área: ${an.trim()}`
  if (typeof sn === 'string' && sn.trim()) return `Secretaría: ${sn.trim()}`
  return '—'
}

const load = async () => {
  const id = proyectoId.value
  carga.value = true
  errorCarga.value = ''
  try {
    const [proyRes, tareasRes, etapasRes, indRes, adjRes, areasRes, secRes] = await Promise.all([
      getProyecto(id),
      getTareas({ proyecto: id, _ts: Date.now() }),
      api.get('etapas/', { params: { proyecto: id } }),
      api.get('indicadores/', { params: { proyecto: id } }),
      api.get('adjuntos-proyecto/', { params: { proyecto: id } }),
      api.get('areas/').catch(() => ({ data: [] })),
      api.get('secretarias/').catch(() => ({ data: [] })),
    ])
    areasCatalogo.value = Array.isArray(areasRes.data) ? areasRes.data : []
    secretariasCatalogo.value = Array.isArray(secRes.data) ? secRes.data : []
    proyecto.value = proyRes.data as Record<string, unknown>
    tareas.value = parseListResponse(tareasRes.data)
    etapas.value = parseListResponse(etapasRes.data)
    indicadores.value = Array.isArray(indRes.data) ? indRes.data : (indRes.data?.results || [])
    adjuntos.value = Array.isArray(adjRes.data) ? adjRes.data : (adjRes.data?.results || [])
  } catch (e) {
    const err = e as { response?: { status?: number } }
    proyecto.value = null
    if (err.response?.status === 404) {
      errorCarga.value = 'Proyecto no encontrado.'
    } else {
      errorCarga.value = extraerMensajeError(e, 'No se pudo cargar el proyecto. Verifique la conexión.')
    }
  } finally {
    carga.value = false
  }
}

async function subirAdjuntoProyecto() {
  const input = archivoProyecto.value
  if (!proyecto.value || !input?.files?.length) return
  const file = input.files[0]
  if (!file) return
  subiendoAdjunto.value = true
  try {
    const formData = new FormData()
    formData.append('proyecto', String(proyectoId.value))
    formData.append('archivo', file)
    formData.append('nombre_original', file.name)
    await api.post('adjuntos-proyecto/', formData)
    const res = await api.get('adjuntos-proyecto/', { params: { proyecto: proyectoId.value } })
    adjuntos.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Archivo subido correctamente.')
    input.value = ''
  } catch {
    toast.error('Error al subir el archivo.')
  } finally {
    subiendoAdjunto.value = false
  }
}

function iniciarEdicionAdjunto(a: Record<string, unknown>) {
  adjuntoEditando.value = a.id as number
  nombreAdjuntoEditando.value = (a.nombre_original as string) || ''
}

function cancelarEdicionAdjunto() {
  adjuntoEditando.value = null
  nombreAdjuntoEditando.value = ''
}

async function guardarEdicionAdjunto() {
  const id = adjuntoEditando.value
  if (!id || !nombreAdjuntoEditando.value.trim()) return
  try {
    await api.patch(`adjuntos-proyecto/${id}/`, { nombre_original: nombreAdjuntoEditando.value.trim() })
    const res = await api.get('adjuntos-proyecto/', { params: { proyecto: proyectoId.value } })
    adjuntos.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    adjuntoEditando.value = null
    nombreAdjuntoEditando.value = ''
    toast.success('Adjunto actualizado.')
  } catch {
    toast.error('Error al actualizar el adjunto.')
  }
}

async function eliminarAdjunto(a: Record<string, unknown>) {
  if (!(await confirmDelete())) return
  try {
    await api.delete(`adjuntos-proyecto/${a.id}/`)
    const res = await api.get('adjuntos-proyecto/', { params: { proyecto: proyectoId.value } })
    adjuntos.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Adjunto eliminado.')
  } catch {
    toast.error('Error al eliminar el adjunto.')
  }
}

const tareasParaTabla = computed(() => {
  const lista = tareas.value
  const resultado: { tarea: Record<string, unknown>; esSubtarea: boolean; orden: string }[] = []
  const ordenar = (arr: Record<string, unknown>[]) =>
    [...arr].sort((a, b) => {
      const oa = Number(a.orden || 0)
      const ob = Number(b.orden || 0)
      if (oa !== ob) return oa - ob
      return Number(a.id || 0) - Number(b.id || 0)
    })
  const raices = ordenar(lista.filter((t: Record<string, unknown>) => !t.tarea_padre))
  let idx = 1
  for (const t of raices) {
    resultado.push({ tarea: t, esSubtarea: false, orden: String(idx) })
    const hijos = ordenar(((t.subtareas as Record<string, unknown>[]) || []))
    hijos.forEach((h, j) => {
      resultado.push({ tarea: h, esSubtarea: true, orden: `${idx}.${j + 1}` })
    })
    idx++
  }
  const idsIncluidos = new Set(resultado.map((r) => r.tarea.id))
  for (const t of lista) {
    if (t.tarea_padre && !idsIncluidos.has(t.id)) {
      resultado.push({ tarea: t, esSubtarea: true, orden: '—' })
    }
  }
  return resultado
})

function siblingsDeTarea(tarea: Record<string, unknown>) {
  const padreId = getParentId(tarea)
  return [...tareas.value]
    .filter((t) => {
      return getParentId(t) === padreId
    })
    .sort((a, b) => {
      const oa = Number(a.orden || 0)
      const ob = Number(b.orden || 0)
      if (oa !== ob) return oa - ob
      return Number(a.id || 0) - Number(b.id || 0)
    })
}

function getParentId(tarea: Record<string, unknown>) {
  const padreRaw = tarea.tarea_padre
  return padreRaw && typeof padreRaw === 'object'
    ? Number((padreRaw as { id?: number }).id || 0)
    : Number(padreRaw || 0)
}

function getTaskById(id: number) {
  return tareas.value.find((t) => Number(t.id) === id) || null
}

function onDragStart(tarea: Record<string, unknown>) {
  if (!modoOrden.value || isVisualizador.value || guardandoOrden.value) return
  draggedTaskId.value = Number(tarea.id)
}

function onDragEnd() {
  draggedTaskId.value = null
  dragOverTaskId.value = null
}

function onDragOver(tarea: Record<string, unknown>) {
  if (!modoOrden.value || isVisualizador.value || guardandoOrden.value) return
  dragOverTaskId.value = Number(tarea.id)
}

async function onDrop(targetTarea: Record<string, unknown>) {
  const movedId = draggedTaskId.value
  const targetId = Number(targetTarea.id)
  onDragEnd()
  if (!movedId || movedId === targetId || guardandoOrden.value) return

  const movedTask = getTaskById(movedId)
  const targetTask = getTaskById(targetId)
  if (!movedTask || !targetTask) return

  if (getParentId(movedTask) !== getParentId(targetTask)) {
    toast.error('Solo puede reordenar tareas dentro del mismo nivel.')
    return
  }

  const siblings = siblingsDeTarea(targetTask)
  const remaining = siblings.filter((s) => Number(s.id) !== movedId)
  const targetIndex = remaining.findIndex((s) => Number(s.id) === targetId)
  if (targetIndex < 0) return
  remaining.splice(targetIndex, 0, movedTask)

  const reordered = remaining
  const cambios = reordered
    .map((item, i) => ({ id: Number(item.id), orden: i + 1 }))
    .filter(({ id, orden }) => {
      const current = siblings.find((s) => Number(s.id) === id)
      return Number(current?.orden || 0) !== orden
    })
  if (!cambios.length) return
  guardandoOrden.value = true
  try {
    await Promise.all(cambios.map((c) => api.patch(`tareas/${c.id}/`, { orden: c.orden })))
    await actualizarTareasSilencioso()
    toast.success('Orden de tareas actualizado.')
  } catch {
    toast.error('No se pudo guardar el nuevo orden.')
  } finally {
    guardandoOrden.value = false
  }
}

const tareasPorVencimiento = computed(() => {
  const items = tareasParaTabla.value
  const vencidas: { tarea: Record<string, unknown>; esSubtarea: boolean; orden: string }[] = []
  const proximas: { tarea: Record<string, unknown>; esSubtarea: boolean; orden: string }[] = []
  const dentro: { tarea: Record<string, unknown>; esSubtarea: boolean; orden: string }[] = []
  for (const item of items) {
    const est = estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)
    if (est === 'vencida') vencidas.push(item)
    else if (est === 'proxima') proximas.push(item)
    else dentro.push(item)
  }
  return { vencidas, proximas, dentro }
})

const dependenciasListado = computed(() => {
  const p = proyecto.value
  if (!p) {
    return { areas: [] as { id: number; nombre: string }[], secretarias: [] as { id: number; nombre: string }[] }
  }
  const areaIds = new Set<number>()
  const idsRaw = p.areas_asignadas_ids
  if (Array.isArray(idsRaw)) {
    idsRaw.forEach((x) => {
      const n = Number(x)
      if (Number.isFinite(n)) areaIds.add(n)
    })
  }
  const secIds = new Set<number>()
  const secRaw = p.secretarias_asignadas_ids
  if (Array.isArray(secRaw)) {
    secRaw.forEach((x) => {
      const n = Number(x)
      if (Number.isFinite(n)) secIds.add(n)
    })
  }
  const areas = [...areaIds].map((id) => {
    const row = areasCatalogo.value.find((a) => Number(a.id) === id)
    return { id, nombre: String(row?.nombre || `Área ${id}`) }
  })
  const secretarias = [...secIds].map((id) => {
    const row = secretariasCatalogo.value.find((s) => Number(s.id) === id)
    const codigo = row ? String(row.codigo || '').trim() : ''
    const nombre = row ? String(row.nombre || '').trim() : ''
    const label = codigo && nombre ? `${codigo} — ${nombre}` : (nombre || codigo || `Secretaría ${id}`)
    return { id, nombre: label }
  })
  return { areas, secretarias }
})

const tieneDependenciasDetalle = computed(() => {
  const d = dependenciasListado.value
  return d.areas.length > 0 || d.secretarias.length > 0
})

const avanceGeneral = computed(() => Number(proyecto.value?.porcentaje_avance) || 0)
const presupuestoItems = computed(() => {
  const items = proyecto.value?.presupuesto_items
  return Array.isArray(items) ? (items as Record<string, unknown>[]) : []
})
const presupuestoTotal = computed(() => Number(proyecto.value?.presupuesto_total) || 0)
const presupuestoCargado = computed(() => Number(proyecto.value?.presupuesto_cargado) || 0)
const presupuestoDisponible = computed(() => Math.max(0, presupuestoTotal.value - presupuestoCargado.value))
const presupuestoEjecutadoPct = computed(() => {
  if (!presupuestoTotal.value) return 0
  return Math.max(0, Math.min(100, Math.round((presupuestoCargado.value / presupuestoTotal.value) * 100)))
})

const datosBarChart = computed(() => {
  const items = tareasParaTabla.value
  return items.map((item) => ({
    label: (item.tarea.titulo as string) || 'Sin título',
    value: Number(item.tarea.porcentaje_avance) || 0,
  }))
})

const datosSemáforo = computed(() => ({
  vencidas: tareasPorVencimiento.value.vencidas.length,
  proximas: tareasPorVencimiento.value.proximas.length,
  dentro: tareasPorVencimiento.value.dentro.length,
}))

const totalTareasSemáforo = computed(() => {
  const d = datosSemáforo.value
  return d.vencidas + d.proximas + d.dentro
})

async function exportarExcel() {
  if (!proyecto.value) return
  try {
    await exportarProyectoDetalle(
      {
        nombre: proyecto.value.nombre as string,
        descripcion: proyecto.value.descripcion as string,
        estado: proyecto.value.estado as string,
        porcentaje_avance: Number(proyecto.value.porcentaje_avance) || 0,
        presupuesto_total: Number(proyecto.value.presupuesto_total) || 0,
        fuente_financiamiento: proyecto.value.fuente_financiamiento as string,
        presupuesto_cargado: presupuestoCargado.value,
        presupuesto_disponible: presupuestoDisponible.value,
      },
      etapas.value as { id: number; nombre: string; orden?: number }[],
      indicadores.value as { id: number; descripcion?: string; unidad_medida?: string; frecuencia?: string }[],
      tareasParaTabla.value.map((item) => ({
        tarea: item.tarea,
        esSubtarea: item.esSubtarea,
        orden: item.orden,
      })),
      presupuestoItems.value.map((item, index) => ({
        id: item.id as number | undefined,
        categoria_gasto: item.categoria_gasto as string | undefined,
        monto: Number(item.monto) || 0,
        detalle: item.detalle as string | undefined,
        orden: (item.orden as number | undefined) ?? index + 1,
      })),
      `proyecto_${String(proyecto.value.nombre || 'proyecto').replace(/[<>:"/\\|?*]/g, '_').replace(/\s+/g, '_').trim().slice(0, 80) || proyectoId}`
    )
    toast.success('Exportado correctamente.')
  } catch {
    toast.error('Error al exportar.')
  }
}

async function actualizarTareas() {
  try {
    const res = await getTareas({ proyecto: proyectoId.value, _ts: Date.now() })
    tareas.value = parseListResponse(res.data)
    toast.success('Tareas actualizadas.')
  } catch {
    toast.error('No se pudieron actualizar las tareas.')
  }
}

async function actualizarTareasSilencioso() {
  try {
    const res = await getTareas({ proyecto: proyectoId.value, _ts: Date.now() })
    tareas.value = parseListResponse(res.data)
  } catch {
    // Sin ruido visual: es auto-refresh.
  }
}

function recargarAlVolver() {
  void load()
}

function onVisibilityChange() {
  if (document.visibilityState === 'visible') {
    void actualizarTareasSilencioso()
  }
}

function startAutoRefresh() {
  stopAutoRefresh()
  autoRefreshTimer = setInterval(() => {
    if (document.visibilityState === 'visible') {
      void actualizarTareasSilencioso()
    }
  }, AUTO_REFRESH_MS)
}

function stopAutoRefresh() {
  if (autoRefreshTimer) {
    clearInterval(autoRefreshTimer)
    autoRefreshTimer = null
  }
}

onMounted(() => {
  void load()
  window.addEventListener('focus', recargarAlVolver)
  document.addEventListener('visibilitychange', onVisibilityChange)
  startAutoRefresh()
})
onActivated(() => {
  void load()
  startAutoRefresh()
})
onDeactivated(() => {
  stopAutoRefresh()
})
onBeforeUnmount(() => {
  window.removeEventListener('focus', recargarAlVolver)
  document.removeEventListener('visibilitychange', onVisibilityChange)
  stopAutoRefresh()
})
watch(proyectoId, () => {
  void load()
})
</script>

<template>
  <LoaderSpinner v-if="carga" texto="Cargando proyecto..." />
  <div v-else-if="errorCarga" class="page state-error-box">
    <p class="state-error-msg">{{ errorCarga }}</p>
    <button type="button" class="btn-volver" @click="router.push('/proyectos')">
      Volver a Proyectos
    </button>
  </div>
  <div v-else-if="proyecto" class="page">
    <nav class="nav-volver" aria-label="Volver al listado">
      <router-link to="/proyectos" class="btn-volver-proyectos">
        ← Volver a Proyectos
      </router-link>
    </nav>
    <div class="header-row">
      <h1>{{ proyecto.nombre }}</h1>
      <div class="header-actions">
        <button type="button" class="btn-actualizar" @click="actualizarTareas">
          Actualizar tareas
        </button>
        <button type="button" class="btn-exportar" @click="exportarExcel">
          <IconDownload class="btn-icon" />
          Exportar a Excel
        </button>
        <router-link :to="`/proyectos/${proyectoId}/reasignar`" class="btn-reasignar">
          Reasignar Proyecto
        </router-link>
        <router-link
          v-if="proyecto.es_transversal"
          :to="`/proyectos/${proyectoId}/vinculos`"
          class="btn-reasignar"
        >
          Panel de vínculos
        </router-link>
      </div>
    </div>
    <p class="desc">{{ proyecto.descripcion }}</p>
    <p><strong>Estado:</strong> {{ proyecto.estado }} | <strong>Avance general:</strong> {{ avanceGeneral.toFixed(2) }}%</p>

    <section v-if="tieneDependenciasDetalle" class="section asignaciones-detalle-section">
      <h2>Dependencias organizacionales</h2>
      <p class="hint asignaciones-detalle-hint">
        Listado de áreas y secretarías a las que está vinculado este proyecto (incluye alcance transversal con varias dependencias).
      </p>
      <div v-if="dependenciasListado.areas.length" class="asignaciones-detalle-bloque">
        <h3>Áreas</h3>
        <ul class="asignaciones-detalle-lista">
          <li v-for="a in dependenciasListado.areas" :key="'area-' + a.id">
            <span class="asignaciones-detalle-badge badge-area">{{ a.nombre }}</span>
          </li>
        </ul>
      </div>
      <div v-if="dependenciasListado.secretarias.length" class="asignaciones-detalle-bloque">
        <h3>Secretarías</h3>
        <ul class="asignaciones-detalle-lista">
          <li v-for="s in dependenciasListado.secretarias" :key="'sec-' + s.id">
            <span class="asignaciones-detalle-badge badge-secretaria">{{ s.nombre }}</span>
          </li>
        </ul>
      </div>
    </section>

    <section class="section presupuesto-section">
      <h2>Detalle presupuestario</h2>
      <div class="presupuesto-layout">
        <div class="presupuesto-chart-card">
          <h3 class="grafico-titulo">Ejecución presupuestaria</h3>
          <PieChart :value="presupuestoEjecutadoPct" label="Ejecutado" :size="150" />
          <p class="presupuesto-chart-meta">
            {{ formatCurrency(presupuestoCargado) }} de {{ formatCurrency(presupuestoTotal) }}
          </p>
        </div>
        <div class="presupuesto-resumen-grid">
          <div class="presupuesto-card">
            <span class="presupuesto-label">Presupuesto total</span>
            <strong class="presupuesto-value">{{ formatCurrency(presupuestoTotal) }}</strong>
          </div>
          <div class="presupuesto-card">
            <span class="presupuesto-label">Fuente de financiamiento</span>
            <strong class="presupuesto-value presupuesto-value-text">{{ proyecto.fuente_financiamiento || '-' }}</strong>
          </div>
          <div class="presupuesto-card">
            <span class="presupuesto-label">Total gastos</span>
            <strong class="presupuesto-value">{{ formatCurrency(presupuestoCargado) }}</strong>
          </div>
          <div class="presupuesto-card">
            <span class="presupuesto-label">Disponible</span>
            <strong class="presupuesto-value">{{ formatCurrency(presupuestoDisponible) }}</strong>
          </div>
        </div>
      </div>
      <div v-if="presupuestoItems.length" class="presupuesto-gastos-lista">
        <article
          v-for="(item, index) in presupuestoItems"
          :key="(item.id as number) || `presupuesto-${index}`"
          class="presupuesto-gasto-card"
        >
          <div class="presupuesto-gasto-head">
            <strong>{{ item.categoria_gasto || `Gasto ${index + 1}` }}</strong>
            <span>{{ formatCurrency(item.monto) }}</span>
          </div>
          <p class="presupuesto-gasto-detalle">
            {{ item.detalle || 'Sin detalle cargado.' }}
          </p>
        </article>
      </div>
      <p v-else class="hint">No hay gastos presupuestarios cargados para este proyecto.</p>
    </section>

    <!-- Gráficos de resumen -->
    <section class="section graficos-section">
      <h2>Resumen visual</h2>
      <div class="graficos-grid">
        <div class="grafico-card">
          <h3 class="grafico-titulo">Avance general</h3>
          <PieChart :value="avanceGeneral" label="Avance" :size="140" />
        </div>
        <div class="grafico-card">
          <h3 class="grafico-titulo">Avance por tarea</h3>
          <BarChart v-if="datosBarChart.length" :items="datosBarChart" :max-items="10" />
          <p v-else class="hint">Sin tareas para mostrar</p>
        </div>
        <div class="grafico-card grafico-semáforo">
          <h3 class="grafico-titulo">Tareas por vencimiento</h3>
          <div v-if="totalTareasSemáforo" class="semáforo-bars">
            <div class="semáforo-item">
              <span class="semáforo-label">Vencida</span>
              <div class="semáforo-bar-wrap">
                <div class="semáforo-bar vencida" :style="{ width: (datosSemáforo.vencidas / totalTareasSemáforo * 100) + '%' }"></div>
              </div>
              <span class="semáforo-val">{{ datosSemáforo.vencidas }}</span>
            </div>
            <div class="semáforo-item">
              <span class="semáforo-label">Próxima a vencer</span>
              <div class="semáforo-bar-wrap">
                <div class="semáforo-bar proxima" :style="{ width: (datosSemáforo.proximas / totalTareasSemáforo * 100) + '%' }"></div>
              </div>
              <span class="semáforo-val">{{ datosSemáforo.proximas }}</span>
            </div>
            <div class="semáforo-item">
              <span class="semáforo-label">Dentro del plazo</span>
              <div class="semáforo-bar-wrap">
                <div class="semáforo-bar dentro" :style="{ width: (datosSemáforo.dentro / totalTareasSemáforo * 100) + '%' }"></div>
              </div>
              <span class="semáforo-val">{{ datosSemáforo.dentro }}</span>
            </div>
          </div>
          <p v-else class="hint">Sin tareas</p>
        </div>
      </div>
    </section>

    <section class="section">
      <ul class="list">
        <li v-for="e in etapas" :key="(e.id as number)">{{ e.nombre }} (orden: {{ e.orden }})</li>
      </ul>
    </section>

    <section v-if="indicadores.length" class="section">
      <ul class="list indicadores-list">
        <li v-for="i in indicadores" :key="(i.id as number)" class="indicador-item">
          <span>{{ i.descripcion }}</span>
          <span class="meta">{{ i.unidad_medida }} · {{ i.frecuencia }}</span>
        </li>
      </ul>
    </section>

    <section class="section">
      <h2>Adjuntos</h2>
      <div v-if="adjuntos.length" class="adjuntos-lista">
        <div v-for="a in adjuntos" :key="(a.id as number)" class="adjunto-item">
          <template v-if="adjuntoEditando === a.id">
            <input v-model="nombreAdjuntoEditando" type="text" class="adjunto-edit-input" />
            <div class="adjunto-edit-btns">
              <button type="button" class="btn-small" @click="guardarEdicionAdjunto">Guardar</button>
              <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionAdjunto">Cancelar</button>
            </div>
          </template>
          <template v-else>
            <a v-if="a.url" :href="a.url" target="_blank" rel="noopener" class="adjunto-link">📎 {{ a.nombre_original }}</a>
            <span v-else>📎 {{ a.nombre_original }}</span>
            <div v-if="puedeModificarAdjunto(a)" class="adjunto-acciones">
              <button type="button" class="btn-icon-mini" title="Editar nombre" @click="iniciarEdicionAdjunto(a)"><IconEdit class="btn-icon-sm" /></button>
              <button type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarAdjunto(a)"><IconTrash class="btn-icon-sm" /></button>
            </div>
          </template>
        </div>
      </div>
      <div class="adjunto-upload">
        <input ref="archivoProyecto" type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.png,.jpg,.jpeg" @change="subirAdjuntoProyecto" />
        <span v-if="subiendoAdjunto" class="adjunto-loading">Subiendo...</span>
      </div>
    </section>

    <section class="section">
      <h2>Tareas</h2>
      <div class="orden-actions" v-if="!isVisualizador">
        <button type="button" class="btn-orden" @click="modoOrden = !modoOrden">
          {{ modoOrden ? 'Finalizar ordenamiento' : 'Acomodar orden' }}
        </button>
      </div>
      <div class="vencimiento-leyenda">
        <span class="leyenda-item vencida">Vencida</span>
        <span class="leyenda-item proxima">Próxima a vencer (7 días)</span>
        <span class="leyenda-item dentro">Dentro del plazo</span>
      </div>

      <div v-if="tareasPorVencimiento.vencidas.length" class="tareas-grupo tareas-vencidas">
        <h3 class="grupo-titulo">Vencida</h3>
        <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th class="col-orden">Orden</th>
              <th>Título</th>
              <th>Estado</th>
              <th class="col-avance">Avance</th>
              <th class="col-fecha">Fecha de inicio</th>
              <th class="col-organizacion">Área / Secretaría</th>
              <th class="col-fecha">Fecha de vencimiento</th>
              <th class="col-acciones">Acciones</th>
              <th v-if="modoOrden && !isVisualizador">Reordenar</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in tareasPorVencimiento.vencidas"
              :key="(item.tarea.id as number)"
              :draggable="modoOrden && !isVisualizador"
              @dragstart="onDragStart(item.tarea)"
              @dragend="onDragEnd"
              @dragover.prevent="onDragOver(item.tarea)"
              @drop.prevent="onDrop(item.tarea)"
              :class="[claseVencimiento(estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)), item.esSubtarea ? 'row-subtarea' : '', modoOrden && dragOverTaskId === Number(item.tarea.id) && draggedTaskId !== Number(item.tarea.id) ? 'drag-over-row' : '']"
            >
              <td class="col-orden">{{ item.orden }}</td>
              <td :class="{ 'cell-indent': item.esSubtarea }">
                <div class="detalle-titulo-tarea">
                  <span v-if="item.esSubtarea" class="subtarea-icon">↳</span>
                  <span v-if="item.esSubtarea" class="badge-subtarea-detalle">Subtarea</span>
                  <span :class="{ 'titulo-con-sub': item.esSubtarea }">{{ item.tarea.titulo }}</span>
                </div>
              </td>
              <td>{{ item.tarea.estado }}</td>
              <td class="col-avance">{{ item.tarea.porcentaje_avance }}%</td>
              <td class="col-fecha">{{ formatFechaCorta(item.tarea.fecha_inicio as string | undefined) }}</td>
              <td class="col-organizacion">{{ dependenciaTarea(item.tarea) }}</td>
              <td>
                <span v-if="item.tarea.fecha_vencimiento" class="vencimiento-badge" :class="'vencimiento-badge-' + estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)">
                  {{ formatFechaCorta(item.tarea.fecha_vencimiento as string | undefined) }}
                </span>
                <span v-else class="vencimiento-sin">—</span>
              </td>
              <td class="col-acciones">
                <router-link :to="`/tareas?ver=${item.tarea.id}`" class="btn-ver-detalle">Ver detalle</router-link>
              </td>
              <td v-if="modoOrden && !isVisualizador" class="orden-col">
                <span class="drag-handle" title="Arrastrar para reordenar">↕ Arrastrar</span>
              </td>
            </tr>
          </tbody>
        </table>
        </div>
      </div>

      <div v-if="tareasPorVencimiento.proximas.length" class="tareas-grupo tareas-proximas">
        <h3 class="grupo-titulo">Próxima a vencer (7 días)</h3>
        <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th class="col-orden">Orden</th>
              <th>Título</th>
              <th>Estado</th>
              <th class="col-avance">Avance</th>
              <th class="col-fecha">Fecha de inicio</th>
              <th class="col-organizacion">Área / Secretaría</th>
              <th class="col-fecha">Fecha de vencimiento</th>
              <th class="col-acciones">Acciones</th>
              <th v-if="modoOrden && !isVisualizador">Reordenar</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in tareasPorVencimiento.proximas"
              :key="(item.tarea.id as number)"
              :draggable="modoOrden && !isVisualizador"
              @dragstart="onDragStart(item.tarea)"
              @dragend="onDragEnd"
              @dragover.prevent="onDragOver(item.tarea)"
              @drop.prevent="onDrop(item.tarea)"
              :class="[claseVencimiento(estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)), item.esSubtarea ? 'row-subtarea' : '', modoOrden && dragOverTaskId === Number(item.tarea.id) && draggedTaskId !== Number(item.tarea.id) ? 'drag-over-row' : '']"
            >
              <td class="col-orden">{{ item.orden }}</td>
              <td :class="{ 'cell-indent': item.esSubtarea }">
                <div class="detalle-titulo-tarea">
                  <span v-if="item.esSubtarea" class="subtarea-icon">↳</span>
                  <span v-if="item.esSubtarea" class="badge-subtarea-detalle">Subtarea</span>
                  <span :class="{ 'titulo-con-sub': item.esSubtarea }">{{ item.tarea.titulo }}</span>
                </div>
              </td>
              <td>{{ item.tarea.estado }}</td>
              <td class="col-avance">{{ item.tarea.porcentaje_avance }}%</td>
              <td class="col-fecha">{{ formatFechaCorta(item.tarea.fecha_inicio as string | undefined) }}</td>
              <td class="col-organizacion">{{ dependenciaTarea(item.tarea) }}</td>
              <td>
                <span v-if="item.tarea.fecha_vencimiento" class="vencimiento-badge" :class="'vencimiento-badge-' + estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)">
                  {{ formatFechaCorta(item.tarea.fecha_vencimiento as string | undefined) }}
                </span>
                <span v-else class="vencimiento-sin">—</span>
              </td>
              <td class="col-acciones">
                <router-link :to="`/tareas?ver=${item.tarea.id}`" class="btn-ver-detalle">Ver detalle</router-link>
              </td>
              <td v-if="modoOrden && !isVisualizador" class="orden-col">
                <span class="drag-handle" title="Arrastrar para reordenar">↕ Arrastrar</span>
              </td>
            </tr>
          </tbody>
        </table>
        </div>
      </div>

      <div v-if="tareasPorVencimiento.dentro.length" class="tareas-grupo tareas-dentro">
        <h3 class="grupo-titulo">Dentro del plazo</h3>
        <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th class="col-orden">Orden</th>
              <th>Título</th>
              <th>Estado</th>
              <th class="col-avance">Avance</th>
              <th class="col-fecha">Fecha de inicio</th>
              <th class="col-organizacion">Área / Secretaría</th>
              <th class="col-fecha">Fecha de vencimiento</th>
              <th class="col-acciones">Acciones</th>
              <th v-if="modoOrden && !isVisualizador">Reordenar</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in tareasPorVencimiento.dentro"
              :key="(item.tarea.id as number)"
              :draggable="modoOrden && !isVisualizador"
              @dragstart="onDragStart(item.tarea)"
              @dragend="onDragEnd"
              @dragover.prevent="onDragOver(item.tarea)"
              @drop.prevent="onDrop(item.tarea)"
              :class="[claseVencimiento(estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)), item.esSubtarea ? 'row-subtarea' : '', modoOrden && dragOverTaskId === Number(item.tarea.id) && draggedTaskId !== Number(item.tarea.id) ? 'drag-over-row' : '']"
            >
              <td class="col-orden">{{ item.orden }}</td>
              <td :class="{ 'cell-indent': item.esSubtarea }">
                <div class="detalle-titulo-tarea">
                  <span v-if="item.esSubtarea" class="subtarea-icon">↳</span>
                  <span v-if="item.esSubtarea" class="badge-subtarea-detalle">Subtarea</span>
                  <span :class="{ 'titulo-con-sub': item.esSubtarea }">{{ item.tarea.titulo }}</span>
                </div>
              </td>
              <td>{{ item.tarea.estado }}</td>
              <td class="col-avance">{{ item.tarea.porcentaje_avance }}%</td>
              <td class="col-fecha">{{ formatFechaCorta(item.tarea.fecha_inicio as string | undefined) }}</td>
              <td class="col-organizacion">{{ dependenciaTarea(item.tarea) }}</td>
              <td>
                <span v-if="item.tarea.fecha_vencimiento" class="vencimiento-badge" :class="'vencimiento-badge-' + estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)">
                  {{ formatFechaCorta(item.tarea.fecha_vencimiento as string | undefined) }}
                </span>
                <span v-else class="vencimiento-sin">—</span>
              </td>
              <td class="col-acciones">
                <router-link :to="`/tareas?ver=${item.tarea.id}`" class="btn-ver-detalle">Ver detalle</router-link>
              </td>
              <td v-if="modoOrden && !isVisualizador" class="orden-col">
                <span class="drag-handle" title="Arrastrar para reordenar">↕ Arrastrar</span>
              </td>
            </tr>
          </tbody>
        </table>
        </div>
      </div>

      <p v-if="!tareasParaTabla.length" class="hint">Sin tareas en este proyecto.</p>
    </section>
  </div>
</template>

<style scoped>
.nav-volver {
  margin-bottom: 0.75rem;
}
.btn-volver-proyectos {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.45rem 0.95rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: #1e40af;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  text-decoration: none;
  transition: background 0.15s ease, color 0.15s ease;
}
.btn-volver-proyectos:hover {
  background: #dbeafe;
  color: #1d4ed8;
}
.header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
}
.page h1 { margin: 0; }
.state-error-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 2rem;
  text-align: center;
}
.state-error-msg {
  color: #b91c1c;
  font-size: 1rem;
  margin: 0;
}
.btn-volver {
  padding: 0.6rem 1.2rem;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}
.btn-volver:hover { background: #1d4ed8; }
.btn-reasignar {
  padding: 0.5rem 1rem;
  background: #16a34a;
  color: white;
  border-radius: 8px;
  text-decoration: none;
  font-size: 0.9rem;
}
.btn-reasignar:hover {
  background: #15803d;
}
.desc { color: #64748b; margin-bottom: 1rem; }
.section { margin-top: 1.5rem; }
.section h2 { font-size: 1rem; margin-bottom: 0.5rem; }
.list { list-style: none; }
.list li { padding: 0.25rem 0; }
.table { width: 100%; border-collapse: collapse; }
.table th, .table td { padding: 0.5rem; text-align: left; }
.table th.col-avance,
.table td.col-avance { text-align: center; }
.table th.col-fecha,
.table td.col-fecha { white-space: nowrap; font-size: 0.9rem; }
.table th.col-organizacion,
.table td.col-organizacion { font-size: 0.88rem; max-width: 14rem; line-height: 1.35; }
.section .btn-primary {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  margin-bottom: 0.5rem;
}
.indicadores-list { list-style: none; padding: 0; }
.indicador-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #e2e8f0;
}
.indicador-item .meta { color: #64748b; font-size: 0.9rem; }
.hint { color: #94a3b8; font-size: 0.9rem; }
.vencimiento-leyenda {
  display: flex;
  gap: 1rem;
  margin-bottom: 0.75rem;
  font-size: 0.8rem;
  color: #64748b;
}
.leyenda-item {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}
.leyenda-item::before {
  content: '';
  width: 12px;
  height: 12px;
  border-radius: 3px;
}
.leyenda-item.vencida::before { background: #dc2626; }
.leyenda-item.proxima::before { background: #eab308; }
.leyenda-item.dentro::before { background: #22c55e; }
.vencimiento-vencida { background-color: #fef2f2 !important; border-left: 4px solid #dc2626; }
.vencimiento-proxima { background-color: #fffbeb !important; border-left: 4px solid #eab308; }
.vencimiento-dentro-plazo { background-color: #f0fdf4 !important; border-left: 4px solid #22c55e; }
.vencimiento-badge {
  display: inline-block;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 500;
}
.vencimiento-badge-vencida { background: #fecaca; color: #b91c1c; }
.vencimiento-badge-proxima { background: #fef08a; color: #a16207; }
.vencimiento-badge-dentro-plazo { background: #bbf7d0; color: #15803d; }
.vencimiento-sin { color: #94a3b8; }
.row-subtarea { background-color: rgba(248, 250, 252, 0.8); }
.cell-indent { padding-left: 2rem !important; }
.detalle-titulo-tarea {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.35rem;
  line-height: 1.35;
}
.subtarea-icon { color: #64748b; font-size: 0.95rem; flex-shrink: 0; }
.badge-subtarea-detalle {
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
.titulo-con-sub {
  font-weight: 500;
  color: #334155;
}
.tareas-grupo { margin-bottom: 1.5rem; }
.tareas-grupo:last-of-type { margin-bottom: 0; }
.grupo-titulo {
  font-size: 0.95rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: #334155;
}
.tareas-vencidas .grupo-titulo { color: #b91c1c; }
.tareas-proximas .grupo-titulo { color: #a16207; }
.tareas-dentro .grupo-titulo { color: #15803d; }
.col-orden { width: 4rem; text-align: center; font-weight: 600; }
.orden-actions { margin: 0.5rem 0; }
.btn-orden {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.45rem 0.8rem;
  background: #1d4ed8;
  color: #fff;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
}
.btn-orden:hover { background: #1e40af; }
.orden-col { white-space: nowrap; }
.btn-mini {
  border: none;
  background: #e2e8f0;
  color: #1f2937;
  padding: 0.2rem 0.45rem;
  border-radius: 4px;
  margin-right: 0.25rem;
  cursor: pointer;
}
.btn-mini:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.drag-handle {
  display: inline-flex;
  align-items: center;
  padding: 0.2rem 0.5rem;
  background: #e2e8f0;
  border-radius: 4px;
  font-size: 0.8rem;
  color: #334155;
  cursor: grab;
  user-select: none;
}
.drag-over-row {
  outline: 2px dashed #1d4ed8;
  outline-offset: -2px;
}

.header-actions { display: flex; gap: 0.75rem; align-items: center; flex-wrap: wrap; }
.btn-exportar {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 1rem;
  background: #0ea5e9;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  text-decoration: none;
}
.btn-exportar:hover { background: #0284c7; }
.btn-actualizar {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 1rem;
  background: #475569;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
}
.btn-actualizar:hover { background: #334155; }
.btn-icon { width: 1rem; height: 1rem; }

.asignaciones-detalle-section {
  margin-top: 1.5rem;
  padding: 1.1rem 1.2rem;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
}
.asignaciones-detalle-section h2 { margin: 0 0 0.5rem; font-size: 1.15rem; }
.asignaciones-detalle-hint { margin: 0 0 1rem; color: #64748b; font-size: 0.9rem; }
.asignaciones-detalle-bloque { margin-bottom: 1rem; }
.asignaciones-detalle-bloque:last-child { margin-bottom: 0; }
.asignaciones-detalle-bloque h3 {
  margin: 0 0 0.5rem;
  font-size: 0.95rem;
  font-weight: 600;
  color: #334155;
}
.asignaciones-detalle-lista {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
.asignaciones-detalle-badge {
  display: inline-block;
  padding: 0.35rem 0.65rem;
  border-radius: 8px;
  font-size: 0.9rem;
}
.asignaciones-detalle-badge.badge-area {
  background: #e0f2fe;
  color: #0369a1;
  border: 1px solid #bae6fd;
}
.asignaciones-detalle-badge.badge-secretaria {
  background: #f3e8ff;
  color: #6b21a8;
  border: 1px solid #e9d5ff;
}

.presupuesto-section {
  margin-top: 1.5rem;
}
.presupuesto-layout {
  display: grid;
  grid-template-columns: minmax(220px, 280px) 1fr;
  gap: 1rem;
  align-items: stretch;
  margin-top: 1rem;
}
.presupuesto-chart-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8fbff 100%);
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}
.presupuesto-chart-meta {
  margin: 0.25rem 0 0;
  color: #475569;
  font-size: 0.9rem;
}
.presupuesto-resumen-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}
.presupuesto-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8fbff 100%);
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.presupuesto-label {
  font-size: 0.82rem;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}
.presupuesto-value {
  font-size: 1.2rem;
  font-weight: 700;
  color: #0f172a;
}
.presupuesto-value-text {
  font-size: 1rem;
}
.presupuesto-gastos-lista {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  margin-top: 1rem;
}
.presupuesto-gasto-card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1rem;
}
.presupuesto-gasto-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  color: #0f172a;
}
.presupuesto-gasto-detalle {
  margin: 0.5rem 0 0;
  color: #475569;
  line-height: 1.45;
  white-space: pre-wrap;
}

.graficos-section { margin-top: 2rem; }
.graficos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  margin-top: 1rem;
}
.grafico-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
}
.grafico-titulo { font-size: 0.95rem; font-weight: 600; margin-bottom: 0.75rem; color: #334155; }
.grafico-semáforo .semáforo-bars { display: flex; flex-direction: column; gap: 0.75rem; }
.semáforo-item { display: flex; align-items: center; gap: 0.75rem; }
.semáforo-label { font-size: 0.85rem; width: 7rem; color: #475569; }
.semáforo-bar-wrap {
  flex: 1;
  height: 1.25rem;
  background: #f1f5f9;
  border-radius: 6px;
  overflow: hidden;
}
.semáforo-bar {
  height: 100%;
  border-radius: 6px;
  min-width: 2px;
  transition: width 0.3s ease;
}
.semáforo-bar.vencida { background: #dc2626; }
.semáforo-bar.proxima { background: #eab308; }
.semáforo-bar.dentro { background: #22c55e; }
.semáforo-val { font-weight: 700; font-size: 0.95rem; min-width: 1.5rem; text-align: right; }

.adjuntos-lista { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 0.5rem; }
.adjunto-item { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
.adjunto-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.adjunto-edit-input { flex: 1; min-width: 150px; padding: 0.35rem; font-size: 0.85rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.adjunto-edit-btns { display: flex; gap: 0.35rem; }
.btn-icon-mini { padding: 0.2rem 0.4rem; background: #e2e8f0; border: none; border-radius: 4px; cursor: pointer; }
.btn-icon-mini:hover { background: #cbd5e1; }
.btn-danger-mini:hover { background: #fecaca !important; }
.btn-icon-sm { width: 14px; height: 14px; }
.btn-cancel-mini { background: #94a3b8 !important; }
.adjunto-link { color: #2563eb; text-decoration: none; font-size: 0.9rem; }
.adjunto-link:hover { text-decoration: underline; }
.adjunto-upload input[type="file"] { font-size: 0.85rem; }
.adjunto-loading { font-size: 0.85rem; color: #64748b; margin-left: 0.5rem; }
.col-acciones { white-space: nowrap; min-width: 6rem; }
.btn-ver-detalle {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  font-size: 0.85rem;
  color: #2563eb;
  text-decoration: none;
  border-radius: 4px;
  background: #eff6ff;
  transition: background 0.2s;
}
.btn-ver-detalle:hover {
  background: #dbeafe;
  color: #1d4ed8;
}

@media (max-width: 640px) {
  .presupuesto-layout {
    grid-template-columns: 1fr;
  }
  .presupuesto-gasto-head {
    flex-direction: column;
    align-items: flex-start;
  }
}

</style>
