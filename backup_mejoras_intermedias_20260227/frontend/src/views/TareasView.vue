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
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { useAuth } from '@/composables/useAuth'
import { useModalClose } from '@/composables/useModalClose'
import EmptyState from '@/components/EmptyState.vue'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import { extraerMensajeError } from '@/utils/apiError'

const route = useRoute()
const router = useRouter()
const { user, isAdmin, isVisualizador } = useAuth()
const MINUTOS_EDICION = 15

function puedeEditarEliminarComentario(c: Record<string, unknown>): boolean {
  if (!user.value) return false
  if (isAdmin.value) return true
  if ((c.usuario as number) !== user.value.id) return false
  const fecha = new Date((c.fecha as string) || 0).getTime()
  const ahora = Date.now()
  return (ahora - fecha) / 60000 <= MINUTOS_EDICION
}
const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const tareas = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const areas = ref<Record<string, unknown>[]>([])
const secretarias = ref<Record<string, unknown>[]>([])
const usuarios = ref<Record<string, unknown>[]>([])
const usuariosParaResponsable = ref<Record<string, unknown>[]>([])
const cargaUsuariosResponsable = ref(false)
const tipoOrganizacion = ref<'area' | 'secretaria' | 'ninguna'>('area')
const showForm = ref(false)
const editingId = ref<number | null>(null)
const showAsignarModal = ref(false)
const tareaAsignar = ref<Record<string, unknown> | null>(null)
const showVerModal = ref(false)
const tareaVer = ref<Record<string, unknown> | null>(null)
const tipoAsignar = ref<'area' | 'secretaria' | 'ninguna'>('area')
const areaAsignar = ref<number | null>(null)
const secretariaAsignar = ref<number | null>(null)
const guardandoAsignar = ref(false)
const filtroEstado = ref('')
const buscarTitulo = ref('')
const form = ref({
  proyecto: null as number | null,
  tarea_padre: null as number | null,
  etapa: null as number | null,
  area: null as number | null,
  secretaria: null as number | null,
  titulo: '',
  descripcion: '',
  responsable: null as number | null,
  fecha_inicio: '',
  fecha_vencimiento: '',
  estado: 'Pendiente',
  porcentaje_avance: 0,
  prioridad: 'Media',
})

