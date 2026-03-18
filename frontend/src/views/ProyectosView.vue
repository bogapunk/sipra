<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
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
import EmptyState from '@/components/EmptyState.vue'

const route = useRoute()
const { isVisualizador, user } = useAuth()
const toast = useToast()
const proyectos = ref<Record<string, unknown>[]>([])
const carga = ref(false)
const showForm = ref(false)
const editingId = ref<number | null>(null)
const showAsignarModal = ref(false)
const proyectoAsignar = ref<Record<string, unknown> | null>(null)
const showVerModal = ref(false)
const proyectoVer = ref<Record<string, unknown> | null>(null)
const tipoAsignar = ref<'area' | 'secretaria'>('area')
const areasSeleccionadasAsignar = ref<number[]>([])
const secretariaSeleccionadaAsignar = ref<number | null>(null)
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
  area_id: null as number | null,
  secretaria: null as number | null,
  equipo: [] as number[],
  presupuesto_items: [crearItemPresupuesto()] as PresupuestoItemForm[],
})
const usuarios = ref<Record<string, unknown>[]>([])
const usuariosParaResponsable = ref<Record<string, unknown>[]>([])
const cargaUsuariosResponsable = ref(false)
const secretarias = ref<Record<string, unknown>[]>([])
const areas = ref<Record<string, unknown>[]>([])

