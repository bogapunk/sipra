<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import LoaderSpinner from '@/components/LoaderSpinner.vue'

type VistaCalendario = 'tareas' | 'proyectos'
type HitoProyecto = 'inicio' | 'estimada' | 'real'

interface EventoCalendario {
  id: number | string
  proyectoId: number | null
  titulo: string
  fecha: string
  clase: string
  etiqueta: string
}

const router = useRouter()
const { isCarga, user } = useAuth()
const vista = ref<VistaCalendario>('tareas')
const tareas = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const carga = ref(true)
const mesActual = ref(new Date())

const anio = computed(() => mesActual.value.getFullYear())
const mes = computed(() => mesActual.value.getMonth())

const nombresMeses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
const nombresDias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom']

function fechaKey(fecha: string): string {
  return fecha.slice(0, 10)
}

function parseList(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

function hasNext(payload: unknown): boolean {
  return Boolean(payload && typeof payload === 'object' && 'next' in (payload as object) && (payload as { next?: unknown }).next)
}

async function fetchAllPages(endpoint: string, params: Record<string, string | number> = {}): Promise<Record<string, unknown>[]> {
  const all: Record<string, unknown>[] = []
  let page = 1
  while (true) {
    const res = await api.get(endpoint, { params: { ...params, page, page_size: 200 } })
    all.push(...parseList(res.data))
    if (!hasNext(res.data)) break
    page += 1
  }
  return all
}

const diasDelMes = computed(() => {
  const year = anio.value
  const month = mes.value
  const primerDia = new Date(year, month, 1)
  const ultimoDia = new Date(year, month + 1, 0)
  const dias: { fecha: Date; dia: number; esHoy: boolean; esOtroMes: boolean }[] = []
  const inicioSemana = primerDia.getDay()
  const diasAntes = inicioSemana === 0 ? 6 : inicioSemana - 1
  for (let i = 0; i < diasAntes; i++) {
    const d = new Date(year, month, -diasAntes + i + 1)
    dias.push({ fecha: d, dia: d.getDate(), esHoy: false, esOtroMes: true })
  }
  for (let d = 1; d <= ultimoDia.getDate(); d++) {
    const fecha = new Date(year, month, d)
    const hoy = new Date()
    dias.push({
      fecha,
      dia: d,
      esHoy: fecha.toDateString() === hoy.toDateString(),
      esOtroMes: false,
    })
  }
  const sobrantes = 42 - dias.length
  for (let i = 1; i <= sobrantes; i++) {
    const d = new Date(year, month + 1, i)
    dias.push({ fecha: d, dia: d.getDate(), esHoy: false, esOtroMes: true })
  }
  return dias
})

const eventosTarea = computed<EventoCalendario[]>(() =>
  tareas.value
    .filter((t) => Boolean(t.fecha_vencimiento))
    .map((t) => ({
      id: Number(t.id),
      proyectoId: t.proyecto ? Number(t.proyecto) : null,
      titulo: String(t.titulo || 'Tarea'),
      fecha: String(t.fecha_vencimiento || ''),
      clase: claseVencimiento(estadoVencimiento(t.fecha_vencimiento as string | undefined, t.estado as string | undefined)),
      etiqueta: 'Tarea',
    })),
)

function eventoProyecto(p: Record<string, unknown>, fecha: string, hito: HitoProyecto): EventoCalendario {
  const clase = hito === 'inicio' ? 'evento-proyecto-inicio' : hito === 'estimada' ? 'evento-proyecto-estimada' : 'evento-proyecto-real'
  const etiqueta = hito === 'inicio' ? 'Inicio' : hito === 'estimada' ? 'Fin estimada' : 'Fin real'
  return {
    id: `${p.id}-${hito}`,
    proyectoId: Number(p.id),
    titulo: String(p.nombre || 'Proyecto'),
    fecha,
    clase,
    etiqueta,
  }
}

const eventosProyecto = computed<EventoCalendario[]>(() => {
  const eventos: EventoCalendario[] = []
  for (const p of proyectos.value) {
    if (p.fecha_inicio) eventos.push(eventoProyecto(p, String(p.fecha_inicio), 'inicio'))
    if (p.fecha_fin_estimada) eventos.push(eventoProyecto(p, String(p.fecha_fin_estimada), 'estimada'))
    if (p.fecha_fin_real) eventos.push(eventoProyecto(p, String(p.fecha_fin_real), 'real'))
  }
  return eventos
})

const eventosActivos = computed(() => (vista.value === 'tareas' ? eventosTarea.value : eventosProyecto.value))

const eventosPorFecha = computed(() => {
  const map = new Map<string, EventoCalendario[]>()
  for (const e of eventosActivos.value) {
    if (!e.fecha) continue
    const key = fechaKey(e.fecha)
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(e)
  }
  return map
})

function eventosDelDia(fecha: Date): EventoCalendario[] {
  const key = `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}-${String(fecha.getDate()).padStart(2, '0')}`
  return eventosPorFecha.value.get(key) || []
}

const resumenCalendario = computed(() => {
  const diasConActividad = Array.from(eventosPorFecha.value.keys()).filter((key) => {
    const fecha = new Date(`${key}T00:00:00`)
    return fecha.getMonth() === mes.value && fecha.getFullYear() === anio.value
  }).length

  if (vista.value === 'proyectos') {
    const totalProyectos = proyectos.value.length
    const totalHitos = eventosProyecto.value.length
    const finalizados = proyectos.value.filter((p) => String(p.estado || '') === 'Finalizado').length
    return [
      { key: 'proyectos', title: 'Proyectos visibles', value: totalProyectos, meta: 'Con acceso segun su rol', tone: 'neutral' },
      { key: 'hitos', title: 'Hitos en calendario', value: totalHitos, meta: 'Inicio, fin estimada y fin real', tone: 'info' },
      { key: 'finalizados', title: 'Finalizados', value: finalizados, meta: 'Estado del portafolio', tone: 'success' },
      { key: 'actividad', title: 'Dias con actividad', value: diasConActividad, meta: `Mes de ${nombresMeses[mes.value]}`, tone: 'warning' },
    ]
  }

  const total = tareas.value.length
  const vencidas = tareas.value.filter((t) => estadoVencimiento(t.fecha_vencimiento as string | undefined, t.estado as string | undefined) === 'vencida').length
  const proximas = tareas.value.filter((t) => estadoVencimiento(t.fecha_vencimiento as string | undefined, t.estado as string | undefined) === 'proxima').length
  return [
    { key: 'tareas', title: 'Tareas con vencimiento', value: total, meta: 'Incluidas en el calendario', tone: 'neutral' },
    { key: 'vencidas', title: 'Vencidas', value: vencidas, meta: 'Requieren seguimiento urgente', tone: 'danger' },
    { key: 'proximas', title: 'Proximas a vencer', value: proximas, meta: 'Dentro de los proximos 7 dias', tone: 'warning' },
    { key: 'actividad', title: 'Dias con actividad', value: diasConActividad, meta: `Mes de ${nombresMeses[mes.value]}`, tone: 'info' },
  ]
})

function mesAnterior() {
  mesActual.value = new Date(anio.value, mes.value - 1)
}

function mesSiguiente() {
  mesActual.value = new Date(anio.value, mes.value + 1)
}

function irAEvento(e: EventoCalendario) {
  if (e.proyectoId) {
    router.push(`/proyectos/${e.proyectoId}`)
    return
  }
  router.push('/tareas')
}

async function load() {
  carga.value = true
  try {
    const paramsTareas: Record<string, string | number> = {}
    if (isCarga.value && user.value) paramsTareas.usuario = user.value.id
    tareas.value = await fetchAllPages('tareas/', paramsTareas)
    try {
      proyectos.value = await fetchAllPages('dashboard/proyectos/')
    } catch {
      proyectos.value = await fetchAllPages('proyectos/')
    }
  } catch {
    tareas.value = []
    proyectos.value = []
  } finally {
    carga.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <div class="page-hero">
      <div>
        <h1>Calendario</h1>
        <p class="subtitle">
          {{ vista === 'tareas'
            ? 'Vista mensual de tareas por fecha de vencimiento.'
            : 'Vista mensual de proyectos por hitos clave: inicio, fin estimada y fin real.' }}
        </p>
      </div>
    </div>

    <div class="vista-toggle">
      <button type="button" class="toggle-btn" :class="{ active: vista === 'tareas' }" @click="vista = 'tareas'">
        Tareas
      </button>
      <button type="button" class="toggle-btn" :class="{ active: vista === 'proyectos' }" @click="vista = 'proyectos'">
        Proyectos
      </button>
    </div>

    <section class="summary-grid">
      <article v-for="card in resumenCalendario" :key="card.key" class="summary-card" :class="`tone-${card.tone}`">
        <span class="summary-title">{{ card.title }}</span>
        <strong class="summary-value">{{ card.value }}</strong>
        <span class="summary-meta">{{ card.meta }}</span>
      </article>
    </section>

    <LoaderSpinner v-if="carga" :texto="vista === 'tareas' ? 'Cargando tareas...' : 'Cargando proyectos...'" />

    <div v-else class="calendario-wrapper">
      <div class="calendario-header">
        <button type="button" class="btn-nav" @click="mesAnterior">←</button>
        <h2 class="mes-titulo">{{ nombresMeses[mes] }} {{ anio }}</h2>
        <button type="button" class="btn-nav" @click="mesSiguiente">→</button>
      </div>

      <div class="calendario-legend">
        <template v-if="vista === 'tareas'">
          <span class="legend-item vencida">Vencida</span>
          <span class="legend-item proxima">Proxima a vencer</span>
          <span class="legend-item dentro">Dentro del plazo</span>
        </template>
        <template v-else>
          <span class="legend-item inicio">Inicio</span>
          <span class="legend-item estimada">Fin estimada</span>
          <span class="legend-item real">Fin real</span>
        </template>
      </div>

      <div class="calendario-grid">
        <div v-for="d in nombresDias" :key="d" class="calendario-dia-header">{{ d }}</div>
        <div
          v-for="(celda, idx) in diasDelMes"
          :key="idx"
          class="calendario-celda"
          :class="{
            'celda-otro-mes': celda.esOtroMes,
            'celda-hoy': celda.esHoy,
          }"
        >
          <span class="celda-numero">{{ celda.dia }}</span>
          <div class="celda-tareas">
            <button
              v-for="e in eventosDelDia(celda.fecha).slice(0, 3)"
              :key="e.id"
              type="button"
              class="tarea-mini"
              :class="e.clase"
              :title="`${e.etiqueta}: ${e.titulo}`"
              @click="irAEvento(e)"
            >
              {{ e.etiqueta }}: {{ e.titulo.slice(0, 16) }}{{ e.titulo.length > 16 ? '…' : '' }}
            </button>
            <span v-if="eventosDelDia(celda.fecha).length > 3" class="tarea-mas">
              +{{ eventosDelDia(celda.fecha).length - 3 }} mas
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.page-hero {
  padding: 1.25rem 1.35rem;
  border-radius: 18px;
  background: linear-gradient(135deg, #ffffff 0%, #f8fbff 100%);
  border: 1px solid #e2e8f0;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
}
.page h1 { margin: 0 0 0.35rem; }
.subtitle { color: #64748b; margin: 0; }
.vista-toggle {
  display: inline-flex;
  align-self: flex-start;
  background: #f1f5f9;
  border: 1px solid #dbe5f0;
  border-radius: 999px;
  padding: 0.2rem;
}
.toggle-btn {
  border: none;
  background: transparent;
  color: #334155;
  padding: 0.4rem 0.9rem;
  border-radius: 999px;
  font-weight: 600;
  cursor: pointer;
}
.toggle-btn.active {
  background: #2563eb;
  color: #fff;
}
.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 1rem;
}
.summary-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1rem 1.1rem;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.summary-title { font-size: 0.9rem; color: #64748b; }
.summary-value { font-size: 1.9rem; line-height: 1; color: #0f172a; }
.summary-meta { font-size: 0.85rem; color: #64748b; }
.tone-neutral { border-top: 4px solid #2563eb; }
.tone-info { border-top: 4px solid #0ea5e9; }
.tone-warning { border-top: 4px solid #f59e0b; }
.tone-danger { border-top: 4px solid #dc2626; }
.calendario-wrapper {
  background: white;
  border-radius: 18px;
  padding: 1.5rem;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
  border: 1px solid #e2e8f0;
}
.calendario-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}
.calendario-legend {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
  color: #64748b;
  font-size: 0.82rem;
}
.legend-item {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}
.legend-item::before {
  content: '';
  width: 12px;
  height: 12px;
  border-radius: 4px;
}
.legend-item.vencida::before { background: #fecaca; }
.legend-item.proxima::before { background: #fef08a; }
.legend-item.dentro::before { background: #bbf7d0; }
.legend-item.inicio::before { background: #bfdbfe; }
.legend-item.estimada::before { background: #fde68a; }
.legend-item.real::before { background: #86efac; }
.btn-nav {
  padding: 0.5rem 1rem;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1rem;
}
.btn-nav:hover { background: #e2e8f0; }
.mes-titulo { margin: 0; font-size: 1.25rem; color: #1e293b; }
.calendario-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}
.calendario-dia-header {
  padding: 0.5rem;
  background: #64748b;
  color: white;
  font-size: 0.8rem;
  font-weight: 600;
  text-align: center;
}
.calendario-celda {
  min-height: 100px;
  background: white;
  padding: 0.5rem;
  display: flex;
  flex-direction: column;
  transition: background-color 0.2s ease, transform 0.2s ease;
}
.calendario-celda:hover {
  background: #f8fbff;
  transform: translateY(-1px);
}
.celda-otro-mes { background: #f8fafc; }
.celda-otro-mes .celda-numero { color: #94a3b8; }
.celda-hoy { background: #eff6ff; }
.celda-numero {
  font-size: 0.9rem;
  font-weight: 600;
  color: #334155;
  margin-bottom: 0.35rem;
}
.celda-tareas {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
  overflow: hidden;
}
.tarea-mini {
  font-size: 0.7rem;
  padding: 0.2rem 0.4rem;
  text-align: left;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  background: #e2e8f0;
  color: #334155;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tarea-mini:hover { background: #cbd5e1; }
.tarea-mini.vencimiento-vencida { background: #fecaca; color: #991b1b; }
.tarea-mini.vencimiento-proxima { background: #fef08a; color: #854d0e; }
.tarea-mini.vencimiento-dentro-plazo { background: #bbf7d0; color: #166534; }
.tarea-mini.evento-proyecto-inicio { background: #bfdbfe; color: #1e3a8a; }
.tarea-mini.evento-proyecto-estimada { background: #fde68a; color: #92400e; }
.tarea-mini.evento-proyecto-real { background: #86efac; color: #14532d; }
.tarea-mas { font-size: 0.7rem; color: #64748b; }
@media (max-width: 1100px) {
  .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 700px) {
  .summary-grid { grid-template-columns: 1fr; }
  .calendario-wrapper { padding: 1rem; }
}
</style>
