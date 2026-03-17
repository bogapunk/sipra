<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
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
const modalAbierto = ref(false)
const modalFecha = ref('')
const modalEventos = ref<EventoCalendario[]>([])

const anio = computed(() => mesActual.value.getFullYear())
const mes = computed(() => mesActual.value.getMonth())

const nombresMeses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
const nombresDias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom']

function fechaKey(fecha: string): string {
  return fecha.slice(0, 10)
}

function formatFechaLarga(fecha: string): string {
  if (!fecha) return ''
  const [year, month, day] = fecha.split('-').map(Number)
  if (!year || !month || !day) return fecha
  return new Date(year, month - 1, day).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  })
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

function detalleEvento(e: EventoCalendario): Record<string, unknown> | undefined {
  if (vista.value === 'proyectos' && e.proyectoId) {
    return proyectos.value.find((p) => Number(p.id) === e.proyectoId)
  }
  return tareas.value.find((t) => Number(t.id) === Number(e.id))
}

function metaEvento(e: EventoCalendario): string[] {
  const detalle = detalleEvento(e)
  if (!detalle) return []

  if (vista.value === 'proyectos') {
    const meta = [
      String(detalle.estado || '').trim(),
      String(detalle.area_nombre || detalle.area || '').trim(),
      String(detalle.secretaria_nombre || detalle.secretaria || '').trim(),
    ]
    return meta.filter(Boolean)
  }

  const meta = [
    String(detalle.estado || '').trim(),
    String(detalle.prioridad || '').trim(),
    String(detalle.proyecto_nombre || '').trim(),
    String(detalle.responsable_nombre || detalle.responsable || '').trim(),
  ]
  return meta.filter(Boolean)
}

function subtituloEvento(e: EventoCalendario): string {
  const partes = metaEvento(e)
  return partes.join(' · ')
}

function abrirModalFecha(fecha: string, eventos: EventoCalendario[]) {
  if (!eventos.length) return
  modalFecha.value = fecha
  modalEventos.value = [...eventos].sort((a, b) => a.titulo.localeCompare(b.titulo, 'es'))
  modalAbierto.value = true
}

function abrirModalDia(fecha: Date) {
  const eventos = eventosDelDia(fecha)
  const key = `${fecha.getFullYear()}-${String(fecha.getMonth() + 1).padStart(2, '0')}-${String(fecha.getDate()).padStart(2, '0')}`
  abrirModalFecha(key, eventos)
}

function abrirModalEvento(e: EventoCalendario) {
  abrirModalFecha(fechaKey(e.fecha), eventosPorFecha.value.get(fechaKey(e.fecha)) || [e])
}