function parseListResponse(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

async function cargarProyectosParaSelector() {
  try {
    const res = await api.get('dashboard/proyectos/')
    proyectos.value = parseListResponse(res.data)
  } catch {
    const res = await api.get('proyectos/')
    proyectos.value = parseListResponse(res.data)
  }
}

const load = async () => {
  const params: Record<string, string | number> = {}
  if (filtroEstado.value) params.estado = filtroEstado.value
  if (typeof route.query.responsable === 'string' && route.query.responsable) {
    params.responsable = route.query.responsable
  }
  const [t, a, s, uRes] = await Promise.all([
    api.get('tareas/', { params }),
    api.get('areas/', { params: { estado: 'true' } }).catch(() => ({ data: [] })),
    api.get('secretarias/', { params: { activa: 'true' } }).catch(() => ({ data: [] })),
    api.get('usuarios/selector/').catch(() => api.get('usuarios/').then(r => ({
      data: Array.isArray(r.data) ? r.data : (r.data?.results ?? []),
    })).catch(() => ({ data: [] }))),
  ])
  tareas.value = parseListResponse(t.data)
  areas.value = parseListResponse(a.data)
  secretarias.value = parseListResponse(s.data)
  usuarios.value = parseListResponse(uRes.data)
  await cargarProyectosParaSelector()
}

function coincideFiltroVencimientoTarea(t: Record<string, unknown>, filtro: string): boolean {
  if (!filtro) return true
  const estado = estadoVencimiento(t.fecha_vencimiento as string | undefined, t.estado as string | undefined)
  if (filtro === 'vencidas') return estado === 'vencida'
  if (filtro === 'proximas') return estado === 'proxima'
  if (filtro === 'en-plazo') return estado === 'dentro-plazo'
  return true
}

const filtroRutaTexto = computed(() => {
  const partes: string[] = []
  if (typeof route.query.estado === 'string' && route.query.estado) partes.push(`Estado: ${route.query.estado}`)
  if (typeof route.query.responsable === 'string' && route.query.responsable) {
    const usuario = usuarios.value.find((u: Record<string, unknown>) => String(u.id) === route.query.responsable)
    const nombre = usuario ? String((usuario.nombre_completo as string) || `${usuario.nombre || ''} ${usuario.apellido || ''}`.trim()) : route.query.responsable
    partes.push(`Responsable: ${nombre}`)
  }
  if (typeof route.query.vencimiento === 'string' && route.query.vencimiento) {
    const map: Record<string, string> = {
      'vencidas': 'Vencidas',
      'proximas': 'Próximas 7 días',
      'en-plazo': 'En plazo',
    }
    partes.push(`Vencimiento: ${map[route.query.vencimiento] || route.query.vencimiento}`)
  }
  return partes.join(' | ')
})

async function loadUsuariosParaResponsable() {
  if (!showForm.value) return
  cargaUsuariosResponsable.value = true
  try {
    const params: Record<string, number> = {}
    if (tipoOrganizacion.value === 'area' && form.value.area) params.area = form.value.area
    else if (tipoOrganizacion.value === 'secretaria' && form.value.secretaria) params.secretaria = form.value.secretaria
    const res = await api.get('usuarios/selector/', { params })
    const lista = Array.isArray(res.data) ? res.data : []
    usuariosParaResponsable.value = lista
    const ids = new Set(lista.map((u: Record<string, unknown>) => u.id))
    if (form.value.responsable && !ids.has(form.value.responsable)) {
      form.value.responsable = null
    }
  } catch {
    usuariosParaResponsable.value = []
    form.value.responsable = null
  } finally {
    cargaUsuariosResponsable.value = false
  }
}

watch(
  () => [form.value.area, form.value.secretaria, tipoOrganizacion.value],
  () => { if (showForm.value) loadUsuariosParaResponsable() },
  { deep: true }
)

const openCreate = async () => {
  editingId.value = null
  await cargarProyectosParaSelector()
  tipoOrganizacion.value = 'area'
  form.value = {
    proyecto: null,
    tarea_padre: null,
    etapa: null,
    area: null,
    secretaria: null,
    titulo: '',
    descripcion: '',
    responsable: null,
    fecha_inicio: '',
    fecha_vencimiento: '',
    estado: 'Pendiente',
    porcentaje_avance: 0,
    prioridad: 'Media',
  }
  showForm.value = true
  loadUsuariosParaResponsable()
}

const openEdit = (t: Record<string, unknown>) => {
  editingId.value = t.id as number
  const areaId = t.area ? (typeof t.area === 'object' ? (t.area as { id?: number }).id : t.area) : null
  const secretariaId = t.secretaria ? (typeof t.secretaria === 'object' ? (t.secretaria as { id?: number }).id : t.secretaria) : null
  tipoOrganizacion.value = secretariaId ? 'secretaria' : (areaId ? 'area' : 'ninguna')
  const proyId = t.proyecto ? (typeof t.proyecto === 'object' ? (t.proyecto as { id?: number }).id : t.proyecto) : null
  const padreId = t.tarea_padre ? (typeof t.tarea_padre === 'object' ? (t.tarea_padre as { id?: number }).id : t.tarea_padre) : null
  form.value = {
    proyecto: proyId != null ? Number(proyId) : null,
    tarea_padre: padreId != null ? Number(padreId) : null,
    etapa: t.etapa as number | null,
    area: areaId != null ? Number(areaId) : null,
    secretaria: secretariaId != null ? Number(secretariaId) : null,
    titulo: (t.titulo as string) || '',
    descripcion: (t.descripcion as string) || '',
    responsable: t.responsable as number,
    fecha_inicio: (t.fecha_inicio as string) || '',
    fecha_vencimiento: (t.fecha_vencimiento as string) || '',
    estado: (t.estado as string) || 'Pendiente',
    porcentaje_avance: (t.porcentaje_avance as number) || 0,
    prioridad: (t.prioridad as string) || 'Media',
  }
  showForm.value = true
  loadUsuariosParaResponsable()
}

function extraerMensajeError(e: unknown): string {
  const err = e as { response?: { data?: Record<string, unknown> | string; status?: number } }
  const data = err.response?.data
  if (typeof data === 'string') return data
  if (data && typeof data === 'object') {
    if (typeof data.detail === 'string') return data.detail
    const msgs = data as Record<string, string[] | string>
    const primera = Object.entries(msgs).find(([, v]) => Array.isArray(v) ? v.length : v)
    if (primera) {
      const val = primera[1]
      return Array.isArray(val) ? val[0] : val
    }
  }
  return 'Error al guardar la tarea.'
}

const save = async () => {
  try {
    const payload = { ...form.value } as Record<string, unknown>
    if (tipoOrganizacion.value === 'area') {
      payload.secretaria = null
    } else if (tipoOrganizacion.value === 'secretaria') {
      payload.area = null
    } else {
      payload.area = null
      payload.secretaria = null
    }
    if (!payload.proyecto) {
      payload.etapa = null
    }
    if (payload.tarea_padre === '' || payload.tarea_padre === undefined) payload.tarea_padre = null
    if (payload.proyecto === '' || payload.proyecto === undefined) payload.proyecto = null
    if (payload.responsable === '' || payload.responsable === undefined) payload.responsable = null
    if (payload.area === '' || payload.area === undefined) payload.area = null
    if (payload.secretaria === '' || payload.secretaria === undefined) payload.secretaria = null
    if (payload.etapa === '' || payload.etapa === undefined) payload.etapa = null
    if (!payload.titulo?.toString().trim()) {
      toast.error('El título es obligatorio.')
      return
    }
    if (!payload.responsable) {
      toast.error('Debe seleccionar un responsable.')
      return
    }
    if ((tipoOrganizacion.value === 'area' && form.value.area) || (tipoOrganizacion.value === 'secretaria' && form.value.secretaria)) {
      if (!usuariosParaResponsable.value.length) {
        toast.error('No hay usuarios cargados como responsables en esta ' + (tipoOrganizacion.value === 'area' ? 'área' : 'secretaría') + '. Debe registrar o asignar responsables primero.')
        return
      }
    }
    if (!payload.fecha_inicio || !payload.fecha_vencimiento) {
      toast.error('Las fechas de inicio y vencimiento son obligatorias.')
      return
    }
    if (editingId.value) {
      await api.patch(`tareas/${editingId.value}/`, payload)
      toast.success('Tarea actualizada correctamente.')
    } else {
      await api.post('tareas/', payload)
      toast.success('Tarea creada correctamente.')
    }
    showForm.value = false
    load()
  } catch (e) {
    toast.error(extraerMensajeError(e))
  }
}

const remove = async (id: number) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`tareas/${id}/`)
      toast.success('Registro eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar la tarea.')
    }
  }
}