function parseProyectos(res: unknown): Record<string, unknown>[] {
  if (!res || typeof res !== 'object') return []
  const raw = (res as { data?: unknown }).data
  if (Array.isArray(raw)) return raw as Record<string, unknown>[]
  if (raw && typeof raw === 'object' && 'results' in (raw as object)) return ((raw as { results: unknown[] }).results || []) as Record<string, unknown>[]
  return []
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
  if (form.value.presupuesto_items.length === 1) {
    form.value.presupuesto_items = [crearItemPresupuesto()]
    return
  }
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
  if (!Array.isArray(raw) || !raw.length) return [crearItemPresupuesto()]
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
  if (!form.value.presupuesto_items.length) {
    toast.error('Debe cargar al menos un item presupuestario.')
    return null
  }

  const payload = form.value.presupuesto_items.map((item, index) => {
    aplicarReglasPresupuesto(item, index)

    const detalle = item.detalle.trim()
    const monto = Math.max(0, montoToNumber(item.monto))

    return {
      id: item.id ?? undefined,
      categoria_gasto: item.categoria_gasto,
      monto,
      detalle,
      orden: index,
    }
  })

  const primerInvalido = payload.find((item) => {
    const monto = Number(item.monto || 0)
    if (monto <= 0 && !String(item.detalle || '').trim()) return true
    return false
  })

  if (primerInvalido) {
    toast.error('Cada gasto debe tener un monto o un detalle descriptivo.')
    return null
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

function dependenciaOrganizacional(p: Record<string, unknown>): { tipo: string; nombre: string }[] {
  const items: { tipo: string; nombre: string }[] = []
  const areaNom = p.area_nombre as string | undefined
  if (areaNom) items.push({ tipo: 'Área', nombre: areaNom })
  if (!areaNom) {
    const areasAsig = p.areas_asignadas as string[] | undefined
    if (areasAsig?.length) items.push({ tipo: 'Área', nombre: areasAsig.join(', ') })
  }
  let secNombre = p.secretaria_nombre as string | undefined
  if (!secNombre && p.secretaria != null) {
    const secId = typeof p.secretaria === 'object' ? (p.secretaria as { id?: number }).id : p.secretaria
    const s = secretarias.value.find((x: Record<string, unknown>) => (x.id as number) === Number(secId))
    secNombre = s ? String(s.nombre || s.codigo || '') : undefined
  }
  if (secNombre) items.push({ tipo: 'Secretaría', nombre: secNombre })
  return items
}

function presupuestoItemsProyecto(proyecto: Record<string, unknown> | null): Record<string, unknown>[] {
  if (!proyecto) return []
  const items = proyecto.presupuesto_items
  return Array.isArray(items) ? (items as Record<string, unknown>[]) : []
}

async function descargarExcel() {
  const lista = await fetchAllPages('dashboard/proyectos/', buildProjectParams(1))
  const headers = ['Nombre', 'Dependencia organizacional', 'Avance %', 'Responsable', 'Estado', 'Fecha inicio', 'Fecha fin estimada', 'Descripción']
  const rows = lista.map((p: Record<string, unknown>) => {
    const deps = dependenciaOrganizacional(p)
    const depStr = deps.length ? deps.map(d => `${d.tipo}: ${d.nombre}`).join(' | ') : ''
    return [
    String(p.nombre || ''),
    depStr,
    String(p.porcentaje_avance ?? '0'),
    String(p.responsable_nombre || p.creado_por || ''),
    String(p.estado || ''),
    String(p.fecha_inicio || ''),
    String(p.fecha_fin_estimada || ''),
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
    if (form.value.tipoDependencia === 'area' && form.value.area_id) params.area = form.value.area_id
    else if (form.value.tipoDependencia === 'secretaria' && form.value.secretaria) params.secretaria = form.value.secretaria
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
    area_id: null,
    secretaria: tipoInicial === 'secretaria' ? secretariaId : null,
    equipo: [],
    presupuesto_items: [crearItemPresupuesto()],
  }
  showForm.value = true
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
  const areasProy = proyecto.areas_asignadas as string[] | undefined
  let areaIdResolved: number | null = areaDirect != null ? Number(areaDirect) : null
  if (!areaIdResolved && areasProy?.length && areas.value.length) {
    const primerArea = areas.value.find((a: Record<string, unknown>) =>
      areasProy.includes(String(a.nombre))
    )
    if (primerArea) areaIdResolved = primerArea.id as number
  }
  if (!secId && !areaIdResolved) {
    try {
      const paRes = await api.get('proyecto-area/', { params: { proyecto: p.id } })
      const paList = paRes.data || []
      const firstPa = paList[0] as Record<string, unknown> | undefined
      if (firstPa) areaIdResolved = firstPa.area as number
    } catch { /* ignorar */ }
  }
  const tipo: TipoDependencia = secId ? 'secretaria' : 'area'
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
        : proyecto.creado_por
    ) as number | null,
    tipoDependencia: tipo,
    area_id: tipo === 'area' ? areaIdResolved : null,
    secretaria: tipo === 'secretaria' ? secId : null,
    equipo: equipoIds,
    presupuesto_items: mapPresupuestoItems(proyecto.presupuesto_items),
  }
  showForm.value = true
  loadUsuariosParaResponsable()
}

const save = async () => {
  const { tipoDependencia, area_id, equipo, usuario_responsable, presupuesto_items, ...rest } = form.value
  if (tipoDependencia === 'area' && !area_id) {
    toast.error('Seleccione un área para el proyecto.')
    return
  }
  if (tipoDependencia === 'secretaria' && !form.value.secretaria) {
    toast.error('Seleccione una secretaría para el proyecto.')
    return
  }
  if (!usuario_responsable) {
    toast.error('Seleccione un Responsable Principal.')
    return
  }
  if ((tipoDependencia === 'area' && area_id) || (tipoDependencia === 'secretaria' && form.value.secretaria)) {
    if (!usuariosParaResponsable.value.length) {
      toast.error('No hay usuarios cargados como responsables en esta ' + (tipoDependencia === 'area' ? 'área' : 'secretaría') + '. Debe registrar o asignar responsables primero.')
      return
    }
  }
  const presupuestoPayload = buildPresupuestoPayload()
  if (!presupuestoPayload) return
  const payload = {
    ...rest,
    presupuesto_total: montoToNumber(form.value.presupuesto_total),
    usuario_responsable: usuario_responsable,
    area: tipoDependencia === 'area' ? area_id : null,
    secretaria: tipoDependencia === 'secretaria' ? form.value.secretaria : null,
    equipo: equipo || [],
    presupuesto_items: presupuestoPayload,
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

const { confirmDelete } = useConfirmDelete()
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
      const msg = err.response?.data?.detail || err.response?.data?.error || (err.response?.status === 403 ? 'No tiene permiso para eliminar.' : 'Error al eliminar el proyecto.')
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

const openVer = async (p: Record<string, unknown>) => {
  const detalleRes = await api.get(`proyectos/${p.id}/`).catch(() => ({ data: p }))
  proyectoVer.value = { ...p, ...parseProyectoDetalle(detalleRes) }
  showVerModal.value = true
}

const closeVerModal = () => {
  showVerModal.value = false
  proyectoVer.value = null
}

const openAsignar = async (p: Record<string, unknown>) => {
  proyectoAsignar.value = p
  const proyId = p.id as number
  tipoAsignar.value = (p.secretaria != null && p.secretaria !== '') ? 'secretaria' : 'area'
  areasSeleccionadasAsignar.value = []
  secretariaSeleccionadaAsignar.value = null
  try {
    const paRes = await api.get('proyecto-area/', { params: { proyecto: proyId } })
    const paList = paRes.data || []
    areasSeleccionadasAsignar.value = paList.map((pa: Record<string, unknown>) => pa.area as number)
    const sec = p.secretaria
    const secId = sec != null && typeof sec === 'object' && !Array.isArray(sec) ? (sec as { id?: number }).id : sec
    secretariaSeleccionadaAsignar.value = secId != null ? Number(secId) : null
  } catch {
    areasSeleccionadasAsignar.value = []
    secretariaSeleccionadaAsignar.value = null
  }
  showAsignarModal.value = true
}

const closeAsignarModal = () => {
  showAsignarModal.value = false
  proyectoAsignar.value = null
  areasSeleccionadasAsignar.value = []
  secretariaSeleccionadaAsignar.value = null
}
const closeForm = () => { showForm.value = false }
useModalClose(showVerModal, closeVerModal)
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
      const areaId = areasSeleccionadasAsignar.value[0]
      await api.patch(`proyectos/${proyId}/`, { area: areaId, secretaria: null })
      const paActuales = (await api.get('proyecto-area/', { params: { proyecto: proyId } })).data || []
      for (const pa of paActuales) {
        await api.delete(`proyecto-area/${(pa as Record<string, unknown>).id}/`)
      }
      for (const aid of areasSeleccionadasAsignar.value) {
        await api.post('proyecto-area/', { proyecto: proyId, area: aid })
      }
    } else {
      await api.patch(`proyectos/${proyId}/`, { area: null, secretaria: secretariaSeleccionadaAsignar.value })
      const paActuales = (await api.get('proyecto-area/', { params: { proyecto: proyId } })).data || []
      for (const pa of paActuales) {
        await api.delete(`proyecto-area/${(pa as Record<string, unknown>).id}/`)
      }
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
  () => [form.value.area_id, form.value.secretaria, form.value.tipoDependencia],
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

    <div class="toolbar">
      <input
        v-model="buscarProyecto"
        type="search"
        placeholder="Buscar por nombre del proyecto..."
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

    <div v-else-if="proyectosFiltrados.length" class="table-wrapper">
      <table class="table">
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Dependencia organizacional</th>
            <th>Avance</th>
            <th>Responsable</th>
            <th>Estado</th>
            <th>Fecha inicio</th>
            <th>Fecha fin</th>
            <th class="actions-header">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in proyectosFiltrados" :key="(p.id as number)" :class="claseVencimiento(estadoVencimiento(p.fecha_fin_estimada, p.estado))">
            <td>
              <router-link :to="`/proyectos/${p.id}`">{{ p.nombre || '-' }}</router-link>
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
            <td class="avance-cell">
              <div class="progress-inline">
                <div class="progress-track">
                  <div class="progress-fill" :style="{ width: `${Math.min(100, Number(p.porcentaje_avance) || 0)}%` }" />
                </div>
                <span class="progress-value">{{ Number(p.porcentaje_avance) ?? 0 }}%</span>
              </div>
            </td>
            <td>{{ p.responsable_nombre || p.creado_por || '-' }}</td>
            <td>
              <span class="estado-chip" :class="estadoProyectoClase(p.estado)">{{ p.estado || '-' }}</span>
            </td>
            <td>{{ p.fecha_inicio || '-' }}</td>
            <td class="vencimiento-cell">
              <span v-if="p.fecha_fin_estimada" class="vencimiento-badge" :class="'vencimiento-badge-' + estadoVencimiento(p.fecha_fin_estimada, p.estado)">
                {{ p.fecha_fin_estimada }}
              </span>
              <span v-else class="vencimiento-sin">—</span>
            </td>
            <td class="actions-cell">
              <button class="btn-action" title="Ver" @click="openVer(p)"><IconEye class="btn-icon-sm" /> Ver</button>
              <template v-if="!isVisualizador">
                <button class="btn-action" title="Asignar" @click="openAsignar(p)"><IconPlus class="btn-icon-sm" /> Asignar</button>
                <button class="btn-action" title="Editar" @click="openEdit(p)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button class="btn-action-danger" title="Eliminar" @click="remove(p.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
              </template>
            </td>
          </tr>
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

          <section class="form-section">
            <div class="form-section-header">
              <div>
                <h3>Matriz presupuestaria</h3>
                <p class="hint">Defina el presupuesto total, la fuente y luego agregue los gastos asociados.</p>
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
          <div class="tipo-dependencia-selector">
            <label class="tipo-opt">
              <input type="radio" value="area" v-model="form.tipoDependencia" @change="form.secretaria = null" />
              Área
            </label>
            <label class="tipo-opt">
              <input type="radio" value="secretaria" v-model="form.tipoDependencia" @change="form.area_id = null" />
              Secretaría
            </label>
          </div>
          <template v-if="form.tipoDependencia === 'area'">
            <label>Seleccione el área</label>
            <select v-model.number="form.area_id" :required="form.tipoDependencia === 'area'">
              <option :value="null">— Seleccione un área —</option>
              <option v-for="a in areas" :key="(a.id as number)" :value="a.id">
                {{ a.nombre }}
              </option>
            </select>
          </template>
          <template v-else>
            <label>Seleccione la secretaría</label>
            <select v-model.number="form.secretaria">
              <option :value="null">— Seleccione una secretaría —</option>
              <option v-for="s in secretarias" :key="(s.id as number)" :value="s.id">
                {{ s.codigo }} - {{ s.nombre }}
              </option>
            </select>
          </template>
          <label>Responsable Principal</label>
          <template v-if="cargaUsuariosResponsable">
            <p class="mensaje-carga">Cargando usuarios...</p>
          </template>
          <template v-else-if="(form.tipoDependencia === 'area' && form.area_id) || (form.tipoDependencia === 'secretaria' && form.secretaria)">
            <template v-if="!usuariosParaResponsable.length">
              <p class="mensaje-sin-usuarios">No hay usuarios cargados como responsables en esta {{ form.tipoDependencia === 'area' ? 'área' : 'secretaría' }}.</p>
              <p class="mensaje-sin-usuarios-hint">Debe registrar o asignar responsables a esa dependencia antes de continuar.</p>
            </template>
            <select v-else v-model.number="form.usuario_responsable" required>
              <option :value="null">— Seleccione responsable —</option>
              <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">
                {{ u.nombre_completo || u.nombre }}
              </option>
            </select>
          </template>
          <select v-else v-model.number="form.usuario_responsable" required>
            <option :value="null">— Seleccione responsable —</option>
            <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">
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

    <!-- Modal Ver detalle proyecto -->
    <div v-if="showVerModal && proyectoVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-ver">
        <h2>Detalle del proyecto</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Nombre</span>
            <span class="detalle-valor">{{ proyectoVer.nombre }}</span>
          </div>
          <div class="detalle-row" v-if="proyectoVer.descripcion">
            <span class="detalle-label">Descripción</span>
            <p class="detalle-valor detalle-desc">{{ proyectoVer.descripcion }}</p>
          </div>
          <div class="detalle-grid">
            <div class="detalle-row">
              <span class="detalle-label">Estado</span>
              <span class="detalle-valor">{{ proyectoVer.estado }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Avance</span>
              <span class="detalle-valor">{{ Number(proyectoVer.porcentaje_avance) ?? 0 }}%</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Responsable</span>
              <span class="detalle-valor">{{ proyectoVer.responsable_nombre || proyectoVer.creado_por || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Fecha inicio</span>
              <span class="detalle-valor">{{ proyectoVer.fecha_inicio || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Fecha fin estimada</span>
              <span class="detalle-valor">{{ proyectoVer.fecha_fin_estimada || '-' }}</span>
            </div>
          </div>
          <div class="detalle-row" v-if="dependenciaOrganizacional(proyectoVer).length">
            <span class="detalle-label">Dependencia organizacional</span>
            <div class="detalle-valor">
              <span
                v-for="(d, i) in dependenciaOrganizacional(proyectoVer)"
                :key="i"
                class="dependencia-badge"
                :class="d.tipo === 'Secretaría' ? 'badge-secretaria' : 'badge-area'"
              >
                {{ d.tipo }}: {{ d.nombre }}
              </span>
            </div>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Presupuesto</span>
            <div class="detalle-presupuesto">
              <div class="detalle-presupuesto-resumen">
                <div class="detalle-row">
                  <span class="detalle-label">Presupuesto total</span>
                  <span class="detalle-valor">{{ formatCurrency(Number(proyectoVer.presupuesto_total) || 0) }}</span>
                </div>
                <div class="detalle-row">
                  <span class="detalle-label">Fuente de financiamiento</span>
                  <span class="detalle-valor">{{ proyectoVer.fuente_financiamiento || '-' }}</span>
                </div>
                <div class="detalle-row">
                  <span class="detalle-label">Total cargado</span>
                  <span class="detalle-valor">{{ formatCurrency(Number(proyectoVer.presupuesto_cargado) || 0) }}</span>
                </div>
              </div>
              <div v-if="presupuestoItemsProyecto(proyectoVer).length" class="detalle-presupuesto-gastos">
                <div
                  v-for="(item, index) in presupuestoItemsProyecto(proyectoVer)"
                  :key="item.id ?? `ver-presupuesto-${index}`"
                  class="detalle-presupuesto-item"
                >
                  <div class="detalle-presupuesto-item-head">
                    <strong>{{ item.categoria_gasto || `Gasto ${index + 1}` }}</strong>
                    <span>{{ formatCurrency(Number(item.monto) || 0) }}</span>
                  </div>
                  <p class="detalle-presupuesto-texto">
                    {{ item.detalle || 'Sin observaciones cargadas.' }}
                  </p>
                </div>
              </div>
              <p v-else class="detalle-presupuesto-vacio">No hay gastos presupuestarios cargados.</p>
            </div>
          </div>
        </div>
        <div class="modal-actions">
          <router-link v-if="proyectoVer.id" :to="`/proyectos/${proyectoVer.id}`" class="btn-primary">Ver proyecto completo</router-link>
          <button type="button" class="btn-cancel" @click="closeVerModal"><IconCancel class="btn-icon" /> Cerrar</button>
        </div>
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
            <label>Seleccione la secretaría</label>
            <select v-model.number="secretariaSeleccionadaAsignar">
              <option :value="null">— Sin secretaría —</option>
              <option v-for="s in secretariasActivas" :key="(s.id as number)" :value="s.id">
                {{ s.codigo }} - {{ s.nombre }}
              </option>
            </select>
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
.table tbody tr:hover { background: #f8fbff; }
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
.dependencia-cell { min-width: 180px; }
.avance-cell { min-width: 190px; }
.progress-inline {
  display: flex;
  align-items: center;
  gap: 0.7rem;
}
.progress-track {
  flex: 1;
  height: 10px;
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
  min-width: 2.8rem;
  font-weight: 700;
  color: #0f172a;
  font-size: 0.88rem;
}
.dependencia-badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: 6px;
  font-size: 0.85rem;
  margin-right: 0.35rem;
  margin-bottom: 0.25rem;
}
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
}
@media (max-width: 700px) {
  .summary-grid { grid-template-columns: 1fr; }
  .page-hero { padding: 1rem; }
}
</style>
