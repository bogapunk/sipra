<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '@/services/api'
import { exportToCsv } from '@/utils/exportCsv'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconPlus from '@/components/icons/IconPlus.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconEye from '@/components/icons/IconEye.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import { useAuth } from '@/composables/useAuth'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { invalidateApiCache } from '@/services/api'
import { useModalClose } from '@/composables/useModalClose'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import { extraerMensajeError } from '@/utils/apiError'
import { formatFechaCorta } from '@/utils/fecha'
import EmptyState from '@/components/EmptyState.vue'
import { flattenTasksTree, fetchAllTareasProyecto } from '@/utils/taskTree'

const route = useRoute()
const router = useRouter()
const { isVisualizador, user } = useAuth()
const toast = useToast()
const { confirmDelete } = useConfirmDelete()
const proyectos = ref<Record<string, unknown>[]>([])
const carga = ref(false)
const showForm = ref(false)
const editingId = ref<number | null>(null)
const showAsignarModal = ref(false)
const proyectoAsignar = ref<Record<string, unknown> | null>(null)
const tipoAsignar = ref<'area' | 'secretaria'>('area')
const areasSeleccionadasAsignar = ref<number[]>([])
const secretariasSeleccionadasAsignar = ref<number[]>([])
const guardandoAsignar = ref(false)
const buscarProyecto = ref('')
const paginaActual = ref(1)
const tamanioPagina = 20
const totalProyectos = ref(0)
const soporteCargado = ref(false)
let busquedaTimer: ReturnType<typeof setTimeout> | null = null
type TipoDependencia = 'area' | 'secretaria'
type CategoriaGasto = 'Equipamiento' | 'Gastos operativos y logisticos' | 'Dotacion'
type FuenteFinanciamiento = 'Provincial' | 'Nacional' | 'CFI' | 'Otros' | 'Sin Erogacion'
type PresupuestoItemForm = {
  id: number | null
  categoria_gasto: CategoriaGasto
  monto: string
  detalle: string
  orden: number
}
type EstadoAvanceObjetivo = 'No iniciado' | 'En progreso' | 'Finalizado'
type ObjetivoProyectoForm = {
  id: number
  estado_avance: EstadoAvanceObjetivo
}

const ESTADOS_AVANCE_OBJETIVO: EstadoAvanceObjetivo[] = ['No iniciado', 'En progreso', 'Finalizado']
const AVANCE_POR_ESTADO_OBJETIVO: Record<EstadoAvanceObjetivo, number> = {
  'No iniciado': 0,
  'En progreso': 50,
  'Finalizado': 100,
}

const FUENTE_SIN_EROGACION: FuenteFinanciamiento = 'Sin Erogacion'
const CATEGORIAS_GASTO: CategoriaGasto[] = ['Equipamiento', 'Gastos operativos y logisticos', 'Dotacion']
const FUENTES_FINANCIAMIENTO: FuenteFinanciamiento[] = ['Provincial', 'Nacional', 'CFI', 'Otros', 'Sin Erogacion']
const currencyFormatter = new Intl.NumberFormat('es-AR', {
  style: 'currency',
  currency: 'ARS',
  maximumFractionDigits: 2,
})

function normalizarMontoInput(value: string | number | null | undefined): string {
  const soloDigitos = String(value ?? '').replace(/\D/g, '')
  if (!soloDigitos) return ''
  return soloDigitos.replace(/\B(?=(\d{3})+(?!\d))/g, '.')
}

function montoToNumber(value: string | number | null | undefined): number {
  const limpio = String(value ?? '').replace(/\./g, '').replace(/\D/g, '')
  return limpio ? Number(limpio) : 0
}

function crearItemPresupuesto(overrides: Partial<PresupuestoItemForm> = {}): PresupuestoItemForm {
  return {
    id: null,
    categoria_gasto: 'Equipamiento',
    monto: '',
    detalle: '',
    orden: 0,
    ...overrides,
  }
}

const form = ref({
  nombre: '',
  descripcion: '',
  fecha_inicio: '',
  fecha_fin_estimada: '',
  estado: 'Activo',
  presupuesto_total: '',
  fuente_financiamiento: 'Provincial' as FuenteFinanciamiento,
  creado_por: 1,
  usuario_responsable: null as number | null,
  tipoDependencia: 'area' as TipoDependencia,
  areas_ids: [] as number[],
  secretarias_ids: [] as number[],
  equipo: [] as number[],
  presupuesto_items: [] as PresupuestoItemForm[],
  objetivos: [] as ObjetivoProyectoForm[],
})
const objetivosCatalogo = ref<Record<string, unknown>[]>([])
const buscarObjetivo = ref('')
const cargaObjetivosCatalogo = ref(false)
const usuarios = ref<Record<string, unknown>[]>([])
const usuariosParaResponsable = ref<Record<string, unknown>[]>([])
const cargaUsuariosResponsable = ref(false)
const secretarias = ref<Record<string, unknown>[]>([])
const areas = ref<Record<string, unknown>[]>([])

function parseProyectos(res: unknown): Record<string, unknown>[] {
  if (!res || typeof res !== 'object') return []
  const raw = (res as { data?: unknown }).data
  let lista: Record<string, unknown>[] = []
  if (Array.isArray(raw)) lista = raw as Record<string, unknown>[]
  else if (raw && typeof raw === 'object' && 'results' in (raw as object)) {
    lista = ((raw as { results: unknown[] }).results || []) as Record<string, unknown>[]
  }
  const visto = new Set<number>()
  return lista.filter((p) => {
    const id = Number(p.id)
    if (!Number.isFinite(id) || visto.has(id)) return false
    visto.add(id)
    return true
  })
}

function parseCountFromResponse(res: unknown): number {
  if (!res || typeof res !== 'object') return 0
  const raw = (res as { data?: unknown }).data
  if (raw && typeof raw === 'object' && 'count' in (raw as object)) {
    const count = Number((raw as { count?: unknown }).count)
    return Number.isFinite(count) ? count : 0
  }
  return Array.isArray(raw) ? raw.length : 0
}

function hasNextPage(res: unknown): boolean {
  if (!res || typeof res !== 'object') return false
  const raw = (res as { data?: unknown }).data
  return Boolean(raw && typeof raw === 'object' && 'next' in (raw as object) && (raw as { next?: unknown }).next)
}

function parseProyectoDetalle(res: unknown): Record<string, unknown> {
  if (!res || typeof res !== 'object') return {}
  const raw = (res as { data?: unknown }).data
  if (raw && typeof raw === 'object' && !Array.isArray(raw)) return raw as Record<string, unknown>
  return {}
}

function formatCurrency(value: number): string {
  return currencyFormatter.format(Number.isFinite(value) ? value : 0)
}

function reordenarPresupuesto() {
  form.value.presupuesto_items = form.value.presupuesto_items.map((item, index) => ({
    ...item,
    orden: index,
  }))
}

function aplicarReglasPresupuesto(item: PresupuestoItemForm, index?: number) {
  if (typeof index === 'number') item.orden = index
  item.monto = normalizarMontoInput(item.monto)
}

function agregarItemPresupuesto() {
  form.value.presupuesto_items.push(
    crearItemPresupuesto({ orden: form.value.presupuesto_items.length }),
  )
}

function eliminarItemPresupuesto(index: number) {
  form.value.presupuesto_items.splice(index, 1)
  reordenarPresupuesto()
}

function onCategoriaPresupuestoChange(item: PresupuestoItemForm, index: number) {
  aplicarReglasPresupuesto(item, index)
}

function onPresupuestoTotalInput(event: Event) {
  const target = event.target as HTMLInputElement
  form.value.presupuesto_total = normalizarMontoInput(target.value)
}

function onMontoItemInput(event: Event, item: PresupuestoItemForm, index: number) {
  const target = event.target as HTMLInputElement
  item.monto = normalizarMontoInput(target.value)
  aplicarReglasPresupuesto(item, index)
}

function mapPresupuestoItems(raw: unknown): PresupuestoItemForm[] {
  if (!Array.isArray(raw) || !raw.length) return []
  return raw.map((entry, index) => {
    const item = entry as Record<string, unknown>
    const mapped = crearItemPresupuesto({
      id: typeof item.id === 'number' ? item.id : null,
      categoria_gasto: (item.categoria_gasto as CategoriaGasto) || 'Equipamiento',
      monto: normalizarMontoInput(item.monto as string | number | null | undefined),
      detalle: String(item.detalle || ''),
      orden: typeof item.orden === 'number' ? item.orden : index,
    })
    aplicarReglasPresupuesto(mapped, index)
    return mapped
  })
}

function buildPresupuestoPayload(): Record<string, unknown>[] | null {
  const payload: Record<string, unknown>[] = []
  let orden = 0
  for (let index = 0; index < form.value.presupuesto_items.length; index++) {
    const item = form.value.presupuesto_items[index]
    aplicarReglasPresupuesto(item, index)
    const detalle = item.detalle.trim()
    const monto = Math.max(0, montoToNumber(item.monto))
    if (monto <= 0 && !detalle) {
      continue
    }
    payload.push({
      id: item.id ?? undefined,
      categoria_gasto: item.categoria_gasto,
      monto,
      detalle,
      orden: orden++,
    })
  }

  const totalGastos = payload.reduce((acc, item) => acc + (Number(item.monto || 0) || 0), 0)
  const presupuestoTotal = Math.max(0, montoToNumber(form.value.presupuesto_total))
  if (form.value.fuente_financiamiento === FUENTE_SIN_EROGACION && presupuestoTotal !== 0) {
    toast.error('Si la fuente de financiamiento es Sin erogación, el presupuesto total debe ser 0.')
    return null
  }
  if (totalGastos > presupuestoTotal) {
    toast.error('La suma de los gastos no puede superar el presupuesto total del proyecto.')
    return null
  }

  return payload
}

const presupuestoCargado = computed(() =>
  form.value.presupuesto_items.reduce((acc, item) => {
    aplicarReglasPresupuesto(item)
    const monto = montoToNumber(item.monto)
    return acc + (Number.isFinite(monto) ? monto : 0)
  }, 0),
)

const presupuestoDisponible = computed(() =>
  Math.max(0, montoToNumber(form.value.presupuesto_total) - presupuestoCargado.value),
)

const avanceObjetivosPreview = computed(() => {
  const lista = form.value.objetivos
  if (!lista.length) return 0
  const sum = lista.reduce((acc, o) => acc + (AVANCE_POR_ESTADO_OBJETIVO[o.estado_avance] || 0), 0)
  return Math.round(sum / lista.length)
})

const objetivosCatalogoFiltrados = computed(() => {
  const q = buscarObjetivo.value.trim().toLowerCase()
  if (!q) return objetivosCatalogo.value
  return objetivosCatalogo.value.filter((o) => {
    const desc = String(o.descripcion || '').toLowerCase()
    const prog = String(o.programa_nombre || '').toLowerCase()
    return desc.includes(q) || prog.includes(q)
  })
})