const comentariosTareaVer = ref<Record<string, unknown>[]>([])
const adjuntosTareaVer = ref<Record<string, unknown>[]>([])
const nuevoComentarioVer = ref('')
const comentarioEditandoVer = ref<number | null>(null)
const textoEditandoVer = ref('')
const adjuntoEditandoVer = ref<number | null>(null)
const nombreAdjuntoEditandoVer = ref('')

function puedeModificarAdjunto(a: Record<string, unknown>): boolean {
  if (!user.value) return false
  if (isAdmin.value) return true
  return (a.subido_por as number) === user.value.id
}
const archivoAdjuntoVer = ref<HTMLInputElement | null>(null)
const subiendoAdjuntoVer = ref(false)

const openVer = async (t: Record<string, unknown>) => {
  tareaVer.value = t
  showVerModal.value = true
  nuevoComentarioVer.value = ''
  try {
    const [comRes, adjRes] = await Promise.all([
      api.get('comentarios-tarea/', { params: { tarea: t.id } }),
      api.get('adjuntos-tarea/', { params: { tarea: t.id } }),
    ])
    comentariosTareaVer.value = Array.isArray(comRes.data) ? comRes.data : (comRes.data?.results || [])
    adjuntosTareaVer.value = Array.isArray(adjRes.data) ? adjRes.data : (adjRes.data?.results || [])
  } catch {
    comentariosTareaVer.value = []
    adjuntosTareaVer.value = []
  }
}

const closeVerModal = () => {
  showVerModal.value = false
  tareaVer.value = null
  comentarioEditandoVer.value = null
  textoEditandoVer.value = ''
  adjuntoEditandoVer.value = null
  nombreAdjuntoEditandoVer.value = ''
}

async function guardarComentarioVer() {
  const t = tareaVer.value
  if (!t || !nuevoComentarioVer.value.trim()) return
  try {
    await api.post('comentarios-tarea/', { tarea: t.id, texto: nuevoComentarioVer.value.trim() })
    nuevoComentarioVer.value = ''
    const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
    comentariosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Comentario guardado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al guardar el comentario.'))
  }
}

function iniciarEdicionComentarioVer(c: Record<string, unknown>) {
  comentarioEditandoVer.value = c.id as number
  textoEditandoVer.value = (c.texto as string) || ''
}

function cancelarEdicionComentarioVer() {
  comentarioEditandoVer.value = null
  textoEditandoVer.value = ''
}

async function guardarEdicionComentarioVer() {
  const t = tareaVer.value
  const id = comentarioEditandoVer.value
  if (!t || !id || !textoEditandoVer.value.trim()) return
  try {
    await api.patch(`comentarios-tarea/${id}/`, { texto: textoEditandoVer.value.trim() })
    const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
    comentariosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    comentarioEditandoVer.value = null
    textoEditandoVer.value = ''
    toast.success('Comentario actualizado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al actualizar el comentario.'))
  }
}

async function eliminarComentarioVer(c: Record<string, unknown>) {
  const t = tareaVer.value
  if (!t || !(await confirmDelete())) return
  try {
    await api.delete(`comentarios-tarea/${c.id}/`)
    const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
    comentariosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Comentario eliminado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al eliminar el comentario.'))
  }
}

function iniciarEdicionAdjuntoVer(a: Record<string, unknown>) {
  adjuntoEditandoVer.value = a.id as number
  nombreAdjuntoEditandoVer.value = (a.nombre_original as string) || ''
}

function cancelarEdicionAdjuntoVer() {
  adjuntoEditandoVer.value = null
  nombreAdjuntoEditandoVer.value = ''
}

async function guardarEdicionAdjuntoVer() {
  const t = tareaVer.value
  const id = adjuntoEditandoVer.value
  if (!t || !id || !nombreAdjuntoEditandoVer.value.trim()) return
  try {
    await api.patch(`adjuntos-tarea/${id}/`, { nombre_original: nombreAdjuntoEditandoVer.value.trim() })
    const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
    adjuntosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    adjuntoEditandoVer.value = null
    nombreAdjuntoEditandoVer.value = ''
    toast.success('Adjunto actualizado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al actualizar el adjunto.'))
  }
}

async function eliminarAdjuntoVer(a: Record<string, unknown>) {
  const t = tareaVer.value
  if (!t || !(await confirmDelete())) return
  try {
    await api.delete(`adjuntos-tarea/${a.id}/`)
    const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
    adjuntosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Adjunto eliminado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al eliminar el adjunto.'))
  }
}

async function subirAdjuntoVer() {
  const t = tareaVer.value
  const input = archivoAdjuntoVer.value
  if (!t || !input?.files?.length) return
  const file = input.files[0]
  if (!file) return
  subiendoAdjuntoVer.value = true
  try {
    const formData = new FormData()
    formData.append('tarea', String(t.id))
    formData.append('archivo', file)
    formData.append('nombre_original', file.name)
    await api.post('adjuntos-tarea/', formData)
    const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
    adjuntosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Archivo subido correctamente.')
    input.value = ''
  } catch {
    toast.error('Error al subir el archivo.')
  } finally {
    subiendoAdjuntoVer.value = false
  }
}

