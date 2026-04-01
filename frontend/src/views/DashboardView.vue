<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { use } from 'echarts/core'
import { BarChart, LineChart, PieChart } from 'echarts/charts'
import { CanvasRenderer } from 'echarts/renderers'
import {
  GridComponent,
  LegendComponent,
  TooltipComponent,
  TitleComponent,
} from 'echarts/components'
import VChart from 'vue-echarts'
import type { EChartsOption } from 'echarts'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import { api } from '@/services/api'
import { getDashboard, getDashboardAnalitico, getDashboardUsuario } from '@/services/dashboard'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'

use([
  CanvasRenderer,
  PieChart,
  BarChart,
  LineChart,
  GridComponent,
  LegendComponent,
  TooltipComponent,
  TitleComponent,
])

type Kpis = {
  total_proyectos: number
  proyectos_activos: number
  proyectos_finalizados: number
  avance_promedio: number
  proyectos_en_riesgo: number
  tareas_bloqueadas: number
  tareas_activas: number
}

type ChartItem = {
  id?: number | null
  name: string
  value: number
  filter_type?: string | null
  avance?: number
  proyectos?: number
  tareas?: number
  bloqueadas?: number
  estado?: string
  responsable_nombre?: string
  fecha_fin_estimada?: string
}

type TrendPoint = {
  periodo: string
  label: string
  valor: number
  actualizaciones: number
}

type VencimientoPoint = {
  categoria: string
  proyectos: number
  tareas: number
}

type RiesgoProyecto = {
  id: number
  nombre: string
  estado: string
  responsable_nombre: string
  secretaria_nombre: string
  fecha_fin_estimada: string | null
  porcentaje_avance: number
  tareas_bloqueadas: number
  dias_atraso: number
}

type TareaCritica = {
  id: number
  titulo: string
  proyecto_id: number | null
  proyecto_nombre: string
  responsable_nombre: string
  estado: string
  fecha_vencimiento: string | null
  porcentaje_avance: number
  dias_restantes: number
}

type DashboardAnalitico = {
  kpis: Kpis
  charts: {
    proyectos_por_estado: ChartItem[]
    proyectos_por_dependencia: ChartItem[]
    tendencia_avance: TrendPoint[]
    vencimientos: VencimientoPoint[]
    top_proyectos_atrasados: ChartItem[]
    carga_por_responsable: ChartItem[]
  }
  highlights: {
    proyectos_riesgo: RiesgoProyecto[]
    tareas_criticas: TareaCritica[]
  }
  filtros: {
    secretaria?: string | null
    area?: string | null
    estado?: string | null
  }
}

type DashboardCarga = {
  proyectos_a_cargo?: Record<string, unknown>[]
  proyectos_participacion?: Record<string, unknown>[]
  proyectos?: Record<string, unknown>[]
  tareas_particulares?: Record<string, unknown>[]
}

type ChartClickParam = {
  name?: string
  seriesName?: string
  data?: Record<string, unknown> | number
}

type EChartExpose = {
  getDataURL: (opts?: Record<string, unknown>) => string
}

const router = useRouter()
const toast = useToast()
const { user, isAdmin, isVisualizador, isCarga } = useAuth()

const carga = ref(true)
const error = ref('')
const aviso = ref('')
const dashboard = ref<DashboardAnalitico | null>(null)
const dashboardCarga = ref<DashboardCarga | null>(null)
type DependenciaOption = {
  value: string
  label: string
  tipo: 'secretaria' | 'area'
  id: number
}
const dependencias = ref<DependenciaOption[]>([])
const filtroDependencia = ref('')
const filtroEstado = ref('')
const estadoChartRef = ref<EChartExpose | null>(null)
const dependenciaChartRef = ref<EChartExpose | null>(null)
const tendenciaChartRef = ref<EChartExpose | null>(null)
const vencimientosChartRef = ref<EChartExpose | null>(null)
const atrasadosChartRef = ref<EChartExpose | null>(null)
const cargaChartRef = ref<EChartExpose | null>(null)
const showTareaDetalleModal = ref(false)
const cargandoTareaDetalle = ref(false)
const tareaDetalle = ref<Record<string, unknown> | null>(null)
const comentariosTareaDetalle = ref<Record<string, unknown>[]>([])
const adjuntosTareaDetalle = ref<Record<string, unknown>[]>([])

const ESTADOS_PROYECTO = [
  { value: '', label: 'Todos los estados' },
  { value: 'Activo', label: 'Activos' },
  { value: 'En pausa', label: 'En pausa' },
  { value: 'Finalizado', label: 'Finalizados' },
] as const

const canSeeExecutive = computed(() => isAdmin.value || isVisualizador.value)

function formatNumber(value: number | string | null | undefined): string {
  const num = Number(value ?? 0)
  return Number.isFinite(num) ? num.toLocaleString('es-CL') : '0'
}

function formatPercent(value: number | string | null | undefined): string {
  const num = Number(value ?? 0)
  return `${Number.isFinite(num) ? num.toLocaleString('es-CL', { maximumFractionDigits: 1 }) : '0'}%`
}