function cerrarModal() {
  modalAbierto.value = false
  modalFecha.value = ''
  modalEventos.value = []
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && modalAbierto.value) {
    cerrarModal()
  }
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
    cerrarModal()
    return
  }
  router.push('/tareas')
  cerrarModal()
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
onMounted(() => window.addEventListener('keydown', onKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', onKeydown))
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
          @click="abrirModalDia(celda.fecha)"
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
              @click.stop="abrirModalEvento(e)"
            >
              {{ e.etiqueta }}: {{ e.titulo.slice(0, 16) }}{{ e.titulo.length > 16 ? '…' : '' }}
            </button>
            <button
              v-if="eventosDelDia(celda.fecha).length > 3"
              type="button"
              class="tarea-mas"
              @click.stop="abrirModalDia(celda.fecha)"
            >
              +{{ eventosDelDia(celda.fecha).length - 3 }} mas
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="modalAbierto" class="modal-overlay" @click.self="cerrarModal">
      <div class="modal-calendario">
        <div class="modal-calendario-header">
          <div>
            <h3>{{ vista === 'tareas' ? 'Tareas del dia' : 'Proyectos del dia' }}</h3>
            <p>{{ formatFechaLarga(modalFecha) }} · {{ modalEventos.length }} {{ modalEventos.length === 1 ? 'registro' : 'registros' }}</p>
          </div>
          <button type="button" class="modal-close" @click="cerrarModal">×</button>
        </div>

        <div class="modal-calendario-body">
          <article
            v-for="evento in modalEventos"
            :key="evento.id"
            class="modal-evento"
            :class="evento.clase"
          >
            <div class="modal-evento-main">
              <span class="modal-evento-tag">{{ evento.etiqueta }}</span>
              <h4>{{ evento.titulo }}</h4>
              <p v-if="subtituloEvento(evento)" class="modal-evento-meta">
                {{ subtituloEvento(evento) }}
              </p>
            </div>
            <button type="button" class="btn-ir-detalle" @click="irAEvento(evento)">
              {{ vista === 'proyectos' ? 'Ver proyecto' : 'Ir a tareas' }}
            </button>
          </article>
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
  cursor: pointer;
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
.tarea-mas {
  font-size: 0.7rem;
  color: #64748b;
  background: transparent;
  border: none;
  padding: 0;
  text-align: left;
  cursor: pointer;
}
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  z-index: 60;
}
.modal-calendario {
  width: min(820px, 100%);
  max-height: 85vh;
  overflow: hidden;
  background: #fff;
  border-radius: 20px;
  border: 1px solid #dbe5f0;
  box-shadow: 0 24px 64px rgba(15, 23, 42, 0.22);
  display: flex;
  flex-direction: column;
}
.modal-calendario-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.1rem 1.25rem;
  border-bottom: 1px solid #e2e8f0;
}
.modal-calendario-header h3 {
  margin: 0 0 0.3rem;
  color: #0f172a;
}
.modal-calendario-header p {
  margin: 0;
  color: #64748b;
  font-size: 0.92rem;
}
.modal-close {
  border: none;
  background: #f1f5f9;
  color: #334155;
  border-radius: 999px;
  width: 2rem;
  height: 2rem;
  font-size: 1.3rem;
  cursor: pointer;
}
.modal-calendario-body {
  padding: 1rem 1.25rem 1.25rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.modal-evento {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.95rem 1rem;
  border: 1px solid #e2e8f0;
  border-left-width: 5px;
  border-radius: 14px;
  background: #f8fafc;
}
.modal-evento-main {
  min-width: 0;
}
.modal-evento-tag {
  display: inline-flex;
  align-items: center;
  padding: 0.2rem 0.55rem;
  border-radius: 999px;
  background: rgba(37, 99, 235, 0.12);
  color: #1d4ed8;
  font-size: 0.75rem;
  font-weight: 700;
  margin-bottom: 0.45rem;
}
.modal-evento h4 {
  margin: 0;
  color: #0f172a;
  font-size: 1rem;
}
.modal-evento-meta {
  margin: 0.35rem 0 0;
  color: #64748b;
  font-size: 0.88rem;
}
.btn-ir-detalle {
  border: none;
  border-radius: 10px;
  padding: 0.65rem 0.95rem;
  background: #2563eb;
  color: #fff;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
}
.btn-ir-detalle:hover {
  background: #1d4ed8;
}
.modal-evento.vencimiento-vencida { border-left-color: #dc2626; }
.modal-evento.vencimiento-proxima { border-left-color: #ca8a04; }
.modal-evento.vencimiento-dentro-plazo { border-left-color: #16a34a; }
.modal-evento.evento-proyecto-inicio { border-left-color: #2563eb; }
.modal-evento.evento-proyecto-estimada { border-left-color: #d97706; }
.modal-evento.evento-proyecto-real { border-left-color: #15803d; }
@media (max-width: 1100px) {
  .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 700px) {
  .summary-grid { grid-template-columns: 1fr; }
  .calendario-wrapper { padding: 1rem; }
  .modal-calendario {
    max-height: 90vh;
  }
  .modal-evento {
    flex-direction: column;
    align-items: stretch;
  }
  .btn-ir-detalle {
    width: 100%;
  }
}
</style>