const openAsignar = (t: Record<string, unknown>) => {
  tareaAsignar.value = t
  const areaId = t.area ? (typeof t.area === 'object' ? (t.area as { id?: number }).id : t.area) : null
  const secretariaId = t.secretaria ? (typeof t.secretaria === 'object' ? (t.secretaria as { id?: number }).id : t.secretaria) : null
  tipoAsignar.value = secretariaId ? 'secretaria' : (areaId ? 'area' : 'ninguna')
  areaAsignar.value = areaId != null ? Number(areaId) : null
  secretariaAsignar.value = secretariaId != null ? Number(secretariaId) : null
  showAsignarModal.value = true
}

const closeAsignarModal = () => {
  showAsignarModal.value = false
  tareaAsignar.value = null
  areaAsignar.value = null
  secretariaAsignar.value = null
}
const closeForm = () => { showForm.value = false }
useModalClose(showVerModal, closeVerModal)
useModalClose(showAsignarModal, closeAsignarModal)
useModalClose(showForm, closeForm)

const guardarAsignar = async () => {
  if (!tareaAsignar.value) return
  const id = tareaAsignar.value.id as number
  if (tipoAsignar.value === 'area') {
    if (!areaAsignar.value) {
      toast.error('Seleccione un área.')
      return
    }
  } else if (tipoAsignar.value === 'secretaria') {
    if (!secretariaAsignar.value) {
      toast.error('Seleccione una secretaría.')
      return
    }
  }
  guardandoAsignar.value = true
  try {
    const payload = tipoAsignar.value === 'area'
      ? { area: areaAsignar.value, secretaria: null }
      : tipoAsignar.value === 'secretaria'
        ? { area: null, secretaria: secretariaAsignar.value }
        : { area: null, secretaria: null }
    await api.patch(`tareas/${id}/`, payload)
    toast.success('Tarea asignada correctamente.')
    closeAsignarModal()
    load()
  } catch {
    toast.error('Error al asignar la tarea.')
  } finally {
    guardandoAsignar.value = false
  }
}

async function descargarExcel() {
  const lista = tareasFiltradas.value
  const headers = ['Título', 'Tarea padre', 'Área/Secretaría', 'Usuario responsable', 'Estado', 'Avance %', 'Prioridad', 'Proyecto']
  const rows = lista.map((t: Record<string, unknown>) => [
    String(t.titulo || ''),
    String(t.tarea_padre_nombre || '-'),
    String(t.organizacion_nombre || t.area_nombre || t.secretaria_nombre || ''),
    String(t.responsable_nombre || ''),
    String(t.estado || ''),
    String(t.porcentaje_avance ?? '0'),
    String(t.prioridad || ''),
    String(t.proyecto_nombre || t.proyecto || ''),
  ])
  await exportToCsv(headers, rows, `tareas_${new Date().toISOString().slice(0, 10)}.csv`)
}

const ESTADOS = [
  { value: '', label: 'Todos' },
  { value: 'Pendiente', label: 'Pendiente' },
  { value: 'En proceso', label: 'En proceso' },
  { value: 'Finalizada', label: 'Finalizada' },
  { value: 'Bloqueada', label: 'Bloqueada' },
] as const

const tareasFiltradas = computed(() => {
  const lista = tareas.value
  const q = buscarTitulo.value.trim().toLowerCase()
  const filtroVencimiento = typeof route.query.vencimiento === 'string' ? route.query.vencimiento : ''
  return lista.filter((t: Record<string, unknown>) =>
    (!q || String(t.titulo || '').toLowerCase().includes(q)) &&
    coincideFiltroVencimientoTarea(t, filtroVencimiento)
  )
})

const tareasRaiz = computed(() =>
  tareas.value.filter((t: Record<string, unknown>) => !t.tarea_padre)
)

const tareasParaTabla = computed(() => {
  const lista = tareasFiltradas.value
  const resultado: { tarea: Record<string, unknown>; esSubtarea: boolean }[] = []
  const idsIncluidos = new Set<number>()
  const raices = lista.filter((t: Record<string, unknown>) => !t.tarea_padre)
  for (const t of raices) {
    resultado.push({ tarea: t, esSubtarea: false })
    idsIncluidos.add(t.id as number)
    const hijos = (t.subtareas as Record<string, unknown>[]) || []
    for (const h of hijos) {
      resultado.push({ tarea: h, esSubtarea: true })
      idsIncluidos.add(h.id as number)
    }
  }
  for (const t of lista) {
    if (t.tarea_padre && !idsIncluidos.has(t.id as number)) {
      resultado.push({ tarea: t, esSubtarea: true })
    }
  }
  return resultado
})

const tareasParaPadre = computed(() => {
  const raices = tareasRaiz.value
  const id = editingId.value
  if (!id) return raices
  return raices.filter((t: Record<string, unknown>) => (t.id as number) !== id)
})

async function abrirDetalleDesdeRuta() {
  const verId = route.query.ver
  if (!verId) return
  const id = Number(verId)
  if (!id) return
  try {
    const res = await api.get(`tareas/${id}/`)
    const t = res.data as Record<string, unknown>
    openVer(t)
    const nextQuery = { ...route.query }
    delete nextQuery.ver
    router.replace({ path: '/tareas', query: nextQuery })
  } catch {
    toast.error('No se pudo cargar el detalle de la tarea.')
  }
}

onMounted(async () => {
  filtroEstado.value = typeof route.query.estado === 'string' ? route.query.estado : ''
  await load()
  await abrirDetalleDesdeRuta()
})