function formatDate(value: string | null | undefined): string {
  if (!value) return '-'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleDateString('es-CL', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

function resumenRiesgoDias(dias: number): string {
  if (dias > 0) return `${dias} dia(s) de atraso`
  if (dias === 0) return 'Vence hoy'
  return `${Math.abs(dias)} dia(s) restantes`
}

async function cargarDependencias() {
  try {
    const [secretariasRes, areasRes] = await Promise.all([
      api.get('secretarias/', { params: { activa: 'true' } }),
      api.get('areas/', { params: { estado: 'true' } }),
    ])
    const secretarias = Array.isArray(secretariasRes.data)
      ? (secretariasRes.data as { id: number; nombre: string; codigo?: string }[])
      : []
    const areas = Array.isArray(areasRes.data)
      ? (areasRes.data as { id: number; nombre: string }[])
      : []
    dependencias.value = [
      ...secretarias.map((item) => ({
        value: `secretaria:${item.id}`,
        label: `Secretaria: ${item.codigo ? `${item.codigo} - ` : ''}${item.nombre}`,
        tipo: 'secretaria' as const,
        id: item.id,
      })),
      ...areas.map((item) => ({
        value: `area:${item.id}`,
        label: `Area: ${item.nombre}`,
        tipo: 'area' as const,
        id: item.id,
      })),
    ]
  } catch {
    dependencias.value = []
  }
}

async function cargarDashboardEjecutivo() {
  const params: Record<string, string> = {}
  if (filtroDependencia.value) {
    const [tipo, id] = filtroDependencia.value.split(':')
    if (tipo === 'secretaria' && id) params.secretaria = id
    if (tipo === 'area' && id) params.area = id
  }
  if (filtroEstado.value) params.estado = filtroEstado.value
  try {
    const res = await getDashboardAnalitico(params)
    dashboard.value = res.data as DashboardAnalitico
  } catch (e) {
    const err = e as { response?: { status?: number; data?: string | { detail?: string } } }
    const raw = typeof err.response?.data === 'string' ? err.response.data : ''
    const endpointFaltante = err.response?.status === 404 || raw.includes('/api/dashboard/analitico/')
    if (!endpointFaltante) throw e

    const legacy = await getDashboard()
    const data = legacy.data as {
      total_proyectos?: number
      proyectos_activos?: number
      total_tareas?: number
      tareas_bloqueadas?: number
      avance_global?: number
    }
    dashboard.value = {
      kpis: {
        total_proyectos: Number(data.total_proyectos || 0),
        proyectos_activos: Number(data.proyectos_activos || 0),
        proyectos_finalizados: 0,
        avance_promedio: Number(data.avance_global || 0),
        proyectos_en_riesgo: 0,
        tareas_bloqueadas: Number(data.tareas_bloqueadas || 0),
        tareas_activas: Math.max(0, Number(data.total_tareas || 0) - Number(data.tareas_bloqueadas || 0)),
      },
      charts: {
        proyectos_por_estado: [],
        proyectos_por_dependencia: [],
        tendencia_avance: [],
        vencimientos: [],
        top_proyectos_atrasados: [],
        carga_por_responsable: [],
      },
      highlights: {
        proyectos_riesgo: [],
        tareas_criticas: [],
      },
      filtros: {
        secretaria: null,
        area: null,
        estado: filtroEstado.value || null,
      },
    }
    aviso.value = 'El frontend ya fue actualizado, pero el backend que esta corriendo todavia no cargo el endpoint nuevo. Reinicie el backend o vuelva a ejecutar el sistema para ver los graficos completos.'
  }
}

async function cargarDashboardCarga() {
  if (!user.value?.id) {
    dashboardCarga.value = null
    return
  }
  const res = await getDashboardUsuario(user.value.id)
  dashboardCarga.value = res.data as DashboardCarga
}

async function cargarTodo() {
  carga.value = true
  error.value = ''
  aviso.value = ''
  try {
    if (canSeeExecutive.value) {
      await Promise.all([cargarDependencias(), cargarDashboardEjecutivo()])
      dashboardCarga.value = null
    } else if (isCarga.value) {
      await cargarDashboardCarga()
      dashboard.value = null
    } else {
      dashboard.value = null
      dashboardCarga.value = null
    }
  } catch (e) {
    const err = e as { response?: { data?: { detail?: string } | string }; message?: string }
    error.value = typeof err.response?.data === 'string'
      ? err.response.data
      : err.response?.data && typeof err.response.data === 'object' && 'detail' in err.response.data
        ? String(err.response.data.detail || 'No se pudo cargar el dashboard.')
        : err.message || 'No se pudo cargar el dashboard.'
  } finally {
    carga.value = false
  }
}

watch([filtroDependencia, filtroEstado], async () => {
  if (canSeeExecutive.value) {
    await cargarDashboardEjecutivo()
  }
})

onMounted(cargarTodo)

const kpiCards = computed(() => {
  const kpis = dashboard.value?.kpis
  if (!kpis) return []
  return [
    {
      key: 'total',
      title: 'Proyectos totales',
      value: formatNumber(kpis.total_proyectos),
      meta: `${formatNumber(kpis.proyectos_activos)} activos / ${formatNumber(kpis.proyectos_finalizados)} finalizados`,
      tone: 'neutral',
    },
    {
      key: 'avance',
      title: 'Avance promedio',
      value: formatPercent(kpis.avance_promedio),
      meta: `${formatNumber(kpis.tareas_activas)} tareas activas`,
      tone: 'info',
    },
    {
      key: 'riesgo',
      title: 'Proyectos en riesgo',
      value: formatNumber(kpis.proyectos_en_riesgo),
      meta: 'Priorizan seguimiento ejecutivo',
      tone: kpis.proyectos_en_riesgo > 0 ? 'danger' : 'success',
    },
    {
      key: 'bloqueadas',
      title: 'Tareas bloqueadas',
      value: formatNumber(kpis.tareas_bloqueadas),
      meta: 'Impactan cumplimiento y avance',
      tone: kpis.tareas_bloqueadas > 0 ? 'warning' : 'success',
    },
  ]
})

const filtrosActivosResumen = computed(() => {
  const dependencia = dependencias.value.find((item) => item.value === filtroDependencia.value)?.label
  return [
    dependencia ? `Dependencia: ${dependencia}` : 'Dependencia: Todas',
    filtroEstado.value ? `Estado: ${filtroEstado.value}` : 'Estado: Todos',
  ]
})

const insightCards = computed(() => {
  const info = dashboard.value
  if (!info) return []
  const total = Math.max(info.kpis.total_proyectos, 1)
  const finalizados = Math.round((info.kpis.proyectos_finalizados / total) * 100)
  return [
    {
      key: 'cumplimiento',
      label: 'Cumplimiento del portafolio',
      value: `${finalizados}%`,
      meta: `${formatNumber(info.kpis.proyectos_finalizados)} proyectos finalizados`,
    },
    {
      key: 'criticas',
      label: 'Alertas operativas',
      value: formatNumber(info.highlights.tareas_criticas.length),
      meta: 'Tareas criticas visibles con los filtros actuales',
    },
    {
      key: 'seguimiento',
      label: 'Seguimiento prioritario',
      value: formatNumber(info.highlights.proyectos_riesgo.length),
      meta: 'Proyectos que requieren foco de gestion',
    },
  ]
})

const estadoChartOption = computed<EChartsOption>(() => ({
  tooltip: {
    trigger: 'item',
    valueFormatter: (value) => `${value} proyecto(s)`,
  },
  legend: {
    bottom: 0,
    icon: 'circle',
  },
  color: ['#2563eb', '#f59e0b', '#16a34a', '#ef4444'],
  series: [
    {
      name: 'Estado',
      type: 'pie',
      radius: ['48%', '72%'],
      center: ['50%', '46%'],
      avoidLabelOverlap: true,
      label: {
        formatter: '{b}\n{c}',
      },
      itemStyle: {
        borderRadius: 8,
        borderColor: '#fff',
        borderWidth: 2,
      },
      data: dashboard.value?.charts.proyectos_por_estado || [],
    },
  ],
}))
const dependenciaChartOption = computed<EChartsOption>(() => ({
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'shadow' },
    valueFormatter: (value) => `${value} proyecto(s)`,
  },
  grid: { top: 16, left: 12, right: 12, bottom: 16, containLabel: true },
  xAxis: {
    type: 'value',
    axisLabel: { color: '#64748b' },
    splitLine: { lineStyle: { color: '#e2e8f0' } },
  },
  yAxis: {
    type: 'category',
    axisLabel: { color: '#334155', width: 150, overflow: 'truncate' },
    data: (dashboard.value?.charts.proyectos_por_dependencia || []).map((item) => item.name),
  },
  series: [
    {
      name: 'Proyectos',
      type: 'bar',
      barWidth: 18,
      itemStyle: { color: '#0f766e', borderRadius: [0, 8, 8, 0] },
      data: dashboard.value?.charts.proyectos_por_dependencia || [],
    },
  ],
}))