function mapObjetivosAsignados(raw: unknown): ObjetivoProyectoForm[] {
  if (!Array.isArray(raw)) return []
  return raw
    .map((entry) => {
      const item = entry as Record<string, unknown>
      const id = Number(item.objetivo_id ?? item.id)
      if (!Number.isFinite(id)) return null
      const estado = String(item.estado_avance || 'No iniciado') as EstadoAvanceObjetivo
      return {
        id,
        estado_avance: ESTADOS_AVANCE_OBJETIVO.includes(estado) ? estado : 'No iniciado',
      }
    })
    .filter(Boolean) as ObjetivoProyectoForm[]
}

async function cargarObjetivosCatalogo() {
  cargaObjetivosCatalogo.value = true
  try {
    objetivosCatalogo.value = await fetchAllPages('objetivos-estrategicos/')
  } catch {
    try {
      const res = await api.get('objetivos-estrategicos/')
      objetivosCatalogo.value = parseProyectos(res)
    } catch {
      objetivosCatalogo.value = []
    }
  } finally {
    cargaObjetivosCatalogo.value = false
  }
}

function isObjetivoSeleccionado(id: number): boolean {
  return form.value.objetivos.some((o) => o.id === id)
}

function toggleObjetivo(id: number) {
  const idx = form.value.objetivos.findIndex((o) => o.id === id)
  if (idx >= 0) {
    form.value.objetivos = form.value.objetivos.filter((o) => o.id !== id)
    return
  }
  form.value.objetivos = [...form.value.objetivos, { id, estado_avance: 'No iniciado' }]
}

function setEstadoObjetivo(id: number, estado: EstadoAvanceObjetivo) {
  form.value.objetivos = form.value.objetivos.map((o) =>
    o.id === id ? { ...o, estado_avance: estado } : o,
  )
}

function descripcionObjetivo(id: number): string {
  const cat = objetivosCatalogo.value.find((o) => Number(o.id) === id)
  if (cat) return String(cat.descripcion || `Objetivo ${id}`)
  const sel = form.value.objetivos.find((o) => o.id === id)
  if (sel) {
    const fromApi = objetivosCatalogo.value.find((o) => Number(o.id) === sel.id)
    return String(fromApi?.descripcion || `Objetivo ${id}`)
  }
  return `Objetivo ${id}`
}

function programaObjetivo(id: number): string {
  const cat = objetivosCatalogo.value.find((o) => Number(o.id) === id)
  return cat ? String(cat.programa_nombre || '') : ''
}

function claseEstadoAvanceObjetivo(estado: EstadoAvanceObjetivo): string {
  if (estado === 'Finalizado') return 'obj-estado-finalizado'
  if (estado === 'En progreso') return 'obj-estado-progreso'
  return 'obj-estado-no-iniciado'
}

function buildProjectParams(page = paginaActual.value): Record<string, string | number> {
  const secretariaId = route.query.secretaria as string | undefined
  const areaId = route.query.area as string | undefined
  const estado = route.query.estado as string | undefined
  const vencimiento = route.query.vencimiento as string | undefined
  const params: Record<string, string | number> = {
    page,
    page_size: tamanioPagina,
  }
  if (secretariaId) params.secretaria = secretariaId
  if (areaId) params.area = areaId
  if (estado) params.estado = estado
  if (vencimiento) params.vencimiento = vencimiento
  if (buscarProyecto.value.trim()) params.search = buscarProyecto.value.trim()
  return params
}

async function fetchAllPages(
  endpoint: string,
  baseParams: Record<string, string | number> = {},
): Promise<Record<string, unknown>[]> {
  const acumulado: Record<string, unknown>[] = []
  let page = 1
  while (true) {
    const res = await api.get(endpoint, { params: { ...baseParams, page, page_size: 100 } })
    acumulado.push(...parseProyectos(res))
    if (!hasNextPage(res)) break
    page += 1
  }
  return acumulado
}

async function cargarDatosSoporte() {
  if (soporteCargado.value) return
  const [uRes, sRes, aRes] = await Promise.all([
    api.get('usuarios/selector/').catch(() => ({ data: [] })),
    api.get('secretarias/').catch(() => ({ data: [] })),
    api.get('areas/').catch(() => ({ data: [] })),
  ])
  usuarios.value = Array.isArray(uRes.data) ? uRes.data : []
  secretarias.value = Array.isArray(sRes.data) ? sRes.data : []
  areas.value = Array.isArray(aRes.data) ? aRes.data : []
  soporteCargado.value = true
}

const load = async (page = paginaActual.value) => {
  carga.value = true
  try {
    paginaActual.value = page
    const pRes = await api.get('dashboard/proyectos/', { params: buildProjectParams(page) }).catch(
      () => api.get('proyectos/', { params: buildProjectParams(page) }),
    )
    proyectos.value = parseProyectos(pRes)
    totalProyectos.value = parseCountFromResponse(pRes)
  } catch {
    proyectos.value = []
    totalProyectos.value = 0
  } finally {
    carga.value = false
  }
}

const secretariaFiltroNombre = computed(() => {
  const id = route.query.secretaria
  if (!id) return null
  const s = secretarias.value.find((x: Record<string, unknown>) => String(x.id) === id)
  return s ? `${(s.codigo as string) || ''} - ${(s.nombre as string) || ''}` : null
})

const areaFiltroNombre = computed(() => {
  const id = route.query.area
  if (!id) return null
  const area = areas.value.find((x: Record<string, unknown>) => String(x.id) === id)
  return area ? String(area.nombre || '') : null
})

const filtroRutaTexto = computed(() => {
  const partes: string[] = []
  if (secretariaFiltroNombre.value) partes.push(`Secretaría: ${secretariaFiltroNombre.value}`)
  if (areaFiltroNombre.value) partes.push(`Área: ${areaFiltroNombre.value}`)
  if (typeof route.query.estado === 'string' && route.query.estado) partes.push(`Estado: ${route.query.estado}`)
  if (typeof route.query.vencimiento === 'string' && route.query.vencimiento) {
    const map: Record<string, string> = {
      'vencidos': 'Vencidos',
      'proximos': 'Próximos 7 días',
      'en-plazo': 'En plazo',
    }
    partes.push(`Vencimiento: ${map[route.query.vencimiento] || route.query.vencimiento}`)
  }
  return partes.join(' | ')
})

const proyectosFiltrados = computed(() => proyectos.value)

/** Si hay al menos un proyecto transversal en la página, se muestra columna y tabla expandible de tareas. */
const hayTransversalEnLista = computed(() => proyectosFiltrados.value.some((p) => p.es_transversal))

const expandedTransversal = ref<Record<number, boolean>>({})
const tareasPorProyecto = ref<Record<number, Record<string, unknown>[]>>({})
const cargandoTareasExpand = ref<Record<number, boolean>>({})
/** Evita recargar al reexpandir si ya se obtuvo la lista (aunque esté vacía). */
const tareasExpandYaPedidas = ref<Set<number>>(new Set())

async function toggleExpandTransversal(id: number, ev: Event) {
  ev.stopPropagation()
  const abrir = !expandedTransversal.value[id]
  expandedTransversal.value = { ...expandedTransversal.value, [id]: abrir }
  if (abrir && !tareasExpandYaPedidas.value.has(id) && !cargandoTareasExpand.value[id]) {
    cargandoTareasExpand.value = { ...cargandoTareasExpand.value, [id]: true }
    try {
      const list = await fetchAllTareasProyecto(id)
      tareasPorProyecto.value = { ...tareasPorProyecto.value, [id]: list }
      tareasExpandYaPedidas.value = new Set([...tareasExpandYaPedidas.value, id])
    } catch {
      toast.error('No se pudieron cargar las tareas del proyecto.')
    } finally {
      cargandoTareasExpand.value = { ...cargandoTareasExpand.value, [id]: false }
    }
  }
}

function filasTareasExpandidas(proyectoId: number) {
  return flattenTasksTree(tareasPorProyecto.value[proyectoId] || [])
}

function irVerTareaDesdeProyectos(proyectoId: number, tareaId: number) {
  router.push({ path: '/tareas', query: { proyecto: String(proyectoId), ver: String(tareaId) } })
}

function irEditarTareaDesdeProyectos(proyectoId: number, tareaId: number) {
  router.push({ path: '/tareas', query: { proyecto: String(proyectoId), editar: String(tareaId) } })
}

async function eliminarTareaDesdeProyectos(proyectoId: number, tareaId: number) {
  if (!(await confirmDelete())) return
  try {
    await api.delete(`tareas/${tareaId}/`)
    invalidateApiCache('tareas')
    toast.success('Tarea eliminada.')
    const list = await fetchAllTareasProyecto(proyectoId)
    tareasPorProyecto.value = { ...tareasPorProyecto.value, [proyectoId]: list }
    tareasExpandYaPedidas.value = new Set([...tareasExpandYaPedidas.value, proyectoId])
  } catch (e) {
    toast.error(extraerMensajeError(e, 'No se pudo eliminar la tarea.'))
  }
}

const colspanProyectoFila = computed(() => 8 + (hayTransversalEnLista.value ? 1 : 0))

const resumenProyectos = computed(() => {
  const lista = proyectosFiltrados.value
  const total = totalProyectos.value
  const activos = lista.filter((p) => String(p.estado || '') === 'Activo').length
  const finalizados = lista.filter((p) => String(p.estado || '') === 'Finalizado').length
  const enPausa = lista.filter((p) => String(p.estado || '') === 'En pausa').length
  const avancePromedio = total
    ? Math.round(lista.reduce((acc, p) => acc + (Number(p.porcentaje_avance) || 0), 0) / total)
    : 0
  return [
    { key: 'total', title: 'Proyectos visibles', value: total, meta: 'Coincidencias totales de la búsqueda', tone: 'neutral' },
    { key: 'activos', title: 'Activos', value: activos, meta: `${enPausa} en pausa en esta página`, tone: 'info' },
    { key: 'finalizados', title: 'Finalizados', value: finalizados, meta: 'Resultado de la página actual', tone: 'success' },
    { key: 'avance', title: 'Avance promedio', value: `${avancePromedio}%`, meta: 'Promedio de la página actual', tone: 'warning' },
  ]
})

const resumenObjetivos = computed(() => {
  const lista = proyectosFiltrados.value
  let total = 0
  let noIniciado = 0
  let enProgreso = 0
  let finalizados = 0
  for (const p of lista) {
    const r = objetivosResumen(p)
    total += r.total
    noIniciado += r.no_iniciado
    enProgreso += r.en_progreso
    finalizados += r.finalizados
  }
  const pct = (n: number) => (total ? Math.round((n / total) * 100) : 0)
  const avance = total ? Math.round(((enProgreso * 50 + finalizados * 100) / total)) : 0
  return {
    total,
    avance,
    cards: [
      { key: 'obj-total', title: 'Objetivos totales', value: total, pct: 100, meta: 'Asociados a los proyectos visibles', tone: 'neutral' },
      { key: 'obj-noiniciado', title: 'No iniciados', value: noIniciado, pct: pct(noIniciado), meta: `${pct(noIniciado)}% del total`, tone: 'muted' },
      { key: 'obj-progreso', title: 'En progreso', value: enProgreso, pct: pct(enProgreso), meta: `${pct(enProgreso)}% del total`, tone: 'warning' },
      { key: 'obj-finalizado', title: 'Finalizados', value: finalizados, pct: pct(finalizados), meta: `${pct(finalizados)}% del total`, tone: 'success' },
    ],
  }
})

