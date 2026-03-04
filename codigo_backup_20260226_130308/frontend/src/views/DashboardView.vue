<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getDashboard } from '@/services/dashboard'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import PieChart from '@/components/PieChart.vue'
import LineChart from '@/components/LineChart.vue'
import LoaderSpinner from '@/components/LoaderSpinner.vue'

const router = useRouter()
const { user, isAdmin, isVisualizador, isCarga } = useAuth()
const toast = useToast()
const data = ref<Record<string, unknown> | null>(null)
const proyectos = ref<Record<string, unknown>[]>([])
const proyectosCarga = ref<Record<string, unknown>[]>([])
const proyectosACargo = ref<Record<string, unknown>[]>([])
const proyectosParticipacion = ref<Record<string, unknown>[]>([])
const tareasParticularesCarga = ref<Record<string, unknown>[]>([])
const buscarProyecto = ref('')
const evolucionPorProyecto = ref<Record<number, { fecha: string; porcentaje: number }[]>>({})
const cargaProyectos = ref(true)
const errorProyectos = ref('')
const showModalProyecto = ref(false)
const proyectoSeleccionado = ref<Record<string, unknown> | null>(null)
const comentariosProyecto = ref<Record<string, unknown>[]>([])
const nuevoComentario = ref('')

const alertasVencimiento = ref<{
  tareas_vencidas: Record<string, unknown>[];
  tareas_proximas_vencer: Record<string, unknown>[];
  tareas_dentro_plazo: Record<string, unknown>[];
  proyectos_vencidos: Record<string, unknown>[];
  proyectos_proximos_vencer: Record<string, unknown>[];
  proyectos_dentro_plazo: Record<string, unknown>[];
} | null>(null)
const cargaAlertas = ref(false)

onMounted(async () => {
  cargaProyectos.value = true
  errorProyectos.value = ''
  try {
    if (isAdmin.value) {
      const [dashRes, proyRes] = await Promise.all([
        getDashboard(),
        cargarProyectosDashboard(),
      ])
      data.value = dashRes.data
      proyectos.value = proyRes
    } else if (isCarga.value && user.value) {
      // Rol Carga: proyectos a cargo (verde) + participación (azul) + tareas particulares
      const res = await api.get(`dashboard/usuarios/${user.value.id}/proyectos/`)
      const datos = res.data as { proyectos?: unknown[]; proyectos_a_cargo?: unknown[]; proyectos_participacion?: unknown[]; tareas_particulares?: unknown[] }
      proyectosACargo.value = Array.isArray(datos?.proyectos_a_cargo) ? datos.proyectos_a_cargo : []
      proyectosParticipacion.value = Array.isArray(datos?.proyectos_participacion) ? datos.proyectos_participacion : []
      proyectosCarga.value = Array.isArray(datos?.proyectos) ? datos.proyectos : []
      tareasParticularesCarga.value = Array.isArray(datos?.tareas_particulares) ? datos.tareas_particulares : []
      proyectos.value = []
    } else {
      proyectos.value = await cargarProyectosDashboard()
      proyectosCarga.value = []
    }
    await cargarEvoluciones()
    if (isAdmin.value || isVisualizador.value) {
      await cargarAlertasVencimiento()
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: unknown; status?: number }; message?: string }
    const msg = err.response?.data && typeof err.response.data === 'object' && 'detail' in (err.response.data as object)
      ? String((err.response.data as { detail: unknown }).detail)
      : err.response?.data && typeof err.response.data === 'string'
        ? err.response.data
        : err.message || 'Error de conexión'
    errorProyectos.value = `Error al cargar proyectos: ${msg}. Verifique que el servidor esté activo.`
    proyectos.value = []
    proyectosCarga.value = []
    tareasParticularesCarga.value = []
    data.value = null
  } finally {
    cargaProyectos.value = false
  }
})

async function cargarProyectosDashboard(): Promise<Record<string, unknown>[]> {
  try {
    const res = await api.get('dashboard/proyectos/')
    return Array.isArray(res.data) ? res.data : []
  } catch {
    try {
      const res = await api.get('proyectos/')
      const list = Array.isArray(res.data) ? res.data : []
      return list.map((p: Record<string, unknown>) => ({
        ...p,
        porcentaje_avance: p.porcentaje_avance ?? 0,
        fecha_ultima_actualizacion: p.fecha_creacion,
      }))
    } catch {
      return []
    }
  }
}