const tendenciaChartOption = computed<EChartsOption>(() => ({
  tooltip: {
    trigger: 'axis',
    formatter: (params: unknown) => {
      const rows = Array.isArray(params) ? params as Array<{ axisValueLabel?: string; data?: number }> : []
      const first = rows[0]
      return `${first?.axisValueLabel || ''}<br/>Avance promedio: ${formatPercent(first?.data || 0)}`
    },
  },
  grid: { top: 20, left: 12, right: 18, bottom: 16, containLabel: true },
  xAxis: {
    type: 'category',
    boundaryGap: false,
    axisLabel: { color: '#64748b' },
    data: (dashboard.value?.charts.tendencia_avance || []).map((item) => item.label),
  },
  yAxis: {
    type: 'value',
    min: 0,
    max: 100,
    axisLabel: { formatter: '{value}%', color: '#64748b' },
    splitLine: { lineStyle: { color: '#e2e8f0' } },
  },
  series: [
    {
      name: 'Avance promedio',
      type: 'line',
      smooth: true,
      symbolSize: 8,
      lineStyle: { width: 3, color: '#2563eb' },
      areaStyle: { color: 'rgba(37, 99, 235, 0.12)' },
      itemStyle: { color: '#2563eb' },
      data: (dashboard.value?.charts.tendencia_avance || []).map((item) => item.valor),
    },
  ],
}))

const vencimientosChartOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  legend: { bottom: 0 },
  grid: { top: 20, left: 12, right: 12, bottom: 28, containLabel: true },
  xAxis: {
    type: 'category',
    axisLabel: { color: '#64748b' },
    data: (dashboard.value?.charts.vencimientos || []).map((item) => item.categoria),
  },
  yAxis: {
    type: 'value',
    axisLabel: { color: '#64748b' },
    splitLine: { lineStyle: { color: '#e2e8f0' } },
  },
  series: [
    {
      name: 'Proyectos',
      type: 'bar',
      itemStyle: { color: '#2563eb', borderRadius: [8, 8, 0, 0] },
      data: (dashboard.value?.charts.vencimientos || []).map((item) => item.proyectos),
    },
    {
      name: 'Tareas',
      type: 'bar',
      itemStyle: { color: '#f97316', borderRadius: [8, 8, 0, 0] },
      data: (dashboard.value?.charts.vencimientos || []).map((item) => item.tareas),
    },
  ],
}))

const atrasadosChartOption = computed<EChartsOption>(() => ({
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'shadow' },
    formatter: (params: unknown) => {
      const rows = Array.isArray(params) ? params as Array<{ name?: string; data?: Record<string, unknown> }> : []
      const row = rows[0]
      const data = row?.data || {}
      return `${row?.name || ''}<br/>Atraso: ${formatNumber(data.value as number)} dia(s)<br/>Avance: ${formatPercent(data.avance as number)}`
    },
  },
  grid: { top: 16, left: 12, right: 12, bottom: 16, containLabel: true },
  xAxis: {
    type: 'value',
    axisLabel: { color: '#64748b' },
    splitLine: { lineStyle: { color: '#e2e8f0' } },
  },
  yAxis: {
    type: 'category',
    axisLabel: { color: '#334155', width: 150, overflow: 'truncate' },
    data: (dashboard.value?.charts.top_proyectos_atrasados || []).map((item) => item.name),
  },
  series: [
    {
      name: 'Dias de atraso',
      type: 'bar',
      itemStyle: { color: '#dc2626', borderRadius: [0, 8, 8, 0] },
      data: dashboard.value?.charts.top_proyectos_atrasados || [],
    },
  ],
}))

const cargaChartOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  legend: { bottom: 0 },
  grid: { top: 16, left: 12, right: 12, bottom: 28, containLabel: true },
  xAxis: {
    type: 'value',
    axisLabel: { color: '#64748b' },
    splitLine: { lineStyle: { color: '#e2e8f0' } },
  },
  yAxis: {
    type: 'category',
    axisLabel: { color: '#334155', width: 150, overflow: 'truncate' },
    data: (dashboard.value?.charts.carga_por_responsable || []).map((item) => item.name),
  },
  series: [
    {
      name: 'Proyectos',
      type: 'bar',
      stack: 'total',
      itemStyle: { color: '#2563eb' },
      data: (dashboard.value?.charts.carga_por_responsable || []).map((item) => item.proyectos || 0),
    },
    {
      name: 'Tareas',
      type: 'bar',
      stack: 'total',
      itemStyle: { color: '#0f766e' },
      data: (dashboard.value?.charts.carga_por_responsable || []).map((item) => item.tareas || 0),
    },
    {
      name: 'Bloqueadas',
      type: 'bar',
      stack: 'total',
      itemStyle: { color: '#f97316' },
      data: (dashboard.value?.charts.carga_por_responsable || []).map((item) => item.bloqueadas || 0),
    },
  ],
}))

function irAProyectos(query?: Record<string, string>) {
  router.push({ path: '/proyectos', query })
}

function irATareas(query?: Record<string, string>) {
  router.push({ path: '/tareas', query })
}