const totalPaginas = computed(() => Math.max(1, Math.ceil(totalProyectos.value / tamanioPagina)))
const primerResultado = computed(() => totalProyectos.value ? ((paginaActual.value - 1) * tamanioPagina) + 1 : 0)
const ultimoResultado = computed(() => Math.min(totalProyectos.value, paginaActual.value * tamanioPagina))

async function irAPagina(page: number) {
  const destino = Math.min(Math.max(1, page), totalPaginas.value)
  if (destino === paginaActual.value) return
  await load(destino)
}

function estadoProyectoClase(estado: unknown): string {
  const valor = String(estado || '').toLowerCase()
  if (valor === 'activo') return 'estado-activo'
  if (valor === 'finalizado') return 'estado-finalizado'
  if (valor === 'en pausa') return 'estado-pausa'
  return 'estado-neutro'
}

function objetivosResumen(p: Record<string, unknown>): {
  total: number
  no_iniciado: number
  en_progreso: number
  finalizados: number
} {
  const r = (p.objetivos_resumen as Record<string, number> | undefined) || {}
  return {
    total: Number(r.total) || 0,
    no_iniciado: Number(r.no_iniciado) || 0,
    en_progreso: Number(r.en_progreso) || 0,
    finalizados: Number(r.finalizados) || 0,
  }
}

function dependenciaOrganizacional(p: Record<string, unknown>): { tipo: string; nombre: string }[] {
  const items: { tipo: string; nombre: string }[] = []
  const areaNom = p.area_nombre as string | undefined
  if (areaNom) items.push({ tipo: 'Área', nombre: areaNom })
  if (!areaNom) {
    const areasAsig = p.areas_asignadas as string[] | undefined
    if (areasAsig?.length) items.push({ tipo: 'Área', nombre: areasAsig.join(', ') })
  }
  const secsAsig = p.secretarias_asignadas as string[] | undefined
  if (secsAsig?.length) {
    items.push({ tipo: 'Secretaría', nombre: secsAsig.join(', ') })
  } else {
    let secNombre = p.secretaria_nombre as string | undefined
    if (!secNombre && p.secretaria != null) {
      const secId = typeof p.secretaria === 'object' ? (p.secretaria as { id?: number }).id : p.secretaria
      const s = secretarias.value.find((x: Record<string, unknown>) => (x.id as number) === Number(secId))
      secNombre = s ? String(s.nombre || s.codigo || '') : undefined
    }
    if (secNombre) items.push({ tipo: 'Secretaría', nombre: secNombre })
  }
  return items
}

function presupuestoItemsProyecto(proyecto: Record<string, unknown> | null): Record<string, unknown>[] {
  if (!proyecto) return []
  const items = proyecto.presupuesto_items
  return Array.isArray(items) ? (items as Record<string, unknown>[]) : []
}

async function descargarExcel() {
  const lista = await fetchAllPages('dashboard/proyectos/', buildProjectParams(1))
  const headers = ['Nombre del proyecto', 'Dependencia organizacional', 'Avance %', 'Responsable', 'Estado', 'Fecha inicio', 'Fecha fin estimada', 'Descripción']
  const rows = lista.map((p: Record<string, unknown>) => {
    const deps = dependenciaOrganizacional(p)
    const depStr = deps.length ? deps.map(d => `${d.tipo}: ${d.nombre}`).join(' | ') : ''
    return [
    String(p.nombre || ''),
    depStr,
    String(p.porcentaje_avance ?? '0'),
    String(p.responsable_nombre || p.creado_por || ''),
    String(p.estado || ''),
    p.fecha_inicio ? formatFechaCorta(p.fecha_inicio as string) : '',
    p.fecha_fin_estimada ? formatFechaCorta(p.fecha_fin_estimada as string) : '',
    String((p.descripcion || '').toString()),
  ]})
  await exportToCsv(headers, rows, `proyectos_${new Date().toISOString().slice(0, 10)}.xlsx`)
}

async function cargarUsuarios() {
  try {
    const u = await api.get('usuarios/selector/')
    usuarios.value = Array.isArray(u.data) ? u.data : []
  } catch {
    try {
      const u2 = await api.get('usuarios/')
      usuarios.value = Array.isArray(u2.data) ? u2.data : []
    } catch {
      usuarios.value = []
    }
  }
}

async function loadUsuariosParaResponsable() {
  if (!showForm.value) return
  cargaUsuariosResponsable.value = true
  try {
    const params: Record<string, number> = {}
    if (form.value.tipoDependencia === 'area' && form.value.areas_ids.length === 1) params.area = form.value.areas_ids[0]
    else if (form.value.tipoDependencia === 'secretaria' && form.value.secretarias_ids.length === 1) params.secretaria = form.value.secretarias_ids[0]
    const res = await api.get('usuarios/selector/', { params })
    const lista = Array.isArray(res.data) ? res.data : []
    usuariosParaResponsable.value = lista
    const ids = new Set(lista.map((u: Record<string, unknown>) => u.id))
    if (form.value.usuario_responsable && !ids.has(form.value.usuario_responsable)) {
      form.value.usuario_responsable = null
    }
  } catch {
    usuariosParaResponsable.value = []
    form.value.usuario_responsable = null
  } finally {
    cargaUsuariosResponsable.value = false
  }
}

const openCreate = async () => {
  editingId.value = null
  if (!usuarios.value.length) await cargarUsuarios()
  const secretariaId = route.query.secretaria ? Number(route.query.secretaria) : null
  const areaId = route.query.area ? Number(route.query.area) : null
  const tipoInicial: TipoDependencia = secretariaId ? 'secretaria' : 'area'
  form.value = {
    nombre: '',
    descripcion: '',
    fecha_inicio: '',
    fecha_fin_estimada: '',
    estado: 'Activo',
    presupuesto_total: '',
    fuente_financiamiento: 'Provincial',
    creado_por: user.value?.id ?? 1,
    usuario_responsable: user.value?.id ?? null,
    tipoDependencia: tipoInicial,
    areas_ids: tipoInicial === 'area' && areaId ? [areaId] : [],
    secretarias_ids: tipoInicial === 'secretaria' && secretariaId ? [secretariaId] : [],
    equipo: [],
    presupuesto_items: [] as PresupuestoItemForm[],
    objetivos: [] as ObjetivoProyectoForm[],
  }
  buscarObjetivo.value = ''
  showForm.value = true
  await cargarObjetivosCatalogo()
  loadUsuariosParaResponsable()
}

const openEdit = async (p: Record<string, unknown>) => {
  editingId.value = p.id as number
  const detalleRes = await api.get(`proyectos/${editingId.value}/`).catch(() => ({ data: p }))
  const proyecto = { ...p, ...parseProyectoDetalle(detalleRes) }
  const secId = proyecto.secretaria != null
    ? (typeof proyecto.secretaria === 'object'
      ? (proyecto.secretaria as { id?: number }).id
      : proyecto.secretaria as number)
    : null
  const areaDirect = proyecto.area != null
    ? (typeof proyecto.area === 'object'
      ? (proyecto.area as { id?: number }).id
      : proyecto.area as number)
    : null
  const areasIdsApi = proyecto.areas_asignadas_ids as number[] | undefined
  let areasIdsResolved: number[] = Array.isArray(areasIdsApi) && areasIdsApi.length ? [...areasIdsApi] : []
  if (!areasIdsResolved.length && areaDirect != null) {
    areasIdsResolved = [Number(areaDirect)]
  }
  if (!areasIdsResolved.length) {
    const areasProy = proyecto.areas_asignadas as string[] | undefined
    if (areasProy?.length && areas.value.length) {
      for (const nombre of areasProy) {
        const match = areas.value.find((a: Record<string, unknown>) => String(a.nombre) === nombre)
        if (match?.id) areasIdsResolved.push(match.id as number)
      }
    }
  }
  if (!areasIdsResolved.length) {
    try {
      const paRes = await api.get('proyecto-area/', { params: { proyecto: p.id } })
      const paList = paRes.data || []
      areasIdsResolved = (paList as Record<string, unknown>[]).map((pa) => pa.area as number).filter(Boolean)
    } catch { /* ignorar */ }
  }
  const secsIdsApi = proyecto.secretarias_asignadas_ids as number[] | undefined
  let secretariasIdsResolved: number[] = Array.isArray(secsIdsApi) && secsIdsApi.length ? [...secsIdsApi] : []
  if (!secretariasIdsResolved.length && secId != null) {
    secretariasIdsResolved = [Number(secId)]
  }
  if (!secretariasIdsResolved.length && secId == null) {
    try {
      const psRes = await api.get('proyecto-secretaria/', { params: { proyecto: p.id } })
      const psList = psRes.data || []
      secretariasIdsResolved = (psList as Record<string, unknown>[]).map((row) => row.secretaria as number).filter(Boolean)
    } catch { /* ignorar */ }
  }
  const tipo: TipoDependencia = areasIdsResolved.length > 0 ? 'area' : 'secretaria'
  let equipoIds: number[] = []
  try {
    const eqRes = await api.get('proyecto-equipo/', { params: { proyecto: p.id } })
    equipoIds = (eqRes.data || []).map((pe: Record<string, unknown>) => pe.usuario as number)
  } catch { /* ignorar */ }
  form.value = {
    nombre: (proyecto.nombre as string) || '',
    descripcion: (proyecto.descripcion as string) || '',
    fecha_inicio: (proyecto.fecha_inicio as string) || '',
    fecha_fin_estimada: (proyecto.fecha_fin_estimada as string) || '',
    estado: (proyecto.estado as string) || 'Activo',
    presupuesto_total: normalizarMontoInput(proyecto.presupuesto_total as string | number | null | undefined),
    fuente_financiamiento: (proyecto.fuente_financiamiento as FuenteFinanciamiento) || 'Provincial',
    creado_por: proyecto.creado_por as number,
    usuario_responsable: (
      proyecto.usuario_responsable != null
        ? (typeof proyecto.usuario_responsable === 'object'
          ? (proyecto.usuario_responsable as { id?: number }).id
          : proyecto.usuario_responsable)
        : null
    ) as number | null,
    tipoDependencia: tipo,
    areas_ids: tipo === 'area' ? areasIdsResolved : [],
    secretarias_ids: tipo === 'secretaria' ? (secretariasIdsResolved.length ? secretariasIdsResolved : (secId ? [Number(secId)] : [])) : [],
    equipo: equipoIds,
    presupuesto_items: mapPresupuestoItems(proyecto.presupuesto_items),
    objetivos: (() => {
      const asignados = mapObjetivosAsignados(proyecto.objetivos_asignados)
      if (asignados.length) return asignados
      const legacyId = proyecto.objetivo_estrategico != null
        ? (typeof proyecto.objetivo_estrategico === 'object'
          ? (proyecto.objetivo_estrategico as { id?: number }).id
          : proyecto.objetivo_estrategico)
        : null
      return legacyId ? [{ id: Number(legacyId), estado_avance: 'No iniciado' as EstadoAvanceObjetivo }] : []
    })(),
  }
  buscarObjetivo.value = ''
  showForm.value = true
  await cargarObjetivosCatalogo()
  loadUsuariosParaResponsable()
}