async function cargarAlertasVencimiento() {
  cargaAlertas.value = true
  try {
    const res = await api.get('dashboard/alertas-vencimiento/')
    const d = res.data as {
      tareas_vencidas?: unknown[]; tareas_proximas_vencer?: unknown[]; tareas_dentro_plazo?: unknown[];
      proyectos_vencidos?: unknown[]; proyectos_proximos_vencer?: unknown[]; proyectos_dentro_plazo?: unknown[];
    }
    alertasVencimiento.value = {
      tareas_vencidas: Array.isArray(d?.tareas_vencidas) ? d.tareas_vencidas : [],
      tareas_proximas_vencer: Array.isArray(d?.tareas_proximas_vencer) ? d.tareas_proximas_vencer : [],
      tareas_dentro_plazo: Array.isArray(d?.tareas_dentro_plazo) ? d.tareas_dentro_plazo : [],
      proyectos_vencidos: Array.isArray(d?.proyectos_vencidos) ? d.proyectos_vencidos : [],
      proyectos_proximos_vencer: Array.isArray(d?.proyectos_proximos_vencer) ? d.proyectos_proximos_vencer : [],
      proyectos_dentro_plazo: Array.isArray(d?.proyectos_dentro_plazo) ? d.proyectos_dentro_plazo : [],
    }
  } catch {
    alertasVencimiento.value = {
      tareas_vencidas: [], tareas_proximas_vencer: [], tareas_dentro_plazo: [],
      proyectos_vencidos: [], proyectos_proximos_vencer: [], proyectos_dentro_plazo: [],
    }
  } finally {
    cargaAlertas.value = false
  }
}

async function cargarEvoluciones() {
  const lista = proyectosParaGrafico.value
  const resultados: Record<number, { fecha: string; porcentaje: number }[]> = {}
  await Promise.all(
    lista.map(async (p: Record<string, unknown>) => {
      try {
        const res = await api.get(`dashboard/proyectos/${p.id}/evolucion/`)
        resultados[(p.id as number)] = Array.isArray(res.data) ? res.data : []
      } catch {
        resultados[(p.id as number)] = []
      }
    })
  )
  evolucionPorProyecto.value = resultados
}

function formatearFecha(f: unknown): string {
  if (!f) return '-'
  const d = typeof f === 'string' ? new Date(f) : f
  if (d instanceof Date && !isNaN(d.getTime())) {
    return d.toLocaleDateString('es-CL', { day: '2-digit', month: 'short', year: 'numeric' })
  }
  return String(f)
}

const proyectosParaGrafico = computed(() => {
  if (isVisualizador.value) return proyectos.value
  if (isCarga.value) return proyectosCarga.value
  return proyectos.value
})

const proyectosFiltrados = computed(() => {
  const lista = proyectosParaGrafico.value
  const q = buscarProyecto.value.trim().toLowerCase()
  if (!q) return lista
  return lista.filter((p: Record<string, unknown>) =>
    String(p.nombre || '').toLowerCase().includes(q)
  )
})

const proyectosACargoFiltrados = computed(() => {
  const q = buscarProyecto.value.trim().toLowerCase()
  if (!q) return proyectosACargo.value
  return proyectosACargo.value.filter((p: Record<string, unknown>) =>
    String(p.nombre || '').toLowerCase().includes(q)
  )
})

const proyectosParticipacionFiltrados = computed(() => {
  const q = buscarProyecto.value.trim().toLowerCase()
  if (!q) return proyectosParticipacion.value
  return proyectosParticipacion.value.filter((p: Record<string, unknown>) =>
    String(p.nombre || '').toLowerCase().includes(q)
  )
})

const tareasParticularesUnicas = computed(() => {
  const lista = tareasParticularesCarga.value
  const vistos = new Set<number>()
  return lista.filter((t: Record<string, unknown>) => {
    const id = t.id as number
    if (vistos.has(id)) return false
    vistos.add(id)
    return true
  })
})

async function abrirModalProyecto(p: Record<string, unknown>) {
  proyectoSeleccionado.value = p
  showModalProyecto.value = true
  nuevoComentario.value = ''
  try {
    const res = await api.get('comentarios-proyecto/', { params: { proyecto: p.id } })
    comentariosProyecto.value = Array.isArray(res.data) ? res.data : []
  } catch {
    comentariosProyecto.value = []
  }
}

function cerrarModalProyecto() {
  showModalProyecto.value = false
  proyectoSeleccionado.value = null
}