async function abrirDetalleTareaModal(tareaId: number) {
  cargandoTareaDetalle.value = true
  showTareaDetalleModal.value = true
  try {
    const [tareaRes, comentariosRes, adjuntosRes] = await Promise.all([
      api.get(`tareas/${tareaId}/`),
      api.get('comentarios-tarea/', { params: { tarea: tareaId } }),
      api.get('adjuntos-tarea/', { params: { tarea: tareaId } }),
    ])
    tareaDetalle.value = tareaRes.data as Record<string, unknown>
    comentariosTareaDetalle.value = Array.isArray(comentariosRes.data)
      ? comentariosRes.data
      : (comentariosRes.data?.results || [])
    adjuntosTareaDetalle.value = Array.isArray(adjuntosRes.data)
      ? adjuntosRes.data
      : (adjuntosRes.data?.results || [])
  } catch {
    tareaDetalle.value = null
    comentariosTareaDetalle.value = []
    adjuntosTareaDetalle.value = []
    toast.error('No se pudo cargar el detalle de la tarea.')
    showTareaDetalleModal.value = false
  } finally {
    cargandoTareaDetalle.value = false
  }
}

function cerrarDetalleTareaModal() {
  showTareaDetalleModal.value = false
  tareaDetalle.value = null
  comentariosTareaDetalle.value = []
  adjuntosTareaDetalle.value = []
}

function onEstadoChartClick(params: ChartClickParam) {
  if (params.name) irAProyectos({ estado: String(params.name) })
}

function onSecretariaChartClick(params: ChartClickParam) {
  if (typeof params.data === 'object' && params.data && params.data.id) {
    const tipo = String(params.data.filter_type || '')
    if (tipo === 'secretaria') {
      irAProyectos({ secretaria: String(params.data.id) })
      return
    }
    if (tipo === 'area') {
      irAProyectos({ area: String(params.data.id) })
    }
  }
}

function onVencimientosChartClick(params: ChartClickParam) {
  if (!params.name || !params.seriesName) return
  const categoria = String(params.name)
  if (params.seriesName === 'Proyectos') {
    const map: Record<string, string> = {
      Vencidos: 'vencidos',
      'Proximos 7 dias': 'proximos',
      'En plazo': 'en-plazo',
    }
    irAProyectos({ vencimiento: map[categoria] || '' })
    return
  }
  const map: Record<string, string> = {
    Vencidos: 'vencidas',
    'Proximos 7 dias': 'proximas',
    'En plazo': 'en-plazo',
  }
  irATareas({ vencimiento: map[categoria] || '' })
}

function onAtrasadosChartClick(params: ChartClickParam) {
  if (typeof params.data === 'object' && params.data && params.data.id) {
    router.push(`/proyectos/${params.data.id}`)
  }
}

function onCargaChartClick(params: ChartClickParam) {
  const idx = (dashboard.value?.charts.carga_por_responsable || []).find((item) => item.name === params.name)
  if (idx?.id) irATareas({ responsable: String(idx.id) })
}

async function exportarResumen() {
  if (!dashboard.value) return
  const {
    addImageFromDataUrl,
    addKeyValueRows,
    addReportHeader,
    addTable,
    createWorkbook,
    saveWorkbook,
  } = await import('@/utils/exportWorkbook')
  const workbook = await createWorkbook('Panel de control')
  const resumen = workbook.addWorksheet('Resumen', {
    views: [{ state: 'frozen', ySplit: 1 }],
  })
  let row = addReportHeader(
    resumen,
    'Panel de control',
    'Exportacion ejecutiva con indicadores, graficos y detalle operativo.',
  )
  const dependenciaActiva = dependencias.value.find((item) => item.value === filtroDependencia.value)?.label || 'Todas'
  row = addKeyValueRows(resumen, [
    ['Fecha de exportacion', new Date().toLocaleString('es-CL')],
    ['Dependencia filtrada', dependenciaActiva],
    ['Estado filtrado', filtroEstado.value || 'Todos'],
  ], row)
  row = addTable(
    resumen,
    ['Indicador', 'Valor', 'Detalle'],
    [
      ['Proyectos totales', dashboard.value.kpis.total_proyectos, `${dashboard.value.kpis.proyectos_activos} activos / ${dashboard.value.kpis.proyectos_finalizados} finalizados`],
      ['Avance promedio', `${dashboard.value.kpis.avance_promedio}%`, `${dashboard.value.kpis.tareas_activas} tareas activas`],
      ['Proyectos en riesgo', dashboard.value.kpis.proyectos_en_riesgo, 'Seguimiento prioritario'],
      ['Tareas bloqueadas', dashboard.value.kpis.tareas_bloqueadas, 'Impacto operativo'],
    ],
    row,
  )
  addTable(
    resumen,
    ['Seccion', 'Elemento', 'Valor', 'Detalle'],
    [
      ...dashboard.value.charts.proyectos_por_estado.map((item) => ['Grafico', 'Proyectos por estado', item.value, item.name]),
      ...dashboard.value.highlights.proyectos_riesgo.map((item) => ['Riesgo', item.nombre, `${item.porcentaje_avance}%`, `${item.responsable_nombre} | ${item.secretaria_nombre} | ${resumenRiesgoDias(item.dias_atraso)}`]),
      ...dashboard.value.highlights.tareas_criticas.map((item) => ['Tarea critica', item.titulo, `${item.porcentaje_avance}%`, `${item.responsable_nombre} | ${item.proyecto_nombre} | ${resumenRiesgoDias(item.dias_restantes)}`]),
    ],
    row,
  )

  const graficos = workbook.addWorksheet('Graficos')
  let chartRow = addReportHeader(graficos, 'Graficos del panel', 'Imagenes exportadas del dashboard.')
  const chartEntries = [
    ['Proyectos por estado', estadoChartRef.value?.getDataURL({ type: 'png', pixelRatio: 2, backgroundColor: '#ffffff' })],
    ['Proyectos por dependencia', dependenciaChartRef.value?.getDataURL({ type: 'png', pixelRatio: 2, backgroundColor: '#ffffff' })],
    ['Tendencia de avance', tendenciaChartRef.value?.getDataURL({ type: 'png', pixelRatio: 2, backgroundColor: '#ffffff' })],
    ['Tareas y proyectos por vencer', vencimientosChartRef.value?.getDataURL({ type: 'png', pixelRatio: 2, backgroundColor: '#ffffff' })],
    ['Top proyectos atrasados', atrasadosChartRef.value?.getDataURL({ type: 'png', pixelRatio: 2, backgroundColor: '#ffffff' })],
    ['Carga por responsable', cargaChartRef.value?.getDataURL({ type: 'png', pixelRatio: 2, backgroundColor: '#ffffff' })],
  ] as const
  for (const [title, dataUrl] of chartEntries) {
    if (!dataUrl) continue
    graficos.getCell(`A${chartRow}`).value = title
    graficos.getCell(`A${chartRow}`).font = { bold: true, size: 12 }
    await addImageFromDataUrl(graficos, dataUrl, `A${chartRow + 1}:H${chartRow + 17}`)
    chartRow += 19
  }

  const proyectos = workbook.addWorksheet('Proyectos en riesgo')
  let proyectosRow = addReportHeader(proyectos, 'Proyectos en riesgo')
  addTable(
    proyectos,
    ['Proyecto', 'Responsable', 'Dependencia', 'Estado', 'Avance %', 'Bloqueadas', 'Dias atraso', 'Fecha fin estimada'],
    dashboard.value.highlights.proyectos_riesgo.map((item) => [
      item.nombre,
      item.responsable_nombre,
      item.secretaria_nombre,
      item.estado,
      item.porcentaje_avance,
      item.tareas_bloqueadas,
      item.dias_atraso,
      item.fecha_fin_estimada || '-',
    ]),
    proyectosRow,
  )

  const tareas = workbook.addWorksheet('Tareas criticas')
  let tareasRow = addReportHeader(tareas, 'Tareas criticas')
  addTable(
    tareas,
    ['Tarea', 'Proyecto', 'Responsable', 'Estado', 'Avance %', 'Fecha vencimiento', 'Dias restantes'],
    dashboard.value.highlights.tareas_criticas.map((item) => [
      item.titulo,
      item.proyecto_nombre,
      item.responsable_nombre,
      item.estado,
      item.porcentaje_avance,
      item.fecha_vencimiento || '-',
      item.dias_restantes,
    ]),
    tareasRow,
  )

  await saveWorkbook(workbook, `panel_control_${new Date().toISOString().slice(0, 10)}.xlsx`)
  toast.success('Resumen completo exportado correctamente.')
}