watch(
  () => [route.query.estado, route.query.responsable, route.query.vencimiento],
  async () => {
    filtroEstado.value = typeof route.query.estado === 'string' ? route.query.estado : ''
    await load()
  }
)

watch(() => route.query.ver, async () => {
  await abrirDetalleDesdeRuta()
})
</script>

<template>
  <div class="page">
    <h1>Tareas</h1>
    <p v-if="isVisualizador" class="subtitle-rol">Vista de solo lectura: puede consultar y exportar todas las tareas del sistema.</p>
    <p v-if="filtroRutaTexto" class="filter-hint">
      Filtros aplicados: <strong>{{ filtroRutaTexto }}</strong>.
      <router-link :to="{ path: '/tareas' }">Ver todas</router-link>
    </p>
    <div class="toolbar">
      <div class="search-wrapper">
        <span class="search-icon">🔍</span>
        <input
          v-model="buscarTitulo"
          type="search"
          placeholder="Buscar por título..."
          class="search-input"
        />
      </div>
      <div class="estado-selector">
        <button
          v-for="opt in ESTADOS"
          :key="opt.value || '_todos'"
          type="button"
          class="estado-pill"
          :class="{ active: filtroEstado === opt.value }"
          @click="filtroEstado = opt.value; load()"
        >
          {{ opt.label }}
        </button>
      </div>
      <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!tareasFiltradas.length">
        <IconDownload class="btn-icon" />
        Descargar Excel
      </button>
      <button v-if="!isVisualizador" class="btn-primary" @click="openCreate">
        <IconPlus class="btn-icon" />
        Nueva tarea
      </button>
    </div>

    <div class="vencimiento-leyenda">
      <span class="leyenda-item vencida">Vencida</span>
      <span class="leyenda-item proxima">Próxima a vencer (7 días)</span>
      <span class="leyenda-item dentro">Dentro del plazo</span>
    </div>

    <EmptyState
      v-if="!tareasParaTabla.length"
      :titulo="buscarTitulo.trim() ? 'Sin resultados' : 'No hay tareas'"
      :mensaje="buscarTitulo.trim() ? 'No se encontraron tareas que coincidan con la búsqueda. Intente con otros términos o cambie el filtro de estado.' : 'Aún no hay tareas cargadas. Use el botón «Nueva tarea» para crear la primera.'"
      :icono="buscarTitulo.trim() ? 'busqueda' : 'tareas'"
    />
    <div v-else class="table-wrapper">
      <table class="table">
      <thead>
        <tr>
          <th>Título</th>
          <th>Padre</th>
          <th>Área / Secretaría</th>
          <th>Usuario</th>
          <th>Estado</th>
          <th>Avance</th>
          <th>Prioridad</th>
          <th>Fecha</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in tareasParaTabla" :key="(item.tarea.id as number)" :class="[claseVencimiento(estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)), item.esSubtarea ? 'row-subtarea' : '']">
          <td :class="{ 'cell-indent': item.esSubtarea }">
            <span v-if="item.esSubtarea" class="subtarea-icon">↳</span>
            {{ item.tarea.titulo }}
          </td>
          <td>{{ item.esSubtarea ? (item.tarea.tarea_padre_nombre || '-') : '—' }}</td>
          <td>{{ item.tarea.organizacion_nombre || item.tarea.area_nombre || item.tarea.secretaria_nombre || '-' }}</td>
          <td>{{ item.tarea.responsable_nombre || '-' }}</td>
          <td>{{ item.tarea.estado }}</td>
          <td>{{ item.tarea.porcentaje_avance }}%</td>
          <td>{{ item.tarea.prioridad }}</td>
          <td class="vencimiento-cell">
            <span v-if="item.tarea.fecha_vencimiento" class="vencimiento-badge" :class="'vencimiento-badge-' + estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)">
              {{ item.tarea.fecha_vencimiento }}
            </span>
            <span v-else class="vencimiento-sin">—</span>
          </td>
          <td class="actions-cell">
            <button class="btn-action" title="Ver" @click="openVer(item.tarea)"><IconEye class="btn-icon-sm" /> Ver</button>
            <template v-if="!isVisualizador">
              <button class="btn-action" title="Asignar" @click="openAsignar(item.tarea)"><IconPlus class="btn-icon-sm" /> Asignar</button>
              <button class="btn-action" title="Editar" @click="openEdit(item.tarea)"><IconEdit class="btn-icon-sm" /> Editar</button>
              <button class="btn-action-danger" title="Eliminar" @click="remove(item.tarea.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal modal-wide">
        <h2>{{ editingId ? 'Editar' : 'Nueva' }} tarea</h2>
        <form @submit.prevent="save">
          <label>Título</label>
          <input v-model="form.titulo" placeholder="Título" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="2" />
          <label>Proyecto</label>
          <select v-model="form.proyecto" @change="!form.proyecto && (form.etapa = null)">
            <option :value="null">Sin proyecto (tarea independiente)</option>
            <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
          </select>
          <label>Tarea padre (subtarea de)</label>
          <select v-model="form.tarea_padre">
            <option :value="null">Ninguna (tarea raíz)</option>
            <option v-for="tr in tareasParaPadre" :key="(tr.id as number)" :value="tr.id">
              {{ tr.titulo }} {{ tr.proyecto_nombre ? `(${tr.proyecto_nombre})` : '(sin proyecto)' }}
            </option>
          </select>
          <label>Vinculación organizacional</label>
          <div class="radio-group">
            <label class="radio-label">
              <input v-model="tipoOrganizacion" type="radio" value="area" @change="form.area = null; form.secretaria = null" />
              Área
            </label>
            <label class="radio-label">
              <input v-model="tipoOrganizacion" type="radio" value="secretaria" @change="form.area = null; form.secretaria = null" />
              Secretaría
            </label>
            <label class="radio-label">
              <input v-model="tipoOrganizacion" type="radio" value="ninguna" @change="form.area = null; form.secretaria = null" />
              Ninguna
            </label>
          </div>
          <template v-if="tipoOrganizacion === 'area'">
            <label>Área</label>
            <select v-model="form.area">
              <option :value="null">Seleccionar área</option>
              <option v-for="a in areas" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
            </select>
          </template>
          <template v-else-if="tipoOrganizacion === 'secretaria'">
            <label>Secretaría</label>
            <select v-model="form.secretaria">
              <option :value="null">Seleccionar secretaría</option>
              <option v-for="s in secretarias" :key="(s.id as number)" :value="s.id">{{ s.codigo }} - {{ s.nombre }}</option>
            </select>
          </template>
          <label>Responsable</label>
          <template v-if="cargaUsuariosResponsable">
            <p class="mensaje-carga">Cargando usuarios...</p>
          </template>
          <template v-else-if="(tipoOrganizacion === 'area' && form.area) || (tipoOrganizacion === 'secretaria' && form.secretaria)">
            <template v-if="!usuariosParaResponsable.length">
              <p class="mensaje-sin-usuarios">No hay usuarios cargados como responsables en esta {{ tipoOrganizacion === 'area' ? 'área' : 'secretaría' }}.</p>
              <p class="mensaje-sin-usuarios-hint">Debe registrar o asignar responsables a esa dependencia antes de continuar.</p>
            </template>
            <select v-else v-model="form.responsable" required>
              <option :value="null">Seleccionar</option>
              <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">{{ u.nombre_completo || u.nombre }}</option>
            </select>
          </template>
          <select v-else v-model="form.responsable" required>
            <option :value="null">Seleccionar</option>
            <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">{{ u.nombre_completo || u.nombre }}</option>
          </select>
          <div class="row-dates">
            <div class="col-dates">
              <label>Fecha de inicio</label>
              <input v-model="form.fecha_inicio" type="date" required />
              <label>Fecha de vencimiento</label>
              <input v-model="form.fecha_vencimiento" type="date" required />
            </div>
            <div class="col-prioridad">
              <label>Prioridad</label>
              <select v-model="form.prioridad">
                <option value="Baja">Baja</option>
                <option value="Media">Media</option>
                <option value="Alta">Alta</option>
              </select>
            </div>
          </div>
          <div class="row">
            <div>
              <label>Estado</label>
              <select v-model="form.estado">
                <option value="Pendiente">Pendiente</option>
                <option value="En proceso">En proceso</option>
                <option value="Finalizada">Finalizada</option>
                <option value="Bloqueada">Bloqueada</option>
              </select>
            </div>
            <div>
              <label>Avance %</label>
              <input v-model.number="form.porcentaje_avance" type="number" min="0" max="100" />
            </div>
          </div>
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="closeForm"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal Ver detalle tarea -->
    <div v-if="showVerModal && tareaVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-wide modal-ver">
        <h2>Detalle de la tarea</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Título</span>
            <span class="detalle-valor">{{ tareaVer.titulo }}</span>
          </div>
          <div class="detalle-row" v-if="tareaVer.descripcion">
            <span class="detalle-label">Descripción</span>
            <p class="detalle-valor detalle-desc">{{ tareaVer.descripcion }}</p>
          </div>
          <div class="detalle-grid">
            <div class="detalle-row" v-if="tareaVer.tarea_padre_nombre">
              <span class="detalle-label">Tarea padre</span>
              <span class="detalle-valor">{{ tareaVer.tarea_padre_nombre }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Proyecto</span>
              <span class="detalle-valor">{{ tareaVer.proyecto_nombre || 'Sin proyecto' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Área / Secretaría</span>
              <span class="detalle-valor">{{ tareaVer.organizacion_nombre || tareaVer.area_nombre || tareaVer.secretaria_nombre || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Responsable</span>
              <span class="detalle-valor">{{ tareaVer.responsable_nombre || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Estado</span>
              <span class="detalle-valor">{{ tareaVer.estado }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Avance</span>
              <span class="detalle-valor">{{ tareaVer.porcentaje_avance }}%</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Prioridad</span>
              <span class="detalle-valor">{{ tareaVer.prioridad }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Fecha inicio</span>
              <span class="detalle-valor">{{ tareaVer.fecha_inicio || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Fecha vencimiento</span>
              <span class="detalle-valor">{{ tareaVer.fecha_vencimiento || '-' }}</span>
            </div>
          </div>
        </div>
        <div class="detalle-section">
          <h3>Historial de comentarios</h3>
          <p v-if="comentariosTareaVer.length" class="comentario-leyenda">Orden cronológico (del más antiguo al más reciente)</p>
          <div v-if="comentariosTareaVer.length" class="comentarios-lista">
            <div v-for="c in comentariosTareaVer" :key="(c.id as number)" class="comentario-item comentario-item-editable">
              <div class="comentario-header">
                <span class="comentario-meta">{{ c.usuario_nombre }} · {{ new Date(c.fecha).toLocaleString('es-CL') }}</span>
                <span v-if="c.editado_leyenda" class="editado-leyenda">{{ c.editado_leyenda }}</span>
                <div v-if="!isVisualizador && puedeEditarEliminarComentario(c)" class="comentario-acciones">
                  <button v-if="comentarioEditandoVer !== c.id" type="button" class="btn-icon-mini" title="Editar" @click="iniciarEdicionComentarioVer(c)">
                    <IconEdit class="btn-icon-sm" />
                  </button>
                  <button v-if="comentarioEditandoVer !== c.id" type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarComentarioVer(c)">
                    <IconTrash class="btn-icon-sm" />
                  </button>
                </div>
              </div>
              <template v-if="comentarioEditandoVer === c.id">
                <textarea v-model="textoEditandoVer" rows="2" class="edit-textarea" />
                <div class="edit-acciones">
                  <button type="button" class="btn-small" @click="guardarEdicionComentarioVer">Guardar</button>
                  <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionComentarioVer">Cancelar</button>
                </div>
              </template>
              <p v-else class="comentario-texto">{{ c.texto }}</p>
            </div>
          </div>
          <div class="comentario-add">
            <textarea v-model="nuevoComentarioVer" placeholder="Agregar comentario..." rows="2" />
            <button type="button" class="btn-small" @click="guardarComentarioVer" :disabled="!nuevoComentarioVer.trim()">Enviar</button>
          </div>
        </div>
        <div class="detalle-section">
          <h3>Adjuntos</h3>
          <div v-if="adjuntosTareaVer.length" class="adjuntos-lista">
            <div v-for="a in adjuntosTareaVer" :key="(a.id as number)" class="adjunto-item">
              <template v-if="adjuntoEditandoVer === a.id">
                <input v-model="nombreAdjuntoEditandoVer" type="text" class="adjunto-edit-input" />
                <div class="adjunto-edit-btns">
                  <button type="button" class="btn-small" @click="guardarEdicionAdjuntoVer">Guardar</button>
                  <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionAdjuntoVer">Cancelar</button>
                </div>
              </template>
              <template v-else>
                <a v-if="a.url" :href="a.url" target="_blank" rel="noopener" class="adjunto-link">📎 {{ a.nombre_original }}</a>
                <span v-else>📎 {{ a.nombre_original }}</span>
                <div v-if="puedeModificarAdjunto(a)" class="adjunto-acciones">
                  <button type="button" class="btn-icon-mini" title="Editar nombre" @click="iniciarEdicionAdjuntoVer(a)"><IconEdit class="btn-icon-sm" /></button>
                  <button type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarAdjuntoVer(a)"><IconTrash class="btn-icon-sm" /></button>
                </div>
              </template>
            </div>
          </div>
          <div class="adjunto-upload">
            <input ref="archivoAdjuntoVer" type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.png,.jpg,.jpeg" @change="subirAdjuntoVer" />
            <span v-if="subiendoAdjuntoVer" class="adjunto-loading">Subiendo...</span>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal"><IconCancel class="btn-icon" /> Cerrar</button>
        </div>
      </div>
    </div>

    <!-- Modal Asignar tarea -->
    <div v-if="showAsignarModal" class="modal-overlay" @click.self="closeAsignarModal">
      <div class="modal modal-wide">
        <h2>Asignar tarea</h2>
        <p v-if="tareaAsignar" class="modal-subtitle">{{ tareaAsignar.titulo }}</p>
        <p class="modal-hint">Asigne la tarea a un Área, una Secretaría o ninguna estructura.</p>

        <div class="asignar-form">
          <label>Tipo de destino</label>
          <div class="radio-group">
            <label class="radio-label">
              <input v-model="tipoAsignar" type="radio" value="area" @change="areaAsignar = null; secretariaAsignar = null" />
              Área
            </label>
            <label class="radio-label">
              <input v-model="tipoAsignar" type="radio" value="secretaria" @change="areaAsignar = null; secretariaAsignar = null" />
              Secretaría
            </label>
            <label class="radio-label">
              <input v-model="tipoAsignar" type="radio" value="ninguna" @change="areaAsignar = null; secretariaAsignar = null" />
              Ninguna
            </label>
          </div>

          <template v-if="tipoAsignar === 'area'">
            <label>Área</label>
            <select v-model="areaAsignar">
              <option :value="null">Seleccionar área</option>
              <option v-for="a in areas" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
            </select>
          </template>
          <template v-else-if="tipoAsignar === 'secretaria'">
            <label>Secretaría</label>
            <select v-model="secretariaAsignar">
              <option :value="null">Seleccionar secretaría</option>
              <option v-for="s in secretarias" :key="(s.id as number)" :value="s.id">{{ s.codigo }} - {{ s.nombre }}</option>
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
.page h1 { margin-bottom: 0.5rem; }
.subtitle-rol { color: #64748b; font-size: 0.9rem; margin-bottom: 1rem; }
.filter-hint { color: #64748b; font-size: 0.9rem; margin-bottom: 0.8rem; }
.toolbar {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  align-items: center;
  flex-wrap: wrap;
}
.search-wrapper {
  position: relative;
  flex: 1;
  min-width: 220px;
  max-width: 320px;
}
.search-icon {
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1rem;
  opacity: 0.6;
}
.search-input {
  width: 100%;
  padding: 0.5rem 0.75rem 0.5rem 2.25rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  background: white;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.search-input:focus {
  outline: none;
  border-color: #1565c0;
  box-shadow: 0 0 0 3px rgba(21, 101, 192, 0.15);
}
.search-input::placeholder {
  color: #94a3b8;
}
.estado-selector {
  display: flex;
  gap: 0.35rem;
  flex-wrap: wrap;
}
.estado-pill {
  padding: 0.45rem 0.9rem;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  background: white;
  font-size: 0.875rem;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s ease;
}
.estado-pill:hover {
  border-color: #cbd5e1;
  color: #334155;
  background: #f8fafc;
}
.estado-pill.active {
  background: linear-gradient(135deg, #1565c0 0%, #1976d2 100%);
  border-color: #1565c0;
  color: white;
  box-shadow: 0 2px 4px rgba(21, 101, 192, 0.25);
}
.toolbar .btn-secondary,
.toolbar .btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  height: 38px;
  padding: 0 1rem;
  border-radius: 6px;
  font-size: 0.9rem;
  cursor: pointer;
  border: none;
  box-sizing: border-box;
}
.toolbar .btn-secondary {
  background: #16a34a;
  color: white;
}
.toolbar .btn-secondary:disabled { background: #94a3b8; cursor: not-allowed; }
.toolbar .btn-primary {
  background: #3b82f6;
  color: white;
}
.table { width: 100%; background: white; border-radius: 8px; overflow: hidden; }
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.actions-header,
.actions-cell { text-align: center !important; }
.actions-cell { white-space: nowrap; }
.table th { background: #f8fafc; }
.empty-row td {
  text-align: center;
  color: #64748b;
  padding: 2rem 1rem;
  font-style: italic;
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
  max-height: 90vh;
  overflow-y: auto;
}
.modal-wide { max-width: 500px; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.row-dates {
  display: flex;
  gap: 1rem;
  align-items: flex-start;
}
.col-dates {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.col-dates label {
  font-weight: 500;
  color: #374151;
  font-size: 0.9rem;
}
.col-prioridad {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.row { display: flex; gap: 1rem; }
.row > div { flex: 1; }
.radio-group { display: flex; gap: 1rem; margin: 0.25rem 0; }
.radio-label { display: flex; align-items: center; gap: 0.5rem; cursor: pointer; }
.modal-subtitle {
  font-size: 0.95rem;
  color: #64748b;
  margin: -0.25rem 0 0.5rem;
}
.mensaje-carga { font-size: 0.9rem; color: #64748b; margin: 0.5rem 0; }
.mensaje-sin-usuarios { color: #b91c1c; font-weight: 600; margin: 0.5rem 0 0.25rem; }
.mensaje-sin-usuarios-hint { font-size: 0.85rem; color: #64748b; margin: 0 0 0.5rem; }
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
.asignar-form label:first-of-type { margin-top: 0; }

/* Modal Ver detalle */
.modal-ver .detalle-content { max-height: 70vh; overflow-y: auto; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
.detalle-desc { white-space: pre-wrap; line-height: 1.5; }
.detalle-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
.detalle-section {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e2e8f0;
}
.detalle-section h3 { font-size: 0.95rem; margin: 0 0 0.5rem; color: #334155; }
.comentario-leyenda { font-size: 0.75rem; color: #94a3b8; margin: 0 0 0.5rem; }
.comentarios-lista { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 0.5rem; }
.comentario-item { padding: 0.5rem; background: #f8fafc; border-radius: 6px; }
.comentario-item-editable { display: flex; flex-direction: column; gap: 0.25rem; }
.comentario-header { display: flex; flex-wrap: wrap; align-items: center; gap: 0.35rem; }
.comentario-meta { font-size: 0.75rem; color: #64748b; }
.editado-leyenda { font-size: 0.7rem; color: #94a3b8; font-style: italic; }
.comentario-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.btn-icon-mini { padding: 0.2rem 0.4rem; background: #e2e8f0; border: none; border-radius: 4px; cursor: pointer; }
.btn-icon-mini:hover { background: #cbd5e1; }
.btn-danger-mini:hover { background: #fecaca !important; }
.edit-textarea { width: 100%; padding: 0.4rem; font-size: 0.85rem; margin-top: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.edit-acciones { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
.btn-cancel-mini { background: #94a3b8 !important; }
.comentario-texto { margin: 0.25rem 0 0; font-size: 0.9rem; }
.comentario-add { display: flex; flex-direction: column; gap: 0.5rem; margin-top: 0.5rem; }
.comentario-add textarea { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.btn-small { align-self: flex-start; padding: 0.35rem 0.75rem; background: #3b82f6; color: white; border: none; border-radius: 6px; font-size: 0.85rem; cursor: pointer; }
.btn-small:disabled { opacity: 0.6; cursor: not-allowed; }
.adjuntos-lista { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 0.5rem; }
.adjunto-item { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
.adjunto-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.adjunto-edit-input { flex: 1; min-width: 150px; padding: 0.35rem; font-size: 0.85rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.adjunto-edit-btns { display: flex; gap: 0.35rem; }
.adjunto-link { color: #2563eb; text-decoration: none; font-size: 0.9rem; }
.adjunto-link:hover { text-decoration: underline; }
.adjunto-upload input[type="file"] { font-size: 0.85rem; }
.adjunto-loading { font-size: 0.85rem; color: #64748b; margin-left: 0.5rem; }

/* Subtareas jerárquicas */
.row-subtarea { background-color: rgba(248, 250, 252, 0.8); }
.cell-indent { padding-left: 2rem !important; }
.subtarea-icon { color: #64748b; margin-right: 0.35rem; font-size: 0.9rem; }

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
</style>