const save = async () => {
  const { tipoDependencia, areas_ids, secretarias_ids, equipo, usuario_responsable, presupuesto_items, objetivos, ...rest } = form.value
  if (!objetivos.length) {
    toast.error('Seleccione al menos un objetivo estratégico.')
    return
  }
  if (tipoDependencia === 'area' && !areas_ids.length) {
    toast.error('Seleccione al menos un área para el proyecto.')
    return
  }
  if (tipoDependencia === 'secretaria' && !secretarias_ids.length) {
    toast.error('Seleccione al menos una secretaría para el proyecto.')
    return
  }
  const presupuestoPayload = buildPresupuestoPayload()
  if (!presupuestoPayload) return
  const payload: Record<string, unknown> = {
    ...rest,
    presupuesto_total: montoToNumber(form.value.presupuesto_total),
    usuario_responsable: usuario_responsable,
    equipo: equipo || [],
    presupuesto_items: presupuestoPayload,
    objetivos: objetivos.map((o) => ({ id: o.id, estado_avance: o.estado_avance })),
  }
  if (tipoDependencia === 'area') {
    payload.areas_ids = areas_ids
  } else {
    payload.secretarias_ids = secretarias_ids
  }
  try {
    if (editingId.value) {
      await api.patch(`proyectos/${editingId.value}/`, payload)
      toast.success('Proyecto actualizado correctamente.')
    } else {
      await api.post('proyectos/', payload)
      toast.success('Proyecto creado correctamente.')
    }
    showForm.value = false
    load()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al guardar el proyecto. Verifique los datos.'))
  }
}

const remove = async (id: number) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`proyectos/${id}/`)
      invalidateApiCache('dashboard')
      invalidateApiCache('proyectos')
      toast.success('Registro eliminado correctamente.')
      load()
    } catch (e: unknown) {
      const err = e as { response?: { data?: { detail?: string }; status?: number } }
      const msg = extraerMensajeError(
        e,
        err.response?.status === 403 ? 'No tiene permiso para eliminar.' : 'Error al eliminar el proyecto.',
      )
      toast.error(msg)
    }
  }
}

const areasActivas = computed(() =>
  areas.value.filter((a: Record<string, unknown>) => a.estado !== false)
)
const secretariasActivas = computed(() =>
  secretarias.value.filter((s: Record<string, unknown>) => s.activa !== false)
)

const avisoResponsableRecomendado = computed(() => {
  const multiArea = form.value.tipoDependencia === 'area' && form.value.areas_ids.length > 1
  const multiSec = form.value.tipoDependencia === 'secretaria' && form.value.secretarias_ids.length > 1
  return !form.value.usuario_responsable || multiArea || multiSec
})

function toggleFormArea(id: number) {
  const idx = form.value.areas_ids.indexOf(id)
  if (idx >= 0) {
    form.value.areas_ids = form.value.areas_ids.filter((x) => x !== id)
  } else {
    form.value.areas_ids = [...form.value.areas_ids, id]
  }
}

function toggleFormSecretaria(id: number) {
  const idx = form.value.secretarias_ids.indexOf(id)
  if (idx >= 0) {
    form.value.secretarias_ids = form.value.secretarias_ids.filter((x) => x !== id)
  } else {
    form.value.secretarias_ids = [...form.value.secretarias_ids, id]
  }
}

function irADetalleProyecto(id: number) {
  router.push(`/proyectos/${id}`)
}

function irAPanelVinculos(id: number) {
  router.push(`/proyectos/${id}/vinculos`)
}

const openAsignar = async (p: Record<string, unknown>) => {
  proyectoAsignar.value = p
  const proyId = p.id as number
  areasSeleccionadasAsignar.value = []
  secretariasSeleccionadasAsignar.value = []
  try {
    const paRes = await api.get('proyecto-area/', { params: { proyecto: proyId } })
    const paList = paRes.data || []
    areasSeleccionadasAsignar.value = paList.map((pa: Record<string, unknown>) => pa.area as number)
    const psRes = await api.get('proyecto-secretaria/', { params: { proyecto: proyId } })
    const psList = psRes.data || []
    secretariasSeleccionadasAsignar.value = (psList as Record<string, unknown>[]).map((row) => row.secretaria as number).filter(Boolean)
    const sec = p.secretaria
    const secId = sec != null && typeof sec === 'object' && !Array.isArray(sec) ? (sec as { id?: number }).id : sec
    if (secId != null && !secretariasSeleccionadasAsignar.value.includes(Number(secId))) {
      secretariasSeleccionadasAsignar.value = [...secretariasSeleccionadasAsignar.value, Number(secId)]
    }
    if (areasSeleccionadasAsignar.value.length) {
      tipoAsignar.value = 'area'
    } else if (secretariasSeleccionadasAsignar.value.length || (p.secretaria != null && p.secretaria !== '')) {
      tipoAsignar.value = 'secretaria'
    } else {
      tipoAsignar.value = 'area'
    }
  } catch {
    areasSeleccionadasAsignar.value = []
    secretariasSeleccionadasAsignar.value = []
    tipoAsignar.value = (p.secretaria != null && p.secretaria !== '') ? 'secretaria' : 'area'
  }
  showAsignarModal.value = true
}

const closeAsignarModal = () => {
  showAsignarModal.value = false
  proyectoAsignar.value = null
  areasSeleccionadasAsignar.value = []
  secretariasSeleccionadasAsignar.value = []
}
const closeForm = () => { showForm.value = false }
useModalClose(showAsignarModal, closeAsignarModal)
useModalClose(showForm, closeForm)

const areaNombre = (id: number) => {
  const a = areas.value.find((x: Record<string, unknown>) => (x.id as number) === id)
  return (a?.nombre as string) || `Área ${id}`
}

const secretariaNombre = (id: number | null) => {
  if (id == null) return null
  const s = secretarias.value.find((x: Record<string, unknown>) => (x.id as number) === id)
  return (s?.nombre as string) || `Secretaría ${id}`
}

const toggleAreaAsignar = (id: number) => {
  const idx = areasSeleccionadasAsignar.value.indexOf(id)
  if (idx >= 0) {
    areasSeleccionadasAsignar.value = areasSeleccionadasAsignar.value.filter((x) => x !== id)
  } else {
    areasSeleccionadasAsignar.value = [...areasSeleccionadasAsignar.value, id]
  }
}

const toggleSecretariaAsignar = (id: number) => {
  const idx = secretariasSeleccionadasAsignar.value.indexOf(id)
  if (idx >= 0) {
    secretariasSeleccionadasAsignar.value = secretariasSeleccionadasAsignar.value.filter((x) => x !== id)
  } else {
    secretariasSeleccionadasAsignar.value = [...secretariasSeleccionadasAsignar.value, id]
  }
}

const guardarAsignar = async () => {
  if (!proyectoAsignar.value || !user.value) return
  const proyId = proyectoAsignar.value.id as number
  guardandoAsignar.value = true
  try {
    if (tipoAsignar.value === 'area') {
      if (!areasSeleccionadasAsignar.value.length) {
        toast.error('Seleccione al menos un área.')
        guardandoAsignar.value = false
        return
      }
      await api.patch(`proyectos/${proyId}/`, {
        area: null,
        secretaria: null,
        areas_ids: areasSeleccionadasAsignar.value,
      })
    } else {
      if (!secretariasSeleccionadasAsignar.value.length) {
        toast.error('Seleccione al menos una secretaría.')
        guardandoAsignar.value = false
        return
      }
      await api.patch(`proyectos/${proyId}/`, {
        area: null,
        secretaria: null,
        secretarias_ids: secretariasSeleccionadasAsignar.value,
      })
    }
    toast.success('Asignación guardada correctamente.')
    closeAsignarModal()
    load()
  } catch {
    toast.error('Error al guardar la asignación.')
  } finally {
    guardandoAsignar.value = false
  }
}

watch(
  () => [form.value.areas_ids, form.value.secretarias_ids, form.value.tipoDependencia],
  () => { if (showForm.value) loadUsuariosParaResponsable() },
  { deep: true }
)

onMounted(async () => {
  await Promise.all([cargarDatosSoporte(), load(1)])
})

watch(() => [route.query.secretaria, route.query.area, route.query.estado, route.query.vencimiento], () => {
  void load(1)
})

watch(buscarProyecto, () => {
  if (busquedaTimer) clearTimeout(busquedaTimer)
  busquedaTimer = setTimeout(() => {
    void load(1)
  }, 300)
})
</script>