async function guardarComentario() {
  const p = proyectoSeleccionado.value
  if (!p || !user.value || !nuevoComentario.value.trim()) return
  try {
    await api.post('comentarios-proyecto/', {
      proyecto: p.id,
      usuario: user.value.id,
      texto: nuevoComentario.value.trim(),
    })
    nuevoComentario.value = ''
    const res = await api.get('comentarios-proyecto/', { params: { proyecto: p.id } })
    comentariosProyecto.value = Array.isArray(res.data) ? res.data : []
    toast.success('Comentario guardado correctamente.')
  } catch {
    toast.error('Error al guardar el comentario.')
  }
}

function irAReasignarProyecto() {
  const p = proyectoSeleccionado.value
  if (p?.id) {
    cerrarModalProyecto()
    router.push(`/proyectos/${p.id}/reasignar`)
  }
}

function formatearFechaHora(f: unknown): string {
  if (!f) return '-'
  const s = typeof f === 'string' ? f : String(f)
  try {
    const d = new Date(s)
    if (isNaN(d.getTime())) return s
    return d.toLocaleString('es-CL', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
  } catch {
    return s
  }
}
</script>

<template>
  <div class="dashboard">
    <h1>Dashboard</h1>

    <!-- Administrador: KPIs completos -->
    <template v-if="isAdmin && data">
      <div class="kpi-grid">
        <div class="kpi-card">
          <span class="kpi-value">{{ data.total_proyectos }}</span>
          <span class="kpi-label">Total Proyectos</span>
        </div>
        <div class="kpi-card">
          <span class="kpi-value">{{ data.proyectos_activos }}</span>
          <span class="kpi-label">Proyectos Activos</span>
        </div>
        <div class="kpi-card">
          <span class="kpi-value">{{ data.total_tareas }}</span>
          <span class="kpi-label">Total Tareas</span>
        </div>
        <div class="kpi-card">
          <span class="kpi-value">{{ data.tareas_finalizadas }}</span>
          <span class="kpi-label">Tareas Finalizadas</span>
        </div>
        <div class="kpi-card">
          <span class="kpi-value">{{ data.tareas_bloqueadas }}</span>
          <span class="kpi-label">Tareas Bloqueadas</span>
        </div>
        <div class="kpi-card" v-if="(data.tareas_particulares ?? 0) > 0">
          <span class="kpi-value">{{ data.tareas_particulares }}</span>
          <span class="kpi-label">Tareas Particulares</span>
        </div>
        <div class="kpi-card accent">
          <span class="kpi-value">{{ data.avance_global }}%</span>
          <span class="kpi-label">Avance Global</span>
        </div>
      </div>
    </template>

    <!-- Alertas de vencimiento (Admin y Visualizador) -->
    <section v-if="(isAdmin || isVisualizador) && alertasVencimiento" class="section-alertas">
      <h2 class="section-title">Alertas de vencimiento</h2>
      <p class="section-desc">Tareas por fecha de vencimiento · Proyectos por fecha fin estimada</p>
      <LoaderSpinner v-if="cargaAlertas" texto="Cargando alertas..." />
      <div v-else>
        <!-- Tareas -->
        <h3 class="alertas-subtitulo">Tareas</h3>
        <div class="alertas-grid">
          <div class="alerta-bloque alerta-vencidas">
            <div class="alerta-header">
              <span class="alerta-icono">🔴</span>
              <h3>Tareas vencidas</h3>
              <span class="alerta-count">{{ alertasVencimiento.tareas_vencidas.length }}</span>
            </div>
            <p class="alerta-desc">Fecha de vencimiento pasada</p>
            <div class="alerta-lista">
              <router-link
                v-for="t in alertasVencimiento.tareas_vencidas"
                :key="'t-' + t.id"
                :to="'/tareas'"
                class="alerta-item"
              >
                <strong>{{ t.titulo }}</strong>
                <span class="alerta-meta">{{ t.proyecto_nombre || '-' }} · {{ t.responsable_nombre || '-' }}</span>
                <span class="alerta-fecha">Vence: {{ formatearFecha(t.fecha_vencimiento) }}</span>
              </router-link>
              <p v-if="!alertasVencimiento.tareas_vencidas.length" class="alerta-vacio">Ninguna</p>
            </div>
          </div>
          <div class="alerta-bloque alerta-proximas">
            <div class="alerta-header">
              <span class="alerta-icono">🟡</span>
              <h3>Próximas a vencer</h3>
              <span class="alerta-count">{{ alertasVencimiento.tareas_proximas_vencer.length }}</span>
            </div>
            <p class="alerta-desc">Vencen en los próximos 7 días</p>
            <div class="alerta-lista">
              <router-link
                v-for="t in alertasVencimiento.tareas_proximas_vencer"
                :key="'t-' + t.id"
                :to="'/tareas'"
                class="alerta-item"
              >
                <strong>{{ t.titulo }}</strong>
                <span class="alerta-meta">{{ t.proyecto_nombre || '-' }} · {{ t.responsable_nombre || '-' }}</span>
                <span class="alerta-fecha">Vence: {{ formatearFecha(t.fecha_vencimiento) }}</span>
              </router-link>
              <p v-if="!alertasVencimiento.tareas_proximas_vencer.length" class="alerta-vacio">Ninguna</p>
            </div>
          </div>
          <div class="alerta-bloque alerta-dentro-plazo">
            <div class="alerta-header">
              <span class="alerta-icono">🟢</span>
              <h3>Dentro del plazo</h3>
              <span class="alerta-count">{{ alertasVencimiento.tareas_dentro_plazo.length }}</span>
            </div>
            <p class="alerta-desc">Vencen en más de 7 días</p>
            <div class="alerta-lista">
              <router-link
                v-for="t in alertasVencimiento.tareas_dentro_plazo"
                :key="'t-' + t.id"
                :to="'/tareas'"
                class="alerta-item"
              >
                <strong>{{ t.titulo }}</strong>
                <span class="alerta-meta">{{ t.proyecto_nombre || '-' }} · {{ t.responsable_nombre || '-' }}</span>
                <span class="alerta-fecha">Vence: {{ formatearFecha(t.fecha_vencimiento) }}</span>
              </router-link>
              <p v-if="!alertasVencimiento.tareas_dentro_plazo.length" class="alerta-vacio">Ninguna</p>
            </div>
          </div>
        </div>
        <!-- Proyectos -->
        <h3 class="alertas-subtitulo">Proyectos</h3>
        <div class="alertas-grid">
          <div class="alerta-bloque alerta-vencidas">
            <div class="alerta-header">
              <span class="alerta-icono">🔴</span>
              <h3>Proyectos vencidos</h3>
              <span class="alerta-count">{{ alertasVencimiento.proyectos_vencidos.length }}</span>
            </div>
            <p class="alerta-desc">Fecha fin estimada pasada</p>
            <div class="alerta-lista">
              <router-link
                v-for="p in alertasVencimiento.proyectos_vencidos"
                :key="'p-' + p.id"
                :to="'/proyectos/' + p.id"
                class="alerta-item"
              >
                <strong>{{ p.nombre }}</strong>
                <span class="alerta-meta">{{ p.responsable_nombre || '-' }}</span>
                <span class="alerta-fecha">Fin estimado: {{ formatearFecha(p.fecha_vencimiento) }}</span>
              </router-link>
              <p v-if="!alertasVencimiento.proyectos_vencidos.length" class="alerta-vacio">Ninguno</p>
            </div>
          </div>
          <div class="alerta-bloque alerta-proximas">
            <div class="alerta-header">
              <span class="alerta-icono">🟡</span>
              <h3>Próximos a vencer</h3>
              <span class="alerta-count">{{ alertasVencimiento.proyectos_proximos_vencer.length }}</span>
            </div>
            <p class="alerta-desc">Fin estimado en los próximos 7 días</p>
            <div class="alerta-lista">
              <router-link
                v-for="p in alertasVencimiento.proyectos_proximos_vencer"
                :key="'p-' + p.id"
                :to="'/proyectos/' + p.id"
                class="alerta-item"
              >
                <strong>{{ p.nombre }}</strong>
                <span class="alerta-meta">{{ p.responsable_nombre || '-' }}</span>
                <span class="alerta-fecha">Fin estimado: {{ formatearFecha(p.fecha_vencimiento) }}</span>
              </router-link>
              <p v-if="!alertasVencimiento.proyectos_proximos_vencer.length" class="alerta-vacio">Ninguno</p>
            </div>
          </div>
          <div class="alerta-bloque alerta-dentro-plazo">
            <div class="alerta-header">
              <span class="alerta-icono">🟢</span>
              <h3>Dentro del plazo</h3>
              <span class="alerta-count">{{ alertasVencimiento.proyectos_dentro_plazo.length }}</span>
            </div>
            <p class="alerta-desc">Fin estimado en más de 7 días</p>
            <div class="alerta-lista">
              <router-link
                v-for="p in alertasVencimiento.proyectos_dentro_plazo"
                :key="'p-' + p.id"
                :to="'/proyectos/' + p.id"
                class="alerta-item"
              >
                <strong>{{ p.nombre }}</strong>
                <span class="alerta-meta">{{ p.responsable_nombre || '-' }}</span>
                <span class="alerta-fecha">Fin estimado: {{ formatearFecha(p.fecha_vencimiento) }}</span>
              </router-link>
              <p v-if="!alertasVencimiento.proyectos_dentro_plazo.length" class="alerta-vacio">Ninguno</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Sección: Todos los proyectos con avance -->
    <section class="section-proyectos">
      <div class="section-header">
        <h2 class="section-title">Avance por proyecto</h2>
        <input
          v-model="buscarProyecto"
          type="search"
          placeholder="Buscar proyecto..."
          class="search-input"
        />
      </div>

      <LoaderSpinner v-if="cargaProyectos" texto="Cargando proyectos y avances..." />
      <p v-else-if="errorProyectos" class="error-msg">{{ errorProyectos }}</p>

      <template v-else-if="proyectosParaGrafico.length || (isCarga && tareasParticularesUnicas.length)">
        <template v-if="isCarga && (proyectosACargo.length || proyectosParticipacion.length || tareasParticularesUnicas.length)">
          <div v-if="proyectosACargoFiltrados.length" class="proyectos-subsection">
            <h3 class="subsection-title proyectos-a-cargo-title">🟢 Proyectos a Cargo</h3>
            <div class="proyectos-grid">
              <div
                v-for="p in proyectosACargoFiltrados"
                :key="(p.id as number)"
                class="proyecto-card clickable proyecto-a-cargo"
                @click="abrirModalProyecto(p)"
              >
                <div class="proyecto-header">
                  <h3 class="proyecto-nombre">{{ p.nombre }}</h3>
                  <span class="badge-responsable">Responsable</span>
                  <span class="clic-hint">Clic para ver detalles y comentarios</span>
                  <div class="proyecto-stats">
                    <span class="avance-actual">{{ Number(p.porcentaje_avance) || 0 }}%</span>
                    <span class="ultima-actualizacion">Última actualización: {{ formatearFecha(p.fecha_ultima_actualizacion) }}</span>
                  </div>
                </div>
                <div class="proyecto-charts">
                  <div class="chart-torta">
                    <PieChart :value="Number(p.porcentaje_avance) || 0" :label="(p.nombre as string)" :size="110" />
                  </div>
                  <div class="chart-lineal">
                    <LineChart :data="evolucionPorProyecto[p.id as number] || []" :label="`Evolución - ${p.nombre}`" :chart-id="`proy-${p.id}`" :width="280" :height="160" />
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-if="proyectosParticipacionFiltrados.length" class="proyectos-subsection">
            <h3 class="subsection-title proyectos-participacion-title">🔵 Proyectos donde participo</h3>
            <div class="proyectos-grid">
              <div
                v-for="p in proyectosParticipacionFiltrados"
                :key="(p.id as number)"
                class="proyecto-card clickable proyecto-participacion"
                @click="abrirModalProyecto(p)"
              >
                <div class="proyecto-header">
                  <h3 class="proyecto-nombre">{{ p.nombre }}</h3>
                  <span class="clic-hint">Clic para ver detalles</span>
                  <div class="proyecto-stats">
                    <span class="avance-actual">{{ Number(p.porcentaje_avance) || 0 }}%</span>
                    <span class="ultima-actualizacion">Última actualización: {{ formatearFecha(p.fecha_ultima_actualizacion) }}</span>
                  </div>
                </div>
                <div class="proyecto-charts">
                  <div class="chart-torta">
                    <PieChart :value="Number(p.porcentaje_avance) || 0" :label="(p.nombre as string)" :size="110" />
                  </div>
                  <div class="chart-lineal">
                    <LineChart :data="evolucionPorProyecto[p.id as number] || []" :label="`Evolución - ${p.nombre}`" :chart-id="`proy-${p.id}`" :width="280" :height="160" />
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-if="tareasParticularesUnicas.length" class="proyectos-subsection">
            <h3 class="subsection-title tareas-particulares-title">◉ Tareas Particulares</h3>
            <p class="subsection-desc">Tareas sin proyecto asociado asignadas a su área o como responsable.</p>
            <div class="tareas-particulares-list">
              <div
                v-for="t in tareasParticularesUnicas"
                :key="(t.id as number)"
                class="tarea-particular-card"
              >
                <div class="tarea-particular-info">
                  <strong>{{ t.titulo }}</strong>
                  <span class="tarea-particular-meta">{{ t.area_nombre || t.secretaria_nombre || '-' }} · {{ t.estado }} · {{ Number(t.porcentaje_avance) || 0 }}%</span>
                </div>
                <router-link :to="'/cargar'" class="btn-tarea-particular">Actualizar en Cargar Avances</router-link>
              </div>
            </div>
          </div>
          <p v-if="isCarga && !proyectosACargoFiltrados.length && !proyectosParticipacionFiltrados.length && !tareasParticularesUnicas.length && (proyectosACargo.length || proyectosParticipacion.length)" class="empty-msg">
            No hay proyectos que coincidan con la búsqueda.
          </p>
        </template>
        <div v-else class="proyectos-grid">
          <div
            v-for="p in proyectosFiltrados"
            :key="(p.id as number)"
            class="proyecto-card clickable"
            :class="{ 'proyecto-a-cargo': isCarga && p.es_responsable, 'proyecto-participacion': isCarga && !p.es_responsable }"
            @click="abrirModalProyecto(p)"
          >
            <div class="proyecto-header">
              <h3 class="proyecto-nombre">{{ p.nombre }}</h3>
              <span v-if="isCarga && p.es_responsable" class="badge-responsable">Responsable</span>
              <span class="clic-hint">Clic para ver detalles y comentarios</span>
              <div class="proyecto-stats">
                <span class="avance-actual">{{ Number(p.porcentaje_avance) || 0 }}%</span>
                <span class="ultima-actualizacion">
                  Última actualización: {{ formatearFecha(p.fecha_ultima_actualizacion) }}
                </span>
                <span v-if="p.area_ultima_actualizacion && p.area_ultima_actualizacion !== '-'" class="proyecto-extra">
                  Área: <strong>{{ p.area_ultima_actualizacion }}</strong>
                </span>
                <span v-if="p.usuario_ultima_actualizacion && p.usuario_ultima_actualizacion !== '-'" class="proyecto-extra">
                  Último usuario: <strong>{{ p.usuario_ultima_actualizacion }}</strong>
                </span>
              </div>
            </div>
            <div class="proyecto-charts">
              <div class="chart-torta">
                <PieChart
                  :value="Number(p.porcentaje_avance) || 0"
                  :label="(p.nombre as string)"
                  :size="110"
                />
              </div>
              <div class="chart-lineal">
                <LineChart
                  :data="evolucionPorProyecto[p.id as number] || []"
                  :label="`Evolución temporal - ${p.nombre}`"
                  :chart-id="`proy-${p.id}`"
                  :width="280"
                  :height="160"
                />
              </div>
            </div>
          </div>
        </div>
        <p v-if="!proyectosFiltrados.length" class="empty-msg">
          No hay proyectos que coincidan con la búsqueda.
        </p>
      </template>

      <p v-else class="empty-msg">
        {{ isCarga ? 'No tiene proyectos asignados. El administrador debe: 1) Asignar su área en Usuarios, 2) Asignar el proyecto a su área (Reasignar) o ponerlo como responsable de tareas.' : 'No hay proyectos en el sistema.' }}
      </p>
    </section>

    <!-- Modal: Detalle proyecto, comentarios, reasignar -->
    <div v-if="showModalProyecto && proyectoSeleccionado" class="modal-overlay" @click.self="cerrarModalProyecto">
      <div class="modal-proyecto">
        <h2>{{ proyectoSeleccionado.nombre }}</h2>
        <p class="modal-subtitle">Avance: {{ Number(proyectoSeleccionado.porcentaje_avance) || 0 }}% · Última actualización: {{ formatearFecha(proyectoSeleccionado.fecha_ultima_actualizacion) }}</p>
        <p v-if="(proyectoSeleccionado.area_ultima_actualizacion && proyectoSeleccionado.area_ultima_actualizacion !== '-') || (proyectoSeleccionado.usuario_ultima_actualizacion && proyectoSeleccionado.usuario_ultima_actualizacion !== '-')" class="modal-extras">
          <span v-if="proyectoSeleccionado.area_ultima_actualizacion && proyectoSeleccionado.area_ultima_actualizacion !== '-'">Área: <strong>{{ proyectoSeleccionado.area_ultima_actualizacion }}</strong></span>
          <span v-if="(proyectoSeleccionado.area_ultima_actualizacion && proyectoSeleccionado.area_ultima_actualizacion !== '-') && (proyectoSeleccionado.usuario_ultima_actualizacion && proyectoSeleccionado.usuario_ultima_actualizacion !== '-')"> · </span>
          <span v-if="proyectoSeleccionado.usuario_ultima_actualizacion && proyectoSeleccionado.usuario_ultima_actualizacion !== '-'">Último usuario: <strong>{{ proyectoSeleccionado.usuario_ultima_actualizacion }}</strong></span>
        </p>

        <div class="modal-comentarios">
          <h3>Comentarios y observaciones</h3>
          <div v-if="comentariosProyecto.length" class="comentarios-lista">
            <div v-for="c in comentariosProyecto" :key="(c.id as number)" class="comentario-item">
              <span class="comentario-autor">{{ c.usuario_nombre }}</span>
              <span class="comentario-fecha">{{ formatearFechaHora(c.fecha) }}</span>
              <p class="comentario-texto">{{ c.texto }}</p>
            </div>
          </div>
          <p v-else class="sin-comentarios">Sin comentarios aún.</p>

          <div class="comentario-nuevo">
            <textarea v-model="nuevoComentario" placeholder="Agregar comentario sobre el avance, reasignación de área, etc." rows="3" />
            <button type="button" class="btn-primary" @click="guardarComentario" :disabled="!nuevoComentario.trim()">Guardar comentario</button>
          </div>
        </div>

        <div class="modal-actions">
          <button v-if="!isCarga" type="button" class="btn-ver-detalle" @click="irAReasignarProyecto">
            Ver detalle y reasignar proyecto
          </button>
          <button type="button" class="btn-cancel" @click="cerrarModalProyecto">Cerrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard h1 { margin-bottom: 1.5rem; color: #1e293b; }
.section-title { font-size: 1rem; margin: 1.5rem 0 1rem; color: #64748b; }
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 1rem;
}
@media (max-width: 480px) {
  .dashboard h1 { font-size: 1.35rem; }
  .kpi-grid { grid-template-columns: repeat(2, 1fr); gap: 0.75rem; }
  .kpi-card { padding: 1rem; }
  .kpi-value { font-size: 1.5rem; }
  .alertas-grid { grid-template-columns: 1fr; }
}
.kpi-card {
  background: white;
  padding: 1.25rem;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.kpi-card.accent { background: #3b82f6; color: white; }
.kpi-value { font-size: 1.75rem; font-weight: 700; }
.kpi-label { font-size: 0.875rem; color: #64748b; }
.kpi-card.accent .kpi-label { color: rgba(255,255,255,0.9); }

.section-alertas { margin-top: 2rem; }
.section-desc { font-size: 0.9rem; color: #64748b; margin: -0.5rem 0 1rem; }
.alertas-subtitulo { font-size: 1rem; font-weight: 600; color: #334155; margin: 1.5rem 0 0.75rem; }
.alertas-subtitulo:first-of-type { margin-top: 0; }
.alertas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.25rem;
}
.alerta-bloque {
  border-radius: 10px;
  padding: 1.25rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.alerta-vencidas {
  background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
  border-left: 4px solid #dc2626;
}
.alerta-proximas {
  background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
  border-left: 4px solid #d97706;
}
.alerta-dentro-plazo {
  background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
  border-left: 4px solid #16a34a;
}
.alerta-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.35rem;
}
.alerta-icono { font-size: 1.25rem; }
.alerta-header h3 { margin: 0; font-size: 1rem; font-weight: 600; }
.alerta-count {
  margin-left: auto;
  background: rgba(0,0,0,0.08);
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 600;
}
.alerta-desc {
  font-size: 0.8rem;
  color: #64748b;
  margin: 0 0 0.75rem;
}
.alerta-lista {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 200px;
  overflow-y: auto;
}
.alerta-item {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  padding: 0.6rem 0.75rem;
  background: rgba(255,255,255,0.7);
  border-radius: 8px;
  text-decoration: none;
  color: inherit;
  transition: background 0.2s;
}
.alerta-item:hover { background: rgba(255,255,255,0.95); }
.alerta-item strong { font-size: 0.9rem; }
.alerta-meta { font-size: 0.75rem; color: #64748b; }
.alerta-fecha { font-size: 0.75rem; color: #475569; font-weight: 500; }
.alerta-vacio { font-size: 0.85rem; color: #94a3b8; margin: 0; padding: 0.5rem 0; }

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin: 1.5rem 0 1rem;
}
.search-input {
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  min-width: 200px;
}
.proyectos-subsection { margin-bottom: 2rem; }
.subsection-title { font-size: 1rem; margin-bottom: 0.75rem; font-weight: 600; }
.proyectos-a-cargo-title { color: #15803d; }
.proyectos-participacion-title { color: #2563eb; }
.tareas-particulares-title { color: #7c3aed; }
.subsection-desc { font-size: 0.875rem; color: #64748b; margin: 0 0 0.75rem; }
.tareas-particulares-list { display: flex; flex-direction: column; gap: 0.75rem; }
.tarea-particular-card {
  background: linear-gradient(135deg, #faf5ff 0%, #f5f3ff 100%);
  border: 1px solid #e9d5ff;
  border-left: 4px solid #7c3aed;
  padding: 1rem 1.25rem;
  border-radius: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
}
.tarea-particular-info { display: flex; flex-direction: column; gap: 0.25rem; }
.tarea-particular-meta { font-size: 0.875rem; color: #64748b; }
.btn-tarea-particular {
  padding: 0.4rem 0.9rem;
  background: #7c3aed;
  color: white;
  border-radius: 8px;
  font-size: 0.85rem;
  text-decoration: none;
  font-weight: 500;
}
.btn-tarea-particular:hover { background: #6d28d9; color: white; }
.proyecto-a-cargo { border-left: 4px solid #15803d; }
.proyecto-participacion { border-left: 4px solid #2563eb; }
.badge-responsable {
  display: inline-block;
  background: #dcfce7;
  color: #15803d;
  font-size: 0.75rem;
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
  font-weight: 600;
  margin-left: 0.5rem;
}
.proyectos-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(420px, 1fr));
  gap: 1.5rem;
}
.proyecto-card {
  background: white;
  padding: 1.25rem;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.proyecto-card.clickable {
  cursor: pointer;
  transition: box-shadow 0.2s;
}
.proyecto-card.clickable:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.12);
}
.clic-hint {
  font-size: 0.7rem;
  color: #94a3b8;
  display: block;
  margin-bottom: 0.35rem;
}
.proyecto-header {
  margin-bottom: 1rem;
}
.proyecto-nombre {
  font-size: 1.1rem;
  margin: 0 0 0.5rem;
  color: #1e293b;
}
.proyecto-stats {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.avance-actual {
  font-size: 1.5rem;
  font-weight: 700;
  color: #3b82f6;
}
.ultima-actualizacion {
  font-size: 0.8rem;
  color: #64748b;
}
.proyecto-extra {
  font-size: 0.8rem;
  color: #475569;
  display: block;
}
.proyecto-extra strong {
  color: #1e293b;
}
.section-proyectos {
  margin-top: 2rem;
}
.proyecto-charts {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
  align-items: flex-start;
}
.chart-torta {
  flex-shrink: 0;
}
.chart-lineal {
  flex: 1;
  min-width: 220px;
}
.empty-msg, .loading { color: #64748b; margin-top: 1rem; }
.error-msg {
  color: #dc2626;
  background: #fef2f2;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  margin-top: 0.5rem;
}
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-proyecto {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  max-width: 520px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}
.modal-proyecto h2 { margin: 0 0 0.5rem; font-size: 1.25rem; }
.modal-subtitle { color: #64748b; font-size: 0.9rem; margin-bottom: 0.5rem; }
.modal-extras { font-size: 0.9rem; color: #475569; margin-bottom: 1.25rem; }
.modal-extras strong { color: #1e293b; }
.modal-comentarios h3 { font-size: 0.95rem; margin: 0 0 0.75rem; }
.comentarios-lista { max-height: 180px; overflow-y: auto; margin-bottom: 1rem; }
.comentario-item {
  padding: 0.5rem 0;
  border-bottom: 1px solid #f1f5f9;
}
.comentario-autor { font-weight: 600; font-size: 0.9rem; margin-right: 0.5rem; }
.comentario-fecha { font-size: 0.75rem; color: #94a3b8; }
.comentario-texto { margin: 0.25rem 0 0; font-size: 0.9rem; color: #475569; }
.sin-comentarios { color: #94a3b8; font-size: 0.9rem; margin-bottom: 1rem; }
.comentario-nuevo { margin-bottom: 1.25rem; }
.comentario-nuevo textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  margin-bottom: 0.5rem;
  resize: vertical;
}
.comentario-nuevo .btn-primary {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}
.comentario-nuevo .btn-primary:disabled {
  background: #94a3b8;
  cursor: not-allowed;
}
.modal-actions { display: flex; gap: 0.75rem; flex-wrap: wrap; }
.btn-ver-detalle {
  background: #16a34a;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-ver-detalle:hover { background: #15803d; }
.btn-cancel {
  background: #e2e8f0;
  color: #475569;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-cancel:hover { background: #cbd5e1; }
</style>
