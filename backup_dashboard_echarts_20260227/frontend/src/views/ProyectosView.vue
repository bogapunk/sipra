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
type TipoDependencia = 'area' | 'secretaria'
const form = ref({
  nombre: '',
  descripcion: '',
  fecha_inicio: '',
  fecha_fin_estimada: '',
  estado: 'Activo',
  creado_por: 1,
  usuario_responsable: null as number | null,
  tipoDependencia: 'area' as TipoDependencia,
  area_id: null as number | null,
  secretaria: null as number | null,
  equipo: [] as number[],
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

const load = async () => {
  carga.value = true
  try {
    const secretariaId = route.query.secretaria as string | undefined
    const params = secretariaId ? { secretaria: secretariaId } : {}
    const [pRes, uRes, sRes, aRes] = await Promise.all([
      api.get('dashboard/proyectos/', { params }).catch(() => api.get('proyectos/', { params })),
      api.get('usuarios/selector/').catch(() => ({ data: [] })),
      api.get('secretarias/').catch(() => ({ data: [] })),
      api.get('areas/').catch(() => ({ data: [] })),
    ])
    proyectos.value = parseProyectos(pRes)
    usuarios.value = Array.isArray(uRes.data) ? uRes.data : []
    secretarias.value = Array.isArray(sRes.data) ? sRes.data : []
    areas.value = Array.isArray(aRes.data) ? aRes.data : []
  } catch {
    proyectos.value = []
    usuarios.value = []
    secretarias.value = []
    areas.value = []
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

const proyectosFiltrados = computed(() => {
  const ordenados = [...proyectos.value].sort((a, b) => Number(a.id || 0) - Number(b.id || 0))
  const q = buscarProyecto.value.trim().toLowerCase()
  if (!q) return ordenados
  return ordenados.filter((p: Record<string, unknown>) =>
    String(p.nombre || '').toLowerCase().includes(q)
  )
})

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

async function descargarExcel() {
  const lista = proyectosFiltrados.value
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
    creado_por: user.value?.id ?? 1,
    usuario_responsable: user.value?.id ?? null,
    tipoDependencia: tipoInicial,
    area_id: null,
    secretaria: tipoInicial === 'secretaria' ? secretariaId : null,
    equipo: [],
  }
  showForm.value = true
  loadUsuariosParaResponsable()
}

const openEdit = async (p: Record<string, unknown>) => {
  editingId.value = p.id as number
  const secId = p.secretaria != null ? (typeof p.secretaria === 'object' ? (p.secretaria as { id?: number }).id : p.secretaria as number) : null
  const areaDirect = p.area != null ? (typeof p.area === 'object' ? (p.area as { id?: number }).id : p.area as number) : null
  const areasProy = p.areas_asignadas as string[] | undefined
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
    nombre: (p.nombre as string) || '',
    descripcion: (p.descripcion as string) || '',
    fecha_inicio: (p.fecha_inicio as string) || '',
    fecha_fin_estimada: (p.fecha_fin_estimada as string) || '',
    estado: (p.estado as string) || 'Activo',
    creado_por: p.creado_por as number,
    usuario_responsable: (p.usuario_responsable != null ? (typeof p.usuario_responsable === 'object' ? (p.usuario_responsable as { id?: number }).id : p.usuario_responsable) : p.creado_por) as number | null,
    tipoDependencia: tipo,
    area_id: tipo === 'area' ? areaIdResolved : null,
    secretaria: tipo === 'secretaria' ? secId : null,
    equipo: equipoIds,
  }
  showForm.value = true
  loadUsuariosParaResponsable()
}

const save = async () => {
  const { tipoDependencia, area_id, equipo, usuario_responsable, ...rest } = form.value
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
  const payload = {
    ...rest,
    usuario_responsable: usuario_responsable,
    area: tipoDependencia === 'area' ? area_id : null,
    secretaria: tipoDependencia === 'secretaria' ? form.value.secretaria : null,
    equipo: equipo || [],
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
  } catch {
    toast.error('Error al guardar el proyecto. Verifique los datos.')
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

const openVer = (p: Record<string, unknown>) => {
  proyectoVer.value = p
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

onMounted(load)
watch(() => route.query.secretaria, () => load())
</script>

<template>
  <div class="page">
    <h1>Proyectos</h1>
    <p v-if="route.query.secretaria && (secretariaFiltroNombre || secretarias.length)" class="filter-hint">
      Mostrando proyectos de: <strong>{{ secretariaFiltroNombre || 'Secretaría' }}</strong>.
      <router-link :to="{ path: '/proyectos' }">Ver todos</router-link>
    </p>

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
            <td>{{ Number(p.porcentaje_avance) ?? 0 }}%</td>
            <td>{{ p.responsable_nombre || p.creado_por || '-' }}</td>
            <td>{{ p.estado || '-' }}</td>
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

    <EmptyState
      v-else
      :titulo="buscarProyecto.trim() ? 'Sin resultados' : 'No hay proyectos'"
      :mensaje="buscarProyecto.trim() ? 'No se encontraron proyectos que coincidan con la búsqueda. Intente con otros términos.' : 'Aún no hay proyectos cargados. Use el botón «Nuevo proyecto» para crear el primero.'"
      :icono="buscarProyecto.trim() ? 'busqueda' : 'proyectos'"
    />

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
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
.page h1 { margin-bottom: 1rem; }
.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
  margin-bottom: 1rem;
}
.search-input {
  flex: 1;
  min-width: 200px;
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
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
.table-wrapper { overflow-x: auto; }
.loading, .empty-msg { color: #64748b; margin-top: 0.5rem; }
.table {
  width: 100%;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.table th { background: #f8fafc; font-weight: 600; }
.table tbody tr:nth-child(even) { background: #f8fafc; }
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
.modal h2 { margin-bottom: 1rem; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
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
.dependencia-cell { min-width: 180px; }
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