const resumenCarga = computed(() => {
  const data = dashboardCarga.value
  const aCargo = Array.isArray(data?.proyectos_a_cargo) ? data?.proyectos_a_cargo || [] : []
  const participacion = Array.isArray(data?.proyectos_participacion) ? data?.proyectos_participacion || [] : []
  const tareasParticulares = Array.isArray(data?.tareas_particulares) ? data?.tareas_particulares || [] : []
  const avancePromedio = aCargo.length
    ? Math.round(aCargo.reduce((acc, item) => acc + Number(item.porcentaje_avance || 0), 0) / aCargo.length)
    : 0
  return {
    aCargo,
    participacion,
    tareasParticulares,
    cards: [
      { key: 'cargo', title: 'Proyectos a cargo', value: aCargo.length, meta: 'Responsabilidad principal', tone: 'info' },
      { key: 'participacion', title: 'En participacion', value: participacion.length, meta: 'Apoyo y seguimiento', tone: 'neutral' },
      { key: 'particulares', title: 'Tareas particulares', value: tareasParticulares.length, meta: 'Pendientes fuera de proyecto', tone: 'warning' },
      { key: 'avance', title: 'Avance promedio', value: `${avancePromedio}%`, meta: 'Sobre proyectos a cargo', tone: 'success' },
    ],
  }
})
</script>
<template>
  <div class="page dashboard-page">
    <div class="hero">
      <div>
        <h1>Panel de control</h1>
        <p class="hero-text">
          Indicadores, alertas y accesos rapidos para el seguimiento del sistema.
        </p>
      </div>
      <div class="hero-actions">
        <button type="button" class="btn-secondary" @click="cargarTodo">Actualizar</button>
        <button v-if="canSeeExecutive && dashboard" type="button" class="btn-primary" @click="exportarResumen">Exportar resumen</button>
        <button type="button" class="btn-secondary" @click="router.push('/proyectos')">Ver proyectos</button>
        <button type="button" class="btn-secondary" @click="router.push('/tareas')">Ver tareas</button>
      </div>
    </div>

    <div v-if="canSeeExecutive" class="filters-card">
      <div class="filters-grid">
        <label>
          <span>Dependencia</span>
          <select v-model="filtroDependencia">
            <option value="">Todas</option>
            <option v-for="dep in dependencias" :key="dep.value" :value="dep.value">
              {{ dep.label }}
            </option>
          </select>
        </label>
        <label>
          <span>Estado</span>
          <select v-model="filtroEstado">
            <option v-for="estado in ESTADOS_PROYECTO" :key="estado.value" :value="estado.value">
              {{ estado.label }}
            </option>
          </select>
        </label>
        <div class="filters-actions">
          <button type="button" class="btn-secondary" @click="filtroDependencia = ''; filtroEstado = ''">Limpiar filtros</button>
        </div>
      </div>
    </div>

    <div v-if="canSeeExecutive && dashboard" class="filter-summary">
      <span v-for="item in filtrosActivosResumen" :key="item" class="filter-chip">{{ item }}</span>
    </div>

    <div v-if="carga" class="state-box state-loading">
      <LoaderSpinner />
      <span>Cargando indicadores y graficos...</span>
    </div>

    <div v-else-if="error" class="state-box state-error">
      {{ error }}
    </div>

    <div v-else-if="aviso && canSeeExecutive && dashboard" class="state-box state-warning">
      {{ aviso }}
    </div>

    <template v-if="canSeeExecutive && dashboard">
      <section class="kpi-grid">
        <article v-for="card in kpiCards" :key="card.key" class="kpi-card" :class="`tone-${card.tone}`">
          <span class="kpi-title">{{ card.title }}</span>
          <strong class="kpi-value">{{ card.value }}</strong>
          <span class="kpi-meta">{{ card.meta }}</span>
        </article>
      </section>

      <section class="insight-grid">
        <article v-for="item in insightCards" :key="item.key" class="insight-card">
          <span class="insight-label">{{ item.label }}</span>
          <strong class="insight-value">{{ item.value }}</strong>
          <span class="insight-meta">{{ item.meta }}</span>
        </article>
      </section>

      <section class="chart-grid two-columns">
        <article class="chart-card">
          <div class="chart-head">
            <div>
              <h2>Proyectos por estado</h2>
              <p>Distribucion actual del portafolio.</p>
            </div>
            <button type="button" class="link-button" @click="irAProyectos()">Ver detalle</button>
          </div>
          <div v-if="dashboard.charts.proyectos_por_estado.length" class="chart-wrap">
            <VChart ref="estadoChartRef" autoresize class="chart" :option="estadoChartOption" @click="onEstadoChartClick" />
          </div>
          <div v-else class="chart-empty">No hay datos para este grafico.</div>
        </article>

        <article class="chart-card">
          <div class="chart-head">
            <div>
              <h2>Proyectos por dependencia</h2>
              <p>Concentracion de iniciativas entre areas y secretarias activas.</p>
            </div>
            <button type="button" class="link-button" @click="irAProyectos()">Ver detalle</button>
          </div>
          <div v-if="dashboard.charts.proyectos_por_dependencia.length" class="chart-wrap chart-tall">
            <VChart ref="dependenciaChartRef" autoresize class="chart" :option="dependenciaChartOption" @click="onSecretariaChartClick" />
          </div>
          <div v-else class="chart-empty">No hay datos para este grafico.</div>
        </article>
      </section>

      <section class="chart-grid two-columns">
        <article class="chart-card">
          <div class="chart-head">
            <div>
              <h2>Tendencia de avance</h2>
              <p>Evolucion mensual del avance promedio registrado.</p>
            </div>
          </div>
          <div v-if="dashboard.charts.tendencia_avance.length" class="chart-wrap">
            <VChart ref="tendenciaChartRef" autoresize class="chart" :option="tendenciaChartOption" />
          </div>
          <div v-else class="chart-empty">Todavia no hay historial suficiente para mostrar tendencia.</div>
        </article>

        <article class="chart-card">
          <div class="chart-head">
            <div>
              <h2>Tareas y proyectos por vencer</h2>
              <p>Semaforo operativo para priorizar seguimiento.</p>
            </div>
            <button type="button" class="link-button" @click="irATareas()">Ver tareas</button>
          </div>
          <div v-if="dashboard.charts.vencimientos.length" class="chart-wrap">
            <VChart ref="vencimientosChartRef" autoresize class="chart" :option="vencimientosChartOption" @click="onVencimientosChartClick" />
          </div>
          <div v-else class="chart-empty">No hay datos para este grafico.</div>
        </article>
      </section>

      <section class="chart-grid two-columns">
        <article class="chart-card">
          <div class="chart-head">
            <div>
              <h2>Top proyectos atrasados</h2>
              <p>Ranking de los proyectos con mayor desvio de plazo.</p>
            </div>
          </div>
          <div v-if="dashboard.charts.top_proyectos_atrasados.length" class="chart-wrap chart-tall">
            <VChart ref="atrasadosChartRef" autoresize class="chart" :option="atrasadosChartOption" @click="onAtrasadosChartClick" />
          </div>
          <div v-else class="chart-empty">No hay proyectos atrasados para mostrar.</div>
        </article>

        <article class="chart-card">
          <div class="chart-head">
            <div>
              <h2>Carga por responsable</h2>
              <p>Distribucion combinada de proyectos, tareas y bloqueos.</p>
            </div>
          </div>
          <div v-if="dashboard.charts.carga_por_responsable.length" class="chart-wrap chart-tall">
            <VChart ref="cargaChartRef" autoresize class="chart" :option="cargaChartOption" @click="onCargaChartClick" />
          </div>
          <div v-else class="chart-empty">No hay responsables con carga visible.</div>
        </article>
      </section>

      <section class="detail-grid two-columns">
        <article class="detail-card">
          <div class="detail-head">
            <div>
              <h2>Proyectos en riesgo</h2>
              <p>Casos que requieren foco de direccion.</p>
            </div>
            <button type="button" class="link-button" @click="irAProyectos({ vencimiento: 'vencidos' })">Ver todos</button>
          </div>
          <div v-if="dashboard.highlights.proyectos_riesgo.length" class="table-shell">
            <table>
              <thead>
                <tr>
                  <th>Proyecto</th>
                  <th>Responsable</th>
                  <th class="col-avance">Avance</th>
                  <th>Situacion</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in dashboard.highlights.proyectos_riesgo" :key="item.id">
                  <td>
                    <strong>{{ item.nombre }}</strong>
                    <small>{{ item.secretaria_nombre }}</small>
                  </td>
                  <td>{{ item.responsable_nombre }}</td>
                  <td class="col-avance">{{ formatPercent(item.porcentaje_avance) }}</td>
                  <td>
                    <span class="status-badge status-danger">
                      {{ item.tareas_bloqueadas ? `${item.tareas_bloqueadas} bloqueada(s)` : resumenRiesgoDias(item.dias_atraso) }}
                    </span>
                  </td>
                  <td>
                    <button type="button" class="link-button" @click="router.push(`/proyectos/${item.id}`)">Ver detalle</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="chart-empty">No se detectaron proyectos en riesgo con los filtros actuales.</div>
        </article>

        <article class="detail-card">
          <div class="detail-head">
            <div>
              <h2>Tareas criticas</h2>
              <p>Vencidas, proximas o bloqueadas.</p>
            </div>
            <button type="button" class="link-button" @click="irATareas()">Ver todas</button>
          </div>
          <div v-if="dashboard.highlights.tareas_criticas.length" class="table-shell">
            <table>
              <thead>
                <tr>
                  <th>Tarea</th>
                  <th>Proyecto</th>
                  <th>Responsable</th>
                  <th>Estado</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in dashboard.highlights.tareas_criticas" :key="item.id">
                  <td>
                    <strong>{{ item.titulo }}</strong>
                    <small>{{ formatDate(item.fecha_vencimiento) }}</small>
                  </td>
                  <td>{{ item.proyecto_nombre }}</td>
                  <td>{{ item.responsable_nombre }}</td>
                  <td>
                    <span class="status-badge" :class="item.dias_restantes < 0 || item.estado === 'Bloqueada' ? 'status-danger' : 'status-warning'">
                      {{ item.estado === 'Bloqueada' ? 'Bloqueada' : resumenRiesgoDias(item.dias_restantes) }}
                    </span>
                  </td>
                  <td>
                    <button type="button" class="link-button" @click="abrirDetalleTareaModal(item.id)">Ver detalle</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="chart-empty">No se detectaron tareas criticas con los filtros actuales.</div>
        </article>
      </section>
    </template>

    <template v-else-if="isCarga && dashboardCarga">
      <section class="kpi-grid">
        <article v-for="card in resumenCarga.cards" :key="card.key" class="kpi-card" :class="`tone-${card.tone}`">
          <span class="kpi-title">{{ card.title }}</span>
          <strong class="kpi-value">{{ card.value }}</strong>
          <span class="kpi-meta">{{ card.meta }}</span>
        </article>
      </section>

      <section class="detail-grid two-columns">
        <article class="detail-card">
          <div class="detail-head">
            <div>
              <h2>Proyectos a cargo</h2>
              <p>Sus frentes de responsabilidad directa.</p>
            </div>
          </div>
          <div v-if="resumenCarga.aCargo.length" class="table-shell">
            <table>
              <thead>
                <tr>
                  <th>Proyecto</th>
                  <th class="col-avance">Avance</th>
                  <th>Estado</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in resumenCarga.aCargo" :key="String(item.id)">
                  <td>{{ item.nombre }}</td>
                  <td class="col-avance">{{ formatPercent(Number(item.porcentaje_avance || 0)) }}</td>
                  <td>{{ item.estado || '-' }}</td>
                  <td>
                    <button type="button" class="link-button" @click="router.push(`/proyectos/${item.id}`)">Ver detalle</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="chart-empty">No tiene proyectos asignados como responsable principal.</div>
        </article>

        <article class="detail-card">
          <div class="detail-head">
            <div>
              <h2>Tareas particulares</h2>
              <p>Actividades fuera de proyecto con seguimiento directo.</p>
            </div>
          </div>
          <div v-if="resumenCarga.tareasParticulares.length" class="table-shell">
            <table>
              <thead>
                <tr>
                  <th>Tarea</th>
                  <th class="col-avance">Avance</th>
                  <th>Estado</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in resumenCarga.tareasParticulares" :key="String(item.id)">
                  <td>{{ item.titulo }}</td>
                  <td class="col-avance">{{ formatPercent(Number(item.porcentaje_avance || 0)) }}</td>
                  <td>{{ item.estado || '-' }}</td>
                  <td>
                    <button type="button" class="link-button" @click="abrirDetalleTareaModal(Number(item.id))">Ver detalle</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="chart-empty">No hay tareas particulares pendientes.</div>
        </article>
      </section>
    </template>

    <div v-if="showTareaDetalleModal" class="modal-overlay" @click.self="cerrarDetalleTareaModal">
      <div class="modal modal-wide modal-ver">
        <h2>Detalle de la tarea</h2>
        <div v-if="cargandoTareaDetalle" class="modal-loading">
          <LoaderSpinner />
          <span>Cargando detalle...</span>
        </div>
        <template v-else-if="tareaDetalle">
          <div class="detalle-content">
            <div class="detalle-row">
              <span class="detalle-label">Titulo</span>
              <span class="detalle-valor">{{ tareaDetalle.titulo }}</span>
            </div>
            <div class="detalle-row" v-if="tareaDetalle.descripcion">
              <span class="detalle-label">Descripcion</span>
              <p class="detalle-valor detalle-desc">{{ tareaDetalle.descripcion }}</p>
            </div>
            <div class="detalle-grid">
              <div class="detalle-row" v-if="tareaDetalle.tarea_padre_nombre">
                <span class="detalle-label">Tarea padre</span>
                <span class="detalle-valor">{{ tareaDetalle.tarea_padre_nombre }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Proyecto</span>
                <span class="detalle-valor">{{ tareaDetalle.proyecto_nombre || 'Sin proyecto' }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Area / Secretaria</span>
                <span class="detalle-valor">{{ tareaDetalle.organizacion_nombre || tareaDetalle.area_nombre || tareaDetalle.secretaria_nombre || '-' }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Responsable</span>
                <span class="detalle-valor">{{ tareaDetalle.responsable_nombre || '-' }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Estado</span>
                <span class="detalle-valor">{{ tareaDetalle.estado }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Avance</span>
                <span class="detalle-valor">{{ tareaDetalle.porcentaje_avance }}%</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Prioridad</span>
                <span class="detalle-valor">{{ tareaDetalle.prioridad || '-' }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Fecha inicio</span>
                <span class="detalle-valor">{{ tareaDetalle.fecha_inicio || '-' }}</span>
              </div>
              <div class="detalle-row">
                <span class="detalle-label">Fecha vencimiento</span>
                <span class="detalle-valor">{{ tareaDetalle.fecha_vencimiento || '-' }}</span>
              </div>
            </div>
          </div>

          <div class="detalle-section">
            <h3>Comentarios</h3>
            <div v-if="comentariosTareaDetalle.length" class="comentarios-lista">
              <div v-for="c in comentariosTareaDetalle" :key="String(c.id)" class="comentario-item">
                <div class="comentario-header">
                  <span class="comentario-meta">{{ c.usuario_nombre }} ? {{ c.fecha ? new Date(String(c.fecha)).toLocaleString('es-CL') : '-' }}</span>
                  <span v-if="c.editado_leyenda" class="editado-leyenda">{{ c.editado_leyenda }}</span>
                </div>
                <p class="comentario-texto">{{ c.texto }}</p>
              </div>
            </div>
            <p v-else class="detalle-empty">No hay comentarios registrados.</p>
          </div>

          <div class="detalle-section">
            <h3>Adjuntos</h3>
            <div v-if="adjuntosTareaDetalle.length" class="adjuntos-lista">
              <div v-for="a in adjuntosTareaDetalle" :key="String(a.id)" class="adjunto-item">
                <a v-if="a.url" :href="String(a.url)" target="_blank" rel="noopener" class="adjunto-link">Adjunto: {{ a.nombre_original }}</a>
                <span v-else>Adjunto: {{ a.nombre_original }}</span>
              </div>
            </div>
            <p v-else class="detalle-empty">No hay adjuntos registrados.</p>
          </div>
        </template>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="cerrarDetalleTareaModal">Cerrar</button>
        </div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}
.hero,
.filters-card,
.chart-card,
.detail-card,
.kpi-card,
.state-box {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
}
.hero {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  padding: 1.5rem;
}
.hero h1 {
  margin: 0 0 0.4rem;
  color: #0f172a;
}
.hero-text {
  margin: 0;
  color: #475569;
  max-width: 60rem;
}
.hero-actions {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}
.filters-card {
  padding: 1rem 1.25rem;
}
.filter-summary {
  display: flex;
  gap: 0.6rem;
  flex-wrap: wrap;
}
.filter-chip {
  display: inline-flex;
  align-items: center;
  padding: 0.45rem 0.8rem;
  border-radius: 999px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.85rem;
  font-weight: 600;
  border: 1px solid #bfdbfe;
}
.filters-grid {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 1rem;
  align-items: end;
}
.filters-grid label {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  color: #334155;
  font-weight: 600;
}
.filters-grid select {
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 0.7rem 0.8rem;
  font: inherit;
}
.filters-actions {
  display: flex;
  justify-content: flex-end;
}
.kpi-grid,
.chart-grid,
.detail-grid {
  display: grid;
  gap: 1rem;
}
.kpi-grid {
  grid-template-columns: repeat(4, minmax(0, 1fr));
}
.two-columns {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}
.insight-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
}
.kpi-card {
  padding: 1.1rem 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
}
.kpi-title {
  font-size: 0.92rem;
  color: #475569;
}
.kpi-value {
  font-size: 2rem;
  line-height: 1;
  color: #0f172a;
}
.kpi-meta {
  color: #64748b;
  font-size: 0.9rem;
}
.tone-neutral { border-top: 4px solid #2563eb; }
.tone-info { border-top: 4px solid #0ea5e9; }
.tone-success { border-top: 4px solid #16a34a; }
.tone-warning { border-top: 4px solid #f59e0b; }
.tone-danger { border-top: 4px solid #dc2626; }
.insight-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1rem 1.1rem;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}
.insight-label {
  color: #475569;
  font-size: 0.9rem;
}
.insight-value {
  color: #0f172a;
  font-size: 1.7rem;
  line-height: 1;
}
.insight-meta {
  color: #64748b;
  font-size: 0.85rem;
}
.chart-card,
.detail-card {
  padding: 1rem 1.1rem;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}
.chart-card:hover,
.detail-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 18px 32px rgba(15, 23, 42, 0.08);
}
.chart-head,
.detail-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 0.8rem;
}
.chart-head h2,
.detail-head h2 {
  margin: 0;
  font-size: 1.05rem;
  color: #0f172a;
}
.chart-head p,
.detail-head p {
  margin: 0.25rem 0 0;
  color: #64748b;
  font-size: 0.92rem;
}
.chart-wrap {
  height: 340px;
}
.chart-tall {
  height: 400px;
}
.chart {
  width: 100%;
  height: 100%;
}
.chart-empty,
.state-box {
  min-height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #64748b;
}
.state-loading {
  gap: 0.75rem;
  padding: 1.5rem;
}
.state-error {
  color: #b91c1c;
  padding: 1.5rem;
}
.state-warning {
  color: #92400e;
  background: #fffbeb;
  padding: 1rem 1.25rem;
  min-height: auto;
}
.table-shell {
  overflow-x: auto;
}
table {
  width: 100%;
  border-collapse: collapse;
}
th,
td {
  padding: 0.8rem 0.65rem;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
  vertical-align: top;
}
th {
  font-size: 0.82rem;
  text-transform: uppercase;
  letter-spacing: 0.02em;
  color: #64748b;
}
.table-shell th.col-avance,
.table-shell td.col-avance {
  text-align: center;
}
td strong {
  display: block;
  color: #0f172a;
}
td small {
  color: #64748b;
}
.status-badge {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.28rem 0.6rem;
  font-size: 0.82rem;
  font-weight: 700;
}
.status-danger {
  background: #fee2e2;
  color: #b91c1c;
}
.status-warning {
  background: #fef3c7;
  color: #92400e;
}
.btn-primary,
.btn-secondary,
.link-button {
  border: none;
  border-radius: 10px;
  padding: 0.75rem 1rem;
  cursor: pointer;
  font-weight: 700;
}
.btn-primary {
  background: #2563eb;
  color: #fff;
}
.btn-secondary {
  background: #e2e8f0;
  color: #0f172a;
}
.link-button {
  background: transparent;
  color: #2563eb;
  padding: 0;
}
.link-button:hover {
  color: #1d4ed8;
}
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
  padding: 1rem;
}
.modal {
  width: min(920px, 100%);
  max-height: 90vh;
  overflow-y: auto;
  background: #fff;
  border-radius: 16px;
  padding: 1.25rem;
  box-shadow: 0 24px 40px rgba(15, 23, 42, 0.25);
}
.modal h2 {
  margin: 0 0 1rem;
  color: #0f172a;
}
.modal-loading {
  min-height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  color: #64748b;
}
.detalle-content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1rem;
}
.detalle-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}
.detalle-row {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.detalle-label {
  font-size: 0.8rem;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
}
.detalle-valor {
  color: #0f172a;
}
.detalle-desc {
  white-space: pre-wrap;
  line-height: 1.5;
}
.detalle-section {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}
.detalle-section h3 {
  margin: 0 0 0.75rem;
  color: #334155;
  font-size: 1rem;
}
.detalle-empty {
  margin: 0;
  color: #64748b;
}
.comentarios-lista,
.adjuntos-lista {
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
}
.comentario-item {
  background: #f8fafc;
  border-radius: 10px;
  padding: 0.75rem;
}
.comentario-header {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 0.35rem;
}
.comentario-meta,
.editado-leyenda {
  font-size: 0.8rem;
  color: #64748b;
}
.comentario-texto {
  margin: 0;
  color: #0f172a;
}
.adjunto-item {
  display: flex;
  align-items: center;
}
.adjunto-link {
  color: #2563eb;
  text-decoration: none;
}
.adjunto-link:hover {
  text-decoration: underline;
}
.modal-actions {
  margin-top: 1rem;
  display: flex;
  justify-content: flex-end;
}
.btn-cancel {
  border: none;
  border-radius: 10px;
  padding: 0.75rem 1rem;
  background: #e2e8f0;
  color: #0f172a;
  cursor: pointer;
  font-weight: 700;
}
@media (max-width: 1100px) {
  .kpi-grid,
  .two-columns,
  .filters-grid,
  .insight-grid {
    grid-template-columns: 1fr;
  }
  .detalle-grid {
    grid-template-columns: 1fr;
  }
  .hero {
    flex-direction: column;
  }
  .hero-actions {
    justify-content: flex-start;
  }
}
</style>