<template>
  <div class="page">
    <div class="page-hero">
      <div>
        <h1>Proyectos</h1>
        <p class="page-subtitle">Vista ejecutiva del portafolio con foco en avance, responsables y vencimientos.</p>
      </div>
    </div>
    <p v-if="filtroRutaTexto" class="filter-hint">
      Filtros aplicados: <strong>{{ filtroRutaTexto }}</strong>.
      <router-link :to="{ path: '/proyectos' }">Ver todos</router-link>
    </p>

    <section class="summary-grid">
      <article v-for="card in resumenProyectos" :key="card.key" class="summary-card" :class="`tone-${card.tone}`">
        <span class="summary-title">{{ card.title }}</span>
        <strong class="summary-value">{{ card.value }}</strong>
        <span class="summary-meta">{{ card.meta }}</span>
      </article>
    </section>

    <section v-if="resumenObjetivos.total > 0" class="objetivos-summary">
      <div class="objetivos-summary-head">
        <div class="objetivos-summary-title">
          <span class="objetivos-summary-label">Objetivos asociados</span>
          <span class="objetivos-summary-sub">Estado de los objetivos de los proyectos visibles</span>
        </div>
        <span class="objetivos-summary-avance">Avance global: {{ resumenObjetivos.avance }}%</span>
      </div>
      <div class="objetivos-summary-bar" :title="`No iniciados, en progreso y finalizados`">
        <div
          v-for="card in resumenObjetivos.cards.slice(1)"
          :key="card.key"
          class="objetivos-summary-seg"
          :class="`seg-${card.tone}`"
          :style="{ width: `${card.pct}%` }"
        />
      </div>
      <div class="objetivos-summary-grid">
        <article
          v-for="card in resumenObjetivos.cards"
          :key="card.key"
          class="objetivos-summary-card"
          :class="`obj-tone-${card.tone}`"
        >
          <span class="objetivos-summary-card-title">{{ card.title }}</span>
          <div class="objetivos-summary-card-main">
            <strong class="objetivos-summary-card-value">{{ card.value }}</strong>
            <span v-if="card.key !== 'obj-total'" class="objetivos-summary-card-pct">{{ card.pct }}%</span>
          </div>
          <span class="objetivos-summary-card-meta">{{ card.meta }}</span>
        </article>
      </div>
    </section>

    <div class="toolbar">
      <input
        v-model="buscarProyecto"
        type="search"
        placeholder="Buscar (varias palabras: nombre, descripción, año, dependencia, responsable)..."
        class="search-input"
      />
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!proyectosFiltrados.length">
          <IconDownload class="btn-icon" />
          Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" />
          Nuevo proyecto
        </button>
      </div>
    </div>

    <div class="vencimiento-leyenda">
      <span class="leyenda-item vencida">Vencido</span>
      <span class="leyenda-item proxima">Próximo a vencer (7 días)</span>
      <span class="leyenda-item dentro">Dentro del plazo</span>
    </div>

    <LoaderSpinner v-if="carga" texto="Cargando proyectos..." />

    <div v-else-if="proyectosFiltrados.length" class="table-wrapper proyectos-panel-table">
      <table class="table">
        <thead>
          <tr>
            <th v-if="hayTransversalEnLista" class="col-expand" title="Expandir tareas del proyecto transversal" />
            <th class="col-nombre-proyecto" title="Nombre del proyecto">Proyecto</th>
            <th class="col-dep" title="Dependencia organizacional">Área / Secretaría</th>
            <th class="col-avance">Avance</th>
            <th>Responsable</th>
            <th class="col-estado">Estado</th>
            <th class="col-fecha-inicio" title="Fecha de inicio">Inicio</th>
            <th class="col-fecha-fin" title="Fecha de finalización estimada">Fin</th>
            <th class="actions-header col-acciones">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="p in proyectosFiltrados" :key="(p.id as number)">
          <tr
            :class="claseVencimiento(estadoVencimiento(p.fecha_fin_estimada, p.estado))"
            class="fila-clic-detalle"
            role="button"
            tabindex="0"
            @click="irADetalleProyecto(p.id as number)"
            @keydown.enter.prevent="irADetalleProyecto(p.id as number)"
            @keydown.space.prevent="irADetalleProyecto(p.id as number)"
          >
            <td v-if="hayTransversalEnLista" class="col-expand" @click.stop>
              <button
                v-if="p.es_transversal"
                type="button"
                class="btn-expand-tareas"
                :title="expandedTransversal[p.id as number] ? 'Ocultar tareas' : 'Ver tareas por dependencia'"
                :aria-expanded="Boolean(expandedTransversal[p.id as number])"
                @click="toggleExpandTransversal(p.id as number, $event)"
              >
                {{ expandedTransversal[p.id as number] ? '▼' : '▶' }}
              </button>
            </td>
            <td class="col-nombre-proyecto">
              <span v-if="p.es_transversal" class="badge-transversal" title="Varias áreas o secretarías">Transversal</span>
              {{ p.nombre || '-' }}
            </td>
            <td class="dependencia-cell">
              <template v-if="dependenciaOrganizacional(p).length">
                <span
                  v-for="(d, i) in dependenciaOrganizacional(p)"
                  :key="i"
                  class="dependencia-badge"
                  :class="d.tipo === 'Secretaría' ? 'badge-secretaria' : 'badge-area'"
                >
                  <strong>{{ d.tipo }}:</strong> {{ d.nombre }}
                </span>
              </template>
              <span v-else class="sin-dependencia">—</span>
            </td>
            <td class="avance-cell col-avance">
              <div class="progress-inline">
                <div class="progress-track">
                  <div class="progress-fill" :style="{ width: `${Math.min(100, Number(p.porcentaje_avance) || 0)}%` }" />
                </div>
                <span class="progress-value">{{ Number(p.porcentaje_avance) ?? 0 }}%</span>
              </div>
              <div v-if="objetivosResumen(p).total > 0" class="avance-objetivos-inline">
                <div class="avance-obj-head">
                  <span class="avance-obj-label">Objetivos</span>
                  <div class="progress-track progress-track-sm">
                    <div class="progress-fill progress-fill-obj" :style="{ width: `${Math.min(100, Number(p.avance_objetivos) || 0)}%` }" />
                  </div>
                  <span class="progress-value-sm">{{ Number(p.avance_objetivos) ?? 0 }}%</span>
                </div>
                <div class="obj-chips">
                  <span class="obj-chip obj-chip-noiniciado" :title="`${objetivosResumen(p).no_iniciado} no iniciado(s)`">
                    <span class="obj-dot" /> {{ objetivosResumen(p).no_iniciado }}
                  </span>
                  <span class="obj-chip obj-chip-progreso" :title="`${objetivosResumen(p).en_progreso} en proceso`">
                    <span class="obj-dot" /> {{ objetivosResumen(p).en_progreso }}
                  </span>
                  <span class="obj-chip obj-chip-finalizado" :title="`${objetivosResumen(p).finalizados} finalizado(s)`">
                    <span class="obj-dot" /> {{ objetivosResumen(p).finalizados }}
                  </span>
                  <span class="obj-chip-total" :title="`${objetivosResumen(p).total} objetivos en total`">/ {{ objetivosResumen(p).total }}</span>
                </div>
              </div>
            </td>
            <td>{{ p.responsable_nombre || p.creado_por || '-' }}</td>
            <td class="col-estado">
              <span class="estado-chip" :class="estadoProyectoClase(p.estado)">{{ p.estado || '-' }}</span>
            </td>
            <td class="col-fecha-inicio">{{ formatFechaCorta(p.fecha_inicio as string | undefined) }}</td>
            <td class="vencimiento-cell col-fecha-fin">
              <span v-if="p.fecha_fin_estimada" class="vencimiento-badge" :class="'vencimiento-badge-' + estadoVencimiento(p.fecha_fin_estimada, p.estado)">
                {{ formatFechaCorta(p.fecha_fin_estimada as string) }}
              </span>
              <span v-else class="vencimiento-sin">—</span>
            </td>
            <td class="actions-cell col-acciones" @click.stop>
              <button type="button" class="btn-action btn-action-compact btn-action-ver" title="Ver detalle" @click="irADetalleProyecto(p.id as number)"><IconEye class="btn-icon-sm" /> Ver</button>
              <template v-if="!isVisualizador">
                <button
                  v-if="p.es_transversal"
                  type="button"
                  class="btn-action btn-action-compact"
                  title="Panel de vínculos y tareas por dependencia"
                  @click.stop="irAPanelVinculos(p.id as number)"
                >
                  Vínculos
                </button>
                <button type="button" class="btn-action btn-action-compact btn-action-asignar" title="Asignar" @click="openAsignar(p)"><IconPlus class="btn-icon-sm" /> Asignar</button>
                <button type="button" class="btn-action btn-action-compact btn-action-editar" title="Editar" @click="openEdit(p)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button
                  type="button"
                  class="btn-action-danger btn-action-compact"
                  :disabled="Boolean(p.es_transversal)"
                  :title="p.es_transversal ? 'Elimine o ajuste cada vínculo desde el panel de vínculos o el listado filtrado por área/secretaría.' : 'Eliminar proyecto'"
                  @click="remove(p.id as number)"
                >
                  <IconTrash class="btn-icon-sm" /> Eliminar
                </button>
              </template>
            </td>
          </tr>
          <tr
            v-if="hayTransversalEnLista && p.es_transversal && expandedTransversal[p.id as number]"
            class="fila-tareas-transversal"
          >
            <td :colspan="colspanProyectoFila" class="celda-tareas-anidadas">
              <LoaderSpinner v-if="cargandoTareasExpand[p.id as number]" texto="Cargando tareas..." />
              <div v-else class="nested-tareas-wrap">
                <p class="nested-tareas-titulo">Tareas del proyecto (por orden y dependencia)</p>
                <div class="table-wrap-nested">
                  <table class="table nested-tareas-table">
                    <thead>
                      <tr>
                        <th class="nt-col-orden">Orden</th>
                        <th class="nt-col-titulo">Título</th>
                        <th class="nt-col-estado">Estado</th>
                        <th class="nt-col-avance">Avance</th>
                        <th class="nt-col-inicio">Inicio</th>
                        <th class="nt-col-dep">Área / Secretaría</th>
                        <th class="nt-col-venc">Vencimiento</th>
                        <th v-if="!isVisualizador" class="nt-col-acc">Acciones</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr
                        v-for="{ t, depth } in filasTareasExpandidas(p.id as number)"
                        :key="'nt-' + (t.id as number)"
                        :class="[
                          claseVencimiento(estadoVencimiento(t.fecha_vencimiento as string, t.estado as string)),
                          depth > 0 ? 'nt-row-subtarea' : '',
                        ]"
                      >
                        <td class="nt-col-orden">{{ t.orden ?? '—' }}</td>
                        <td class="nt-col-titulo">
                          <div
                            class="nt-titulo-cell"
                            :class="{ 'nt-titulo-es-sub': depth > 0 }"
                            :style="{ paddingLeft: `${8 + depth * 14}px` }"
                          >
                            <span v-if="depth > 0" class="nt-subtarea-icon" aria-hidden="true">↳</span>
                            <span v-if="depth > 0" class="badge-subtarea-nested">Subtarea</span>
                            <span class="nt-titulo-texto">{{ t.titulo || '—' }}</span>
                          </div>
                        </td>
                        <td class="nt-col-estado">{{ t.estado || '—' }}</td>
                        <td class="nt-col-avance">{{ Number(t.porcentaje_avance) ?? 0 }}%</td>
                        <td class="nt-col-inicio">{{ formatFechaCorta(t.fecha_inicio as string | undefined) }}</td>
                        <td class="nt-col-dep">{{ t.organizacion_nombre || '—' }}</td>
                        <td class="nt-col-venc">{{ formatFechaCorta(t.fecha_vencimiento as string | undefined) }}</td>
                        <td v-if="!isVisualizador" class="nt-col-acc" @click.stop>
                          <button type="button" class="btn-nested" title="Ver" @click="irVerTareaDesdeProyectos(p.id as number, t.id as number)"><IconEye class="btn-icon-sm" /></button>
                          <button type="button" class="btn-nested" title="Editar" @click="irEditarTareaDesdeProyectos(p.id as number, t.id as number)"><IconEdit class="btn-icon-sm" /></button>
                          <button type="button" class="btn-nested btn-nested-danger" title="Eliminar" @click="eliminarTareaDesdeProyectos(p.id as number, t.id as number)"><IconTrash class="btn-icon-sm" /></button>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <p v-if="!cargandoTareasExpand[p.id as number] && !filasTareasExpandidas(p.id as number).length" class="nested-sin-tareas">
                  No hay tareas registradas para este proyecto.
                </p>
              </div>
            </td>
          </tr>
          </template>
        </tbody>
      </table>
    </div>
    <div v-if="proyectosFiltrados.length" class="pagination-bar">
      <span class="pagination-text">
        Mostrando {{ primerResultado }}-{{ ultimoResultado }} de {{ totalProyectos }} proyectos
      </span>
      <div class="pagination-actions">
        <button type="button" class="btn-action" :disabled="paginaActual <= 1" @click="irAPagina(paginaActual - 1)">
          Anterior
        </button>
        <span class="pagination-page">Página {{ paginaActual }} de {{ totalPaginas }}</span>
        <button type="button" class="btn-action" :disabled="paginaActual >= totalPaginas" @click="irAPagina(paginaActual + 1)">
          Siguiente
        </button>
      </div>
    </div>

    <EmptyState
      v-else
      :titulo="buscarProyecto.trim() ? 'Sin resultados' : 'No hay proyectos'"
      :mensaje="buscarProyecto.trim() ? 'No se encontraron proyectos que coincidan con la búsqueda. Intente con otros términos.' : 'Aún no hay proyectos cargados. Use el botón «Nuevo proyecto» para crear el primero.'"
      :icono="buscarProyecto.trim() ? 'busqueda' : 'proyectos'"
    />

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal modal-proyecto">
        <h2>{{ editingId ? 'Editar' : 'Nuevo' }} proyecto</h2>
        <form @submit.prevent="save">
          <label>Nombre</label>
          <input v-model="form.nombre" placeholder="Nombre" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="3" />
          <label>Fecha inicio</label>
          <input v-model="form.fecha_inicio" type="date" required />
          <label>Fecha fin estimada</label>
          <input v-model="form.fecha_fin_estimada" type="date" required />
          <label>Estado</label>
          <select v-model="form.estado">
            <option value="Activo">Activo</option>
            <option value="En pausa">En pausa</option>
            <option value="Finalizado">Finalizado</option>
          </select>

          <section class="form-section objetivos-section">
            <div class="form-section-header">
              <div>
                <h3>Objetivos</h3>
                <p class="hint">Seleccione uno o más objetivos de Planificación. Cada uno puede tener un estado de avance independiente.</p>
              </div>
              <span class="objetivos-resumen-chip">
                {{ form.objetivos.length }} seleccionado(s) · Avance: {{ avanceObjetivosPreview }}%
              </span>
            </div>
            <input
              v-model="buscarObjetivo"
              type="search"
              class="search-input objetivos-search"
              placeholder="Buscar objetivo por descripción o programa..."
            />
            <LoaderSpinner v-if="cargaObjetivosCatalogo" texto="Cargando objetivos de Planificación..." />
            <p v-else-if="!objetivosCatalogo.length" class="hint">No hay objetivos cargados en Planificación.</p>
            <div v-else class="objetivos-catalogo">
              <label
                v-for="o in objetivosCatalogoFiltrados"
                :key="(o.id as number)"
                class="objetivo-check"
                :class="{ checked: isObjetivoSeleccionado(o.id as number) }"
              >
                <input
                  type="checkbox"
                  :checked="isObjetivoSeleccionado(o.id as number)"
                  @change="toggleObjetivo(o.id as number)"
                />
                <span class="objetivo-check-body">
                  <span class="objetivo-programa">{{ o.programa_nombre || 'Programa' }}</span>
                  <span class="objetivo-desc">{{ o.descripcion }}</span>
                </span>
              </label>
            </div>
            <div v-if="form.objetivos.length" class="objetivos-seleccionados">
              <h4>Objetivos asociados al proyecto</h4>
              <article
                v-for="sel in form.objetivos"
                :key="sel.id"
                class="objetivo-seleccionado-card"
              >
                <div class="objetivo-seleccionado-info">
                  <span v-if="programaObjetivo(sel.id)" class="objetivo-programa">{{ programaObjetivo(sel.id) }}</span>
                  <p class="objetivo-desc">{{ descripcionObjetivo(sel.id) }}</p>
                </div>
                <div class="objetivo-estado-wrap">
                  <label>Estado de avance</label>
                  <select
                    :value="sel.estado_avance"
                    class="objetivo-estado-select"
                    :class="claseEstadoAvanceObjetivo(sel.estado_avance)"
                    @change="setEstadoObjetivo(sel.id, ($event.target as HTMLSelectElement).value as EstadoAvanceObjetivo)"
                  >
                    <option v-for="est in ESTADOS_AVANCE_OBJETIVO" :key="est" :value="est">{{ est }}</option>
                  </select>
                </div>
                <button type="button" class="btn-link-danger" @click="toggleObjetivo(sel.id)">Quitar</button>
              </article>
            </div>
            <p v-else class="hint objetivos-requerido">Debe seleccionar al menos un objetivo.</p>
          </section>

          <section class="form-section">
            <div class="form-section-header">
              <div>
                <h3>Matriz presupuestaria</h3>
                <p class="hint">El presupuesto total y los ítems de gasto son opcionales. Puede guardar sin cargar gastos o usar «Agregar gasto» cuando los defina.</p>
              </div>
              <button type="button" class="btn-inline-add" @click="agregarItemPresupuesto">
                Agregar gasto
              </button>
            </div>
            <div class="budget-summary-grid">
              <div>
                <label>Presupuesto total del proyecto</label>
                <input
                  :value="form.presupuesto_total"
                  type="text"
                  inputmode="numeric"
                  placeholder="Ej: 79.333.098"
                  @input="onPresupuestoTotalInput"
                />
              </div>
              <div>
                <label>Fuente de financiamiento</label>
                <select v-model="form.fuente_financiamiento">
                  <option v-for="fuente in FUENTES_FINANCIAMIENTO" :key="fuente" :value="fuente">
                    {{ fuente }}
                  </option>
                </select>
              </div>
            </div>
            <div class="budget-total">
              <span>Total cargado en gastos</span>
              <strong>{{ formatCurrency(presupuestoCargado) }}</strong>
            </div>
            <div class="budget-total budget-total-secondary">
              <span>Disponible</span>
              <strong>{{ formatCurrency(presupuestoDisponible) }}</strong>
            </div>
            <div class="budget-list">
              <article
                v-for="(item, index) in form.presupuesto_items"
                :key="item.id ?? `presupuesto-${index}`"
                class="budget-item-card"
              >
                <div class="budget-item-head">
                  <strong>Item {{ index + 1 }}</strong>
                  <button type="button" class="btn-link-danger" @click="eliminarItemPresupuesto(index)">
                    Eliminar
                  </button>
                </div>
                <div class="budget-grid">
                  <div>
                    <label>Categoría de gasto</label>
                    <select v-model="item.categoria_gasto" @change="onCategoriaPresupuestoChange(item, index)">
                      <option v-for="categoria in CATEGORIAS_GASTO" :key="categoria" :value="categoria">
                        {{ categoria }}
                      </option>
                    </select>
                  </div>
                  <div>
                    <label>Monto ($)</label>
                    <input
                      :value="item.monto"
                      type="text"
                      inputmode="numeric"
                      placeholder="Ej: 1.200.000"
                      @input="onMontoItemInput($event, item, index)"
                    />
                  </div>
                  <div class="budget-grid-span">
                    <label>Detalle / Observación</label>
                    <input
                      v-model="item.detalle"
                      type="text"
                      :placeholder="item.categoria_gasto === 'Gastos operativos y logisticos' ? 'Ej: Traslado Ush-Tolh-RG' : 'Detalle u observación'"
                    />
                  </div>
                </div>
                <p
                  v-if="!montoToNumber(item.monto) && item.detalle"
                  class="budget-note"
                >
                  Este gasto se registrará como descriptivo, sin impacto monetario directo.
                </p>
              </article>
            </div>
          </section>

          <label>Dependencia organizacional</label>
          <p class="hint">Puede marcar una o varias áreas o secretarías (proyectos transversales). No mezcle áreas y secretarías en el mismo proyecto.</p>
          <div class="tipo-dependencia-selector">
            <label class="tipo-opt">
              <input type="radio" value="area" v-model="form.tipoDependencia" @change="form.secretarias_ids = []" />
              Área(s)
            </label>
            <label class="tipo-opt">
              <input type="radio" value="secretaria" v-model="form.tipoDependencia" @change="form.areas_ids = []" />
              Secretaría(s)
            </label>
          </div>
          <template v-if="form.tipoDependencia === 'area'">
            <label>Seleccione una o más áreas</label>
            <div class="areas-grid-asignar areas-grid-form">
              <label
                v-for="a in areasActivas"
                :key="(a.id as number)"
                class="area-check-asignar"
                :class="{ checked: form.areas_ids.includes(a.id as number) }"
              >
                <input
                  type="checkbox"
                  :checked="form.areas_ids.includes(a.id as number)"
                  @change="toggleFormArea(a.id as number)"
                />
                <span>{{ a.nombre }}</span>
              </label>
            </div>
          </template>
          <template v-else>
            <label>Seleccione una o más secretarías</label>
            <div class="areas-grid-asignar areas-grid-form">
              <label
                v-for="s in secretariasActivas"
                :key="(s.id as number)"
                class="area-check-asignar"
                :class="{ checked: form.secretarias_ids.includes(s.id as number) }"
              >
                <input
                  type="checkbox"
                  :checked="form.secretarias_ids.includes(s.id as number)"
                  @change="toggleFormSecretaria(s.id as number)"
                />
                <span>{{ s.codigo }} — {{ s.nombre }}</span>
              </label>
            </div>
          </template>
          <label>Responsable principal (opcional)</label>
          <p v-if="avisoResponsableRecomendado" class="hint-recomendacion">
            <strong>Recomendación:</strong> conviene designar un responsable principal del proyecto. Si el alcance abarca varias áreas o secretarías, asigne responsables en cada dependencia para organizar tareas y seguimiento (puede hacerlo luego desde las tareas o el equipo).
          </p>
          <template v-if="cargaUsuariosResponsable">
            <p class="mensaje-carga">Cargando usuarios...</p>
          </template>
          <template v-else-if="(form.tipoDependencia === 'area' && form.areas_ids.length === 1) || (form.tipoDependencia === 'secretaria' && form.secretarias_ids.length === 1)">
            <template v-if="!usuariosParaResponsable.length">
              <p class="mensaje-sin-usuarios">No hay usuarios en el selector para esta dependencia (solo administradores pueden listar el selector filtrado). Puede dejar el responsable vacío o elegir entre los usuarios cargados abajo si corresponde.</p>
            </template>
            <select v-else v-model.number="form.usuario_responsable">
              <option :value="null">— Sin responsable asignado —</option>
              <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">
                {{ u.nombre_completo || u.nombre }}
              </option>
            </select>
          </template>
          <template v-else-if="(form.tipoDependencia === 'area' && form.areas_ids.length > 1) || (form.tipoDependencia === 'secretaria' && form.secretarias_ids.length > 1)">
            <select v-model.number="form.usuario_responsable">
              <option :value="null">— Sin responsable asignado —</option>
              <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">
                {{ u.nombre_completo || u.nombre }}
              </option>
            </select>
            <p class="hint">Con varias dependencias, el listado muestra todos los usuarios disponibles; elija quien coordina el proyecto a nivel global.</p>
          </template>
          <select v-else v-model.number="form.usuario_responsable">
            <option :value="null">— Sin responsable asignado —</option>
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">
              {{ u.nombre_completo || u.nombre }}
            </option>
          </select>
          <label>Equipo (opcional)</label>
          <select v-model="form.equipo" multiple class="select-multiple">
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">
              {{ u.nombre_completo || u.nombre }}
            </option>
          </select>
          <p class="hint">Seleccione múltiples miembros con Ctrl/Cmd.</p>
          <label>Creado por</label>
          <select v-model.number="form.creado_por" required>
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">
              {{ u.nombre_completo || u.nombre }}
            </option>
          </select>
          <p v-if="!usuarios.length" class="hint">No hay usuarios disponibles. Verifique la conexión.</p>
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="closeForm"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal Asignar proyecto -->
    <div v-if="showAsignarModal" class="modal-overlay" @click.self="closeAsignarModal">
      <div class="modal modal-asignar">
        <h2>Asignar proyecto</h2>
        <p v-if="proyectoAsignar" class="modal-subtitle">{{ proyectoAsignar.nombre }}</p>
        <p class="modal-hint">Asigne el proyecto a un Área o a una Secretaría.</p>

        <div class="asignar-form">
          <label>Tipo de destino</label>
          <div class="tipo-dependencia-selector">
            <label class="tipo-opt" :class="{ active: tipoAsignar === 'area' }">
              <input type="radio" value="area" v-model="tipoAsignar" />
              Área
            </label>
            <label class="tipo-opt" :class="{ active: tipoAsignar === 'secretaria' }">
              <input type="radio" value="secretaria" v-model="tipoAsignar" />
              Secretaría
            </label>
          </div>

          <template v-if="tipoAsignar === 'area'">
            <label>Seleccione las áreas</label>
            <div class="areas-grid-asignar">
              <label
                v-for="a in areasActivas"
                :key="(a.id as number)"
                class="area-check-asignar"
                :class="{ checked: areasSeleccionadasAsignar.includes(a.id as number) }"
              >
                <input
                  type="checkbox"
                  :checked="areasSeleccionadasAsignar.includes(a.id as number)"
                  @change="toggleAreaAsignar(a.id as number)"
                />
                <span>{{ a.nombre }}</span>
              </label>
            </div>
          </template>
          <template v-else>
            <label>Seleccione las secretarías</label>
            <div class="areas-grid-asignar">
              <label
                v-for="s in secretariasActivas"
                :key="(s.id as number)"
                class="area-check-asignar"
                :class="{ checked: secretariasSeleccionadasAsignar.includes(s.id as number) }"
              >
                <input
                  type="checkbox"
                  :checked="secretariasSeleccionadasAsignar.includes(s.id as number)"
                  @change="toggleSecretariaAsignar(s.id as number)"
                />
                <span>{{ s.codigo }} — {{ s.nombre }}</span>
              </label>
            </div>
          </template>

          <div class="modal-actions">
            <button type="button" class="btn-primary" @click="guardarAsignar" :disabled="guardandoAsignar">
              {{ guardandoAsignar ? 'Guardando...' : 'Confirmar asignación' }}
            </button>
            <button type="button" class="btn-cancel" @click="closeAsignarModal"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page { display: flex; flex-direction: column; gap: 1rem; }
.page-hero {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.25rem 1.35rem;
  border-radius: 18px;
  background: linear-gradient(135deg, #ffffff 0%, #f8fbff 100%);
  border: 1px solid #e2e8f0;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
}
.page h1 { margin: 0 0 0.35rem; }
.page-subtitle { margin: 0; color: #64748b; }
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
.summary-value { font-size: 1.9rem; color: #0f172a; line-height: 1; }
.summary-meta { color: #64748b; font-size: 0.85rem; }
.tone-neutral { border-top: 4px solid #2563eb; }
.tone-info { border-top: 4px solid #0ea5e9; }
.tone-success { border-top: 4px solid #16a34a; }
.tone-warning { border-top: 4px solid #f59e0b; }
.objetivos-summary {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1.1rem 1.25rem 1.25rem;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
  display: flex;
  flex-direction: column;
  gap: 0.9rem;
}
.objetivos-summary-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}
.objetivos-summary-title { display: flex; flex-direction: column; gap: 0.15rem; }
.objetivos-summary-label { font-size: 1rem; font-weight: 700; color: #0f172a; }
.objetivos-summary-sub { font-size: 0.85rem; color: #64748b; }
.objetivos-summary-avance {
  display: inline-flex;
  align-items: center;
  padding: 0.4rem 0.85rem;
  border-radius: 999px;
  background: #ede9fe;
  color: #6d28d9;
  font-weight: 700;
  font-size: 0.88rem;
  white-space: nowrap;
}
.objetivos-summary-bar {
  display: flex;
  width: 100%;
  height: 12px;
  border-radius: 999px;
  overflow: hidden;
  background: #f1f5f9;
}
.objetivos-summary-seg { height: 100%; transition: width 0.4s ease; }
.objetivos-summary-seg.seg-muted { background: #94a3b8; }
.objetivos-summary-seg.seg-warning { background: #f59e0b; }
.objetivos-summary-seg.seg-success { background: #16a34a; }
.objetivos-summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 1rem;
}
.objetivos-summary-card {
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 0.85rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
}
.objetivos-summary-card-title { font-size: 0.85rem; color: #475569; font-weight: 600; }
.objetivos-summary-card-main { display: flex; align-items: baseline; gap: 0.5rem; }
.objetivos-summary-card-value { font-size: 1.7rem; line-height: 1; color: #0f172a; }
.objetivos-summary-card-pct { font-size: 0.95rem; font-weight: 700; color: #64748b; }
.objetivos-summary-card-meta { font-size: 0.8rem; color: #64748b; }
.objetivos-summary-card.obj-tone-neutral { border-top: 4px solid #6366f1; }
.objetivos-summary-card.obj-tone-muted { border-top: 4px solid #94a3b8; }
.objetivos-summary-card.obj-tone-warning { border-top: 4px solid #f59e0b; }
.objetivos-summary-card.obj-tone-success { border-top: 4px solid #16a34a; }
.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
  padding: 1rem 1.1rem;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.05);
}
.search-input {
  flex: 1;
  min-width: 200px;
  padding: 0.7rem 0.9rem;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  font-size: 0.9rem;
}
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.btn-primary {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
}
.btn-secondary {
  background: #16a34a;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-secondary:disabled { background: #94a3b8; cursor: not-allowed; }
.table-wrapper {
  overflow-x: auto;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
}
.loading, .empty-msg { color: #64748b; margin-top: 0.5rem; }
.table {
  width: 100%;
  background: white;
  border-radius: 18px;
  overflow: hidden;
}
.table th, .table td {
  padding: 0.9rem 1rem;
  text-align: left;
  border-bottom: 1px solid #eef2f7;
  vertical-align: middle;
}
.table th {
  background: #f8fafc;
  font-weight: 700;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: #64748b;
}
.proyectos-panel-table.table-wrapper tbody tr.fila-clic-detalle {
  cursor: pointer;
}
.page .btn-action,
.page .btn-action-danger { margin-right: 0.5rem; }
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}
.modal {
  background: white;
  padding: 1.5rem;
  border-radius: 10px;
  max-width: 400px;
  width: 90%;
}
.modal-proyecto {
  max-width: 980px;
  max-height: min(90vh, 960px);
  overflow-y: auto;
}
.modal h2 { margin-bottom: 1rem; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.form-section {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  padding: 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: #f8fbff;
}
.form-section-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}
.form-section-header h3 {
  margin: 0;
  font-size: 1rem;
  color: #0f172a;
}
.btn-inline-add,
.btn-link-danger {
  border: 0;
  background: transparent;
  cursor: pointer;
  font-weight: 600;
}
.btn-inline-add {
  color: #2563eb;
}
.btn-link-danger {
  color: #b91c1c;
}
.budget-total {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  padding: 0.85rem 1rem;
  border-radius: 10px;
  background: #eef6ff;
  color: #0f172a;
}
.budget-total-secondary {
  background: #f8fafc;
}
.budget-summary-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.85rem;
}
.budget-list {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}
.budget-item-card {
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
  padding: 1rem;
  border: 1px solid #dbe5f0;
  border-radius: 12px;
  background: #fff;
}
.budget-item-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}
.budget-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.85rem;
}
.budget-grid-span {
  grid-column: 1 / -1;
}
.budget-flag {
  display: flex;
  align-items: center;
}
.budget-note {
  margin: 0;
  font-size: 0.85rem;
  color: #64748b;
}
.objetivos-section .objetivos-resumen-chip {
  display: inline-flex;
  align-items: center;
  padding: 0.35rem 0.65rem;
  border-radius: 999px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.8rem;
  font-weight: 600;
  white-space: nowrap;
}
.objetivos-search { margin-bottom: 0.75rem; }
.objetivos-catalogo {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 220px;
  overflow-y: auto;
  margin-bottom: 1rem;
  padding-right: 0.25rem;
}
.objetivo-check {
  display: flex;
  gap: 0.65rem;
  align-items: flex-start;
  padding: 0.65rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  background: #fafbfc;
  transition: border-color 0.2s, background 0.2s;
}
.objetivo-check:hover { border-color: #93c5fd; background: #f8fafc; }
.objetivo-check.checked { border-color: #3b82f6; background: #eff6ff; }
.objetivo-check input { margin-top: 0.2rem; accent-color: #3b82f6; }
.objetivo-check-body { display: flex; flex-direction: column; gap: 0.2rem; min-width: 0; }
.objetivo-programa { font-size: 0.75rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.02em; }
.objetivo-desc { font-size: 0.9rem; color: #1e293b; line-height: 1.35; }
.objetivos-seleccionados h4 { margin: 0 0 0.65rem; font-size: 0.95rem; color: #334155; }
.objetivo-seleccionado-card {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 0.75rem;
  align-items: center;
  padding: 0.75rem;
  border: 1px solid #dbeafe;
  border-radius: 8px;
  background: #f8fbff;
  margin-bottom: 0.5rem;
}
.objetivo-seleccionado-info { min-width: 0; }
.objetivo-estado-wrap { display: flex; flex-direction: column; gap: 0.25rem; min-width: 160px; }
.objetivo-estado-wrap label { font-size: 0.75rem; color: #64748b; font-weight: 600; }
.objetivo-estado-select {
  padding: 0.4rem 0.5rem;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  font-size: 0.85rem;
}
.obj-estado-no-iniciado { background: #f8fafc; color: #64748b; }
.obj-estado-progreso { background: #fef9c3; color: #a16207; border-color: #fde047; }
.obj-estado-finalizado { background: #dcfce7; color: #15803d; border-color: #86efac; }
.objetivos-requerido { color: #b45309; }
.avance-objetivos-inline {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  margin-top: 0.45rem;
  padding-top: 0.4rem;
  border-top: 1px dashed #e2e8f0;
}
.avance-obj-head { display: flex; align-items: center; gap: 0.35rem; }
.avance-obj-label { font-size: 0.7rem; color: #64748b; font-weight: 700; text-transform: uppercase; letter-spacing: 0.02em; }
.progress-track-sm { height: 6px; flex: 1; min-width: 40px; }
.progress-fill-obj { background: #8b5cf6; }
.progress-value-sm { font-size: 0.75rem; color: #6d28d9; font-weight: 600; min-width: 2.2rem; }
.obj-chips { display: flex; align-items: center; gap: 0.3rem; flex-wrap: wrap; }
.obj-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 0.1rem 0.4rem;
  border-radius: 999px;
  line-height: 1.2;
}
.obj-chip .obj-dot { width: 7px; height: 7px; border-radius: 50%; display: inline-block; }
.obj-chip-noiniciado { background: #f1f5f9; color: #475569; }
.obj-chip-noiniciado .obj-dot { background: #94a3b8; }
.obj-chip-progreso { background: #fef9c3; color: #a16207; }
.obj-chip-progreso .obj-dot { background: #f59e0b; }
.obj-chip-finalizado { background: #dcfce7; color: #15803d; }
.obj-chip-finalizado .obj-dot { background: #16a34a; }
.obj-chip-total { font-size: 0.72rem; color: #94a3b8; font-weight: 600; }
.tipo-dependencia-selector {
  display: flex;
  gap: 1rem;
  margin-bottom: 0.5rem;
}
.tipo-opt {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-weight: 500;
}
.tipo-opt input { accent-color: #3b82f6; }
.mensaje-carga { font-size: 0.9rem; color: #64748b; margin: 0.5rem 0; }
.hint-recomendacion {
  margin: 0.35rem 0 0.75rem;
  padding: 0.65rem 0.8rem;
  font-size: 0.88rem;
  color: #92400e;
  background: #fffbeb;
  border: 1px solid #fcd34d;
  border-radius: 10px;
  line-height: 1.45;
}
.areas-grid-form {
  max-height: 220px;
  overflow-y: auto;
}
.mensaje-sin-usuarios { color: #b91c1c; font-weight: 600; margin: 0.5rem 0 0.25rem; }
.mensaje-sin-usuarios-hint { font-size: 0.85rem; color: #64748b; margin: 0 0 0.5rem; }
.hint { font-size: 0.85rem; color: #64748b; margin: 0; }
.select-multiple { min-height: 80px; }
.filter-hint { font-size: 0.9rem; color: #64748b; margin-bottom: 0.5rem; }
.pagination-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  padding: 0.9rem 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  background: #fff;
}
.pagination-text {
  color: #64748b;
  font-size: 0.92rem;
}
.pagination-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.pagination-page {
  min-width: 145px;
  text-align: center;
  color: #0f172a;
  font-weight: 600;
}
.table-wrapper th.col-nombre-proyecto {
  text-align: center !important;
}
.table-wrapper td.col-nombre-proyecto {
  text-align: left;
}
.table-wrapper .col-dep {
  width: 14%;
  max-width: 11rem;
}
.table-wrapper th.col-dep {
  text-align: center !important;
}
.dependencia-cell {
  min-width: 0;
  max-width: 11rem;
}
.table-wrapper th.col-avance,
.table-wrapper td.avance-cell.col-avance {
  text-align: center !important;
}
.avance-cell {
  min-width: 6.5rem;
  max-width: 8.5rem;
}
.table-wrapper .col-avance {
  width: 9%;
}
.table-wrapper .progress-inline {
  justify-content: center;
  margin: 0 auto;
  max-width: 7.5rem;
}
/* Evita solapamiento Fin / Acciones; Acciones centradas (coherente con el resto del sistema) */
.table-wrapper.proyectos-panel-table .col-acciones {
  min-width: 17.5rem;
  width: auto;
  max-width: none;
  white-space: nowrap;
}
.table-wrapper.proyectos-panel-table th.col-fecha-inicio,
.table-wrapper.proyectos-panel-table td.col-fecha-inicio {
  min-width: 5.25rem;
  max-width: 6.75rem;
  text-align: center !important;
}
.table-wrapper.proyectos-panel-table th.col-fecha-fin,
.table-wrapper.proyectos-panel-table td.vencimiento-cell.col-fecha-fin {
  min-width: 6.5rem;
  max-width: 8rem;
  text-align: center !important;
}
.table-wrapper.proyectos-panel-table th.col-estado,
.table-wrapper.proyectos-panel-table td.col-estado {
  text-align: center !important;
  vertical-align: middle;
}
.proyectos-panel-table.table-wrapper .table td.actions-cell {
  display: table-cell !important;
  vertical-align: middle !important;
  text-align: center !important;
  white-space: nowrap;
}
.progress-inline {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}
.progress-track {
  flex: 1;
  min-width: 0;
  height: 8px;
  border-radius: 999px;
  background: #e2e8f0;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #0ea5e9);
  border-radius: 999px;
}
.progress-value {
  min-width: 2.35rem;
  font-weight: 600;
  color: #0f172a;
  font-size: 0.75rem;
}
.col-expand {
  width: 2.25rem;
  text-align: center;
  vertical-align: middle;
}
.btn-expand-tareas {
  border: none;
  background: #f1f5f9;
  border-radius: 6px;
  width: 1.75rem;
  height: 1.75rem;
  cursor: pointer;
  font-size: 0.75rem;
  line-height: 1;
  color: #334155;
}
.btn-expand-tareas:hover {
  background: #e2e8f0;
}
.fila-tareas-transversal {
  background: #fafafa;
}
.fila-tareas-transversal .celda-tareas-anidadas {
  padding: 0.75rem 1rem 1rem;
  vertical-align: top;
}
.nested-tareas-titulo {
  margin: 0 0 0.5rem;
  font-size: 0.88rem;
  font-weight: 600;
  color: #334155;
}
.table-wrap-nested {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
}
.nested-tareas-table {
  font-size: 0.82rem;
}
.nested-tareas-table th,
.nested-tareas-table td {
  padding: 0.35rem 0.5rem;
  border-bottom: 1px solid #f1f5f9;
}
.nested-tareas-table tr.nt-row-subtarea td {
  background: rgba(248, 250, 252, 0.92);
}
.nested-tareas-table tr.nt-row-subtarea:hover td {
  background: #f1f5f9;
}
.nt-titulo-cell {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.35rem;
  line-height: 1.35;
}
.nt-titulo-es-sub .nt-titulo-texto {
  font-weight: 500;
  color: #334155;
}
.nt-subtarea-icon {
  color: #64748b;
  font-size: 1rem;
  line-height: 1;
  flex-shrink: 0;
}
.badge-subtarea-nested {
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
.nt-titulo-texto {
  min-width: 0;
  flex: 1 1 120px;
}
.nested-sin-tareas {
  margin: 0.5rem 0 0;
  font-size: 0.85rem;
  color: #64748b;
}
.btn-nested {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.2rem;
  margin-right: 0.25rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background: #fff;
  cursor: pointer;
}
.btn-nested-danger {
  border-color: #fecaca;
  color: #b91c1c;
}
.badge-transversal {
  display: inline-block;
  margin-right: 0.35rem;
  padding: 0.12rem 0.45rem;
  font-size: 0.68rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  border-radius: 4px;
  background: #e0e7ff;
  color: #3730a3;
  vertical-align: middle;
}
.dependencia-badge {
  display: inline-block;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
  font-size: 0.72rem;
  line-height: 1.25;
  margin-right: 0.25rem;
  margin-bottom: 0.15rem;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  vertical-align: top;
}
/* Tamaño de botones Acciones: ver assets/styles.css (.table .actions-cell) */
.dependencia-badge.badge-area {
  background: #e0f2fe;
  color: #0369a1;
}
.dependencia-badge.badge-secretaria {
  background: #fce7f3;
  color: #9d174d;
}
.estado-chip {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 0.28rem 0.65rem;
  font-size: 0.82rem;
  font-weight: 700;
}
.estado-activo { background: #dbeafe; color: #1d4ed8; }
.estado-finalizado { background: #dcfce7; color: #15803d; }
.estado-pausa { background: #fef3c7; color: #a16207; }
.estado-neutro { background: #e2e8f0; color: #475569; }
.sin-dependencia { color: #94a3b8; }
a { color: #3b82f6; text-decoration: none; }
a:hover { text-decoration: underline; }

/* Modal Asignar */
.modal-asignar { max-width: 480px; }
.modal-subtitle {
  font-size: 0.95rem;
  color: #64748b;
  margin: -0.25rem 0 0.5rem;
}
.modal-hint {
  font-size: 0.9rem;
  color: #64748b;
  margin: 0 0 1rem;
  line-height: 1.4;
}
.asignar-form {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.tipo-opt.active {
  font-weight: 600;
  color: #3b82f6;
}
.areas-grid-asignar {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 0.5rem;
  max-height: 200px;
  overflow-y: auto;
}
.area-check-asignar {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  background: #fafbfc;
  transition: all 0.2s;
}
.area-check-asignar:hover {
  border-color: #93c5fd;
  background: #f8fafc;
}
.area-check-asignar.checked {
  border-color: #3b82f6;
  background: #eff6ff;
}
.area-check-asignar input {
  margin: 0;
  accent-color: #3b82f6;
}

/* Modal Ver detalle */
.modal-ver { max-width: 520px; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
.detalle-desc { white-space: pre-wrap; line-height: 1.5; }
.detalle-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
.detalle-presupuesto {
  display: flex;
  flex-direction: column;
  gap: 0.9rem;
}
.detalle-presupuesto-resumen {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.75rem;
  padding: 0.9rem;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: #f8fbff;
}
.detalle-presupuesto-gastos {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.detalle-presupuesto-item {
  padding: 0.85rem 0.95rem;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background: #fff;
}
.detalle-presupuesto-item-head {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: center;
  color: #0f172a;
}
.detalle-presupuesto-texto {
  margin: 0.5rem 0 0;
  color: #475569;
  line-height: 1.45;
}
.detalle-presupuesto-vacio {
  margin: 0;
  color: #64748b;
}

@media (max-width: 900px) {
  .budget-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .detalle-presupuesto-resumen {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .modal-proyecto {
    width: min(96vw, 96vw);
    padding: 1rem;
  }
  .form-section-header,
  .budget-item-head,
  .budget-total {
    flex-direction: column;
    align-items: stretch;
  }
  .budget-summary-grid,
  .budget-grid,
  .detalle-grid {
    grid-template-columns: 1fr;
  }
}

/* Indicadores de vencimiento por color */
.vencimiento-vencida { background-color: #fef2f2 !important; border-left: 4px solid #dc2626; }
.vencimiento-proxima { background-color: #fffbeb !important; border-left: 4px solid #eab308; }
.vencimiento-dentro-plazo { background-color: #f0fdf4 !important; border-left: 4px solid #22c55e; }
.vencimiento-cell { white-space: nowrap; }
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
@media (max-width: 1100px) {
  .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .objetivos-summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 700px) {
  .summary-grid { grid-template-columns: 1fr; }
  .objetivos-summary-grid { grid-template-columns: 1fr; }
  .page-hero { padding: 1rem; }
}
</style>
