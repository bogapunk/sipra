<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { api } from '@/services/api'
import { useRouter, useRoute } from 'vue-router'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconPlus from '@/components/icons/IconPlus.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import IconSave from '@/components/icons/IconSave.vue'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { useAuth } from '@/composables/useAuth'
import { exportToCsv } from '@/utils/exportCsv'

const router = useRouter()
const route = useRoute()
const { isAdmin } = useAuth()
const { confirmDelete } = useConfirmDelete()
const toast = useToast()

const tabs = [
  { id: 'estructura', label: 'Estructura', icon: '📊' },
  { id: 'ejes', label: 'Ejes', icon: '📌' },
  { id: 'planes', label: 'Planes', icon: '📋' },
  { id: 'programas', label: 'Programas', icon: '📂' },
  { id: 'objetivos', label: 'Objetivos', icon: '🎯' },
  { id: 'indicadores', label: 'Indicadores', icon: '📈' },
]

const tabActual = ref('estructura')
watch(() => route.hash, (h) => {
  const id = h ? h.slice(1) : 'estructura'
  if (tabs.some(t => t.id === id)) tabActual.value = id
}, { immediate: true })

function setTab(id: string) {
  tabActual.value = id
  router.replace({ hash: id })
}

// Estructura
const arbol = ref<Record<string, unknown>[]>([])
const cargaArbol = ref(true)
const expandidos = ref<Set<string>>(new Set())

function toggle(key: string) {
  if (expandidos.value.has(key)) expandidos.value.delete(key)
  else expandidos.value.add(key)
  expandidos.value = new Set(expandidos.value)
}

function expandirTodos() {
  const keys = new Set<string>()
  function collect(ejes: Record<string, unknown>[]) {
    for (const e of ejes) {
      keys.add(`eje-${e.id}`)
      for (const p of (e.planes as Record<string, unknown>[]) || []) {
        keys.add(`plan-${p.id}`)
        for (const pr of (p.programas as Record<string, unknown>[]) || []) {
          keys.add(`prog-${pr.id}`)
          for (const o of (pr.objetivos as Record<string, unknown>[]) || []) {
            keys.add(`obj-${o.id}`)
          }
        }
      }
    }
  }
  collect(arbol.value)
  expandidos.value = keys
}

function colapsarTodos() { expandidos.value = new Set() }
function irAProyecto(id: number) { router.push(`/proyectos/${id}`) }

// ABM desde estructura (con padre pre-seleccionado)
function openCreateEjeDesdeEstructura() {
  const maxId = arbol.value.length ? Math.max(...arbol.value.map((e: Record<string, unknown>) => (e.id as number) || 0)) : 0
  editingEjeId.value = null
  formEje.value = { id_eje: maxId + 1, nombre_eje: '' }
  showFormEje.value = true
}

function openEditEjeDesdeEstructura(eje: Record<string, unknown>) {
  editingEjeId.value = eje.id as number
  formEje.value = { id_eje: eje.id as number, nombre_eje: (eje.nombre as string) || '' }
  showFormEje.value = true
}

async function openCreatePlanDesdeEstructura(ejeId: number) {
  await loadPlanes()
  const maxId = planes.value.length ? Math.max(...planes.value.map((p: Record<string, unknown>) => (p.id_plan as number) || 0)) : 0
  editingPlanId.value = null
  formPlan.value = {
    id_plan: maxId + 1, eje: ejeId, nombre_plan: '',
    proposito_politica_publica: '', vision_estrategica: '',
  }
  showFormPlan.value = true
}

async function openEditPlanDesdeEstructura(plan: Record<string, unknown>) {
  const full = (await api.get(`planes/${plan.id}/`)).data
  openEditPlan(full)
}

async function openCreateProgDesdeEstructura(planId: number) {
  await loadProgramas()
  editingProgId.value = null
  formProg.value = { id_programa: '', plan: planId, nombre_programa: '' }
  showFormProg.value = true
}

async function openEditProgDesdeEstructura(prog: Record<string, unknown>) {
  const full = (await api.get(`programas/${prog.id}/`)).data
  openEditProg(full)
}

async function openCreateObjDesdeEstructura(programaId: string) {
  await loadObjetivos()
  editingObjId.value = null
  formObj.value = { programa: programaId, descripcion: '' }
  showFormObj.value = true
}

async function openEditObjDesdeEstructura(obj: Record<string, unknown>) {
  const full = (await api.get(`objetivos-estrategicos/${obj.id}/`)).data
  openEditObj(full)
}

const loadArbol = async () => {
  cargaArbol.value = true
  try {
    arbol.value = (await api.get('planificacion/arbol/')).data
    expandirTodos()
  } catch { arbol.value = [] }
  finally { cargaArbol.value = false }
}

// Ejes ABM
const ejes = ref<Record<string, unknown>[]>([])
const buscarEje = ref('')
const showFormEje = ref(false)
const editingEjeId = ref<number | null>(null)
const formEje = ref({ id_eje: 0, nombre_eje: '' })

const ejesFiltrados = computed(() => {
  const q = buscarEje.value.trim().toLowerCase()
  if (!q) return ejes.value
  return ejes.value.filter((e: Record<string, unknown>) =>
    String(e.nombre_eje || '').toLowerCase().includes(q))
})

const loadEjes = async () => {
  ejes.value = (await api.get('ejes/')).data
}

// Planes ABM
const planes = ref<Record<string, unknown>[]>([])
const buscarPlan = ref('')
const filtroEje = ref<number | ''>('')
const showFormPlan = ref(false)
const editingPlanId = ref<number | null>(null)
const formPlan = ref({
  id_plan: 0, eje: null as number | null, nombre_plan: '',
  proposito_politica_publica: '', vision_estrategica: '',
})

const planesFiltrados = computed(() => {
  let lista = planes.value
  if (filtroEje.value !== '') lista = lista.filter((p: Record<string, unknown>) => p.eje === Number(filtroEje.value))
  const q = buscarPlan.value.trim().toLowerCase()
  if (q) lista = lista.filter((p: Record<string, unknown>) => String(p.nombre_plan || '').toLowerCase().includes(q))
  return lista
})

const loadPlanes = async () => {
  const [pRes, eRes] = await Promise.all([api.get('planes/'), api.get('ejes/')])
  planes.value = Array.isArray(pRes.data) ? pRes.data : (pRes.data?.results || [])
  ejes.value = Array.isArray(eRes.data) ? eRes.data : (eRes.data?.results || [])
}

// Programas ABM
const programas = ref<Record<string, unknown>[]>([])
const buscarProg = ref('')
const filtroPlan = ref<number | ''>('')
const showFormProg = ref(false)
const editingProgId = ref<string | null>(null)
const formProg = ref({ id_programa: '', plan: null as number | null, nombre_programa: '' })

const programasFiltrados = computed(() => {
  let lista = programas.value
  if (filtroPlan.value !== '') lista = lista.filter((p: Record<string, unknown>) => p.plan === Number(filtroPlan.value))
  const q = buscarProg.value.trim().toLowerCase()
  if (q) lista = lista.filter((p: Record<string, unknown>) => String(p.nombre_programa || p.id_programa || '').toLowerCase().includes(q))
  return lista
})

const loadProgramas = async () => {
  const [prRes, plRes] = await Promise.all([api.get('programas/'), api.get('planes/')])
  programas.value = Array.isArray(prRes.data) ? prRes.data : (prRes.data?.results || [])
  planes.value = Array.isArray(plRes.data) ? plRes.data : (plRes.data?.results || [])
}

// Objetivos ABM
const objetivos = ref<Record<string, unknown>[]>([])
const buscarObj = ref('')
const filtroProg = ref<string | ''>('')
const showFormObj = ref(false)
const editingObjId = ref<number | null>(null)
const formObj = ref({ programa: null as string | null, descripcion: '' })

const objetivosFiltrados = computed(() => {
  let lista = objetivos.value
  if (filtroProg.value !== '') lista = lista.filter((o: Record<string, unknown>) => String(o.programa) === String(filtroProg.value))
  const q = buscarObj.value.trim().toLowerCase()
  if (q) lista = lista.filter((o: Record<string, unknown>) => String(o.descripcion || '').toLowerCase().includes(q))
  return lista
})

const loadObjetivos = async () => {
  const [oRes, pRes] = await Promise.all([api.get('objetivos-estrategicos/'), api.get('programas/')])
  objetivos.value = Array.isArray(oRes.data) ? oRes.data : (oRes.data?.results || [])
  programas.value = Array.isArray(pRes.data) ? pRes.data : (pRes.data?.results || [])
}

// Indicadores ABM
const indicadores = ref<Record<string, unknown>[]>([])
const buscarInd = ref('')
const filtroProy = ref<number | ''>('')
const showFormInd = ref(false)
const editingIndId = ref<number | null>(null)
const formInd = ref({ proyecto: null as number | null, descripcion: '', unidad_medida: '', frecuencia: '' })
const proyectos = ref<Record<string, unknown>[]>([])

const indicadoresFiltrados = computed(() => {
  let lista = indicadores.value
  if (filtroProy.value !== '') lista = lista.filter((i: Record<string, unknown>) => i.proyecto === Number(filtroProy.value))
  const q = buscarInd.value.trim().toLowerCase()
  if (q) lista = lista.filter((i: Record<string, unknown>) => String(i.descripcion || i.proyecto_nombre || '').toLowerCase().includes(q))
  return lista
})

const loadIndicadores = async () => {
  try {
    const [iRes, pRes] = await Promise.all([api.get('indicadores/'), api.get('proyectos/')])
    indicadores.value = Array.isArray(iRes.data) ? iRes.data : (iRes.data?.results || [])
    proyectos.value = Array.isArray(pRes.data) ? pRes.data : (pRes.data?.results || [])
  } catch {
    try {
      indicadores.value = (await api.get('indicadores/')).data
      proyectos.value = (await api.get('dashboard/proyectos/')).data || []
    } catch {
      indicadores.value = []
      proyectos.value = []
    }
  }
}

const loadAll = () => {
  loadArbol()
  if (tabActual.value === 'ejes') loadEjes()
  else if (tabActual.value === 'planes') loadPlanes()
  else if (tabActual.value === 'programas') loadProgramas()
  else if (tabActual.value === 'objetivos') loadObjetivos()
  else if (tabActual.value === 'indicadores') loadIndicadores()
}

watch(tabActual, (t) => {
  if (t === 'ejes') loadEjes()
  else if (t === 'planes') loadPlanes()
  else if (t === 'programas') loadProgramas()
  else if (t === 'objetivos') loadObjetivos()
  else if (t === 'indicadores') loadIndicadores()
})

onMounted(() => {
  loadArbol()
  if (tabActual.value === 'ejes') loadEjes()
  else if (tabActual.value === 'planes') loadPlanes()
  else if (tabActual.value === 'programas') loadProgramas()
  else if (tabActual.value === 'objetivos') loadObjetivos()
  else if (tabActual.value === 'indicadores') loadIndicadores()
})

// Ejes
function openCreateEje() {
  editingEjeId.value = null
  const maxId = ejes.value.length ? Math.max(...ejes.value.map((e: Record<string, unknown>) => (e.id_eje as number) || 0)) : 0
  formEje.value = { id_eje: maxId + 1, nombre_eje: '' }
  showFormEje.value = true
}

function openEditEje(e: Record<string, unknown>) {
  editingEjeId.value = e.id_eje as number
  formEje.value = { id_eje: e.id_eje as number, nombre_eje: (e.nombre_eje as string) || '' }
  showFormEje.value = true
}

async function saveEje() {
  try {
    if (editingEjeId.value !== null) {
      await api.patch(`ejes/${editingEjeId.value}/`, formEje.value)
      toast.success('Eje actualizado.')
    } else {
      await api.post('ejes/', formEje.value)
      toast.success('Eje creado.')
    }
    showFormEje.value = false
    loadEjes()
    loadArbol()
  } catch { toast.error('Error al guardar.') }
}

async function removeEje(id: number) {
  if (await confirmDelete()) {
    try {
      await api.delete(`ejes/${id}/`)
      toast.success('Eliminado.')
      loadEjes()
      loadArbol()
    } catch { toast.error('Error al eliminar.') }
  }
}

// Planes
function openCreatePlan() {
  editingPlanId.value = null
  const maxId = planes.value.length ? Math.max(...planes.value.map((p: Record<string, unknown>) => (p.id_plan as number) || 0)) : 0
  formPlan.value = {
    id_plan: maxId + 1,
    eje: ejes.value[0] ? (ejes.value[0] as Record<string, unknown>).id_eje as number : null,
    nombre_plan: '', proposito_politica_publica: '', vision_estrategica: '',
  }
  showFormPlan.value = true
}

function openEditPlan(p: Record<string, unknown>) {
  editingPlanId.value = p.id_plan as number
  formPlan.value = {
    id_plan: p.id_plan as number, eje: p.eje as number,
    nombre_plan: (p.nombre_plan as string) || '',
    proposito_politica_publica: (p.proposito_politica_publica as string) || '',
    vision_estrategica: (p.vision_estrategica as string) || '',
  }
  showFormPlan.value = true
}

async function savePlan() {
  try {
    if (editingPlanId.value !== null) {
      await api.patch(`planes/${editingPlanId.value}/`, formPlan.value)
      toast.success('Plan actualizado.')
    } else {
      await api.post('planes/', formPlan.value)
      toast.success('Plan creado.')
    }
    showFormPlan.value = false
    loadPlanes()
    loadArbol()
  } catch { toast.error('Error al guardar.') }
}

async function removePlan(id: number) {
  if (await confirmDelete()) {
    try {
      await api.delete(`planes/${id}/`)
      toast.success('Eliminado.')
      loadPlanes()
      loadArbol()
    } catch { toast.error('Error al eliminar.') }
  }
}

// Programas
function openCreateProg() {
  editingProgId.value = null
  formProg.value = {
    id_programa: '',
    plan: planes.value[0] ? (planes.value[0] as Record<string, unknown>).id_plan as number : null,
    nombre_programa: '',
  }
  showFormProg.value = true
}

function openEditProg(p: Record<string, unknown>) {
  editingProgId.value = p.id_programa as string
  formProg.value = {
    id_programa: p.id_programa as string,
    plan: p.plan as number,
    nombre_programa: (p.nombre_programa as string) || '',
  }
  showFormProg.value = true
}

async function saveProg() {
  try {
  const payload = { plan: formProg.value.plan, nombre_programa: formProg.value.nombre_programa }
  if (editingProgId.value !== null) {
    await api.patch(`programas/${editingProgId.value}/`, payload)
    toast.success('Programa actualizado.')
  } else {
    await api.post('programas/', { ...payload, id_programa: formProg.value.id_programa })
    toast.success('Programa creado.')
  }
  showFormProg.value = false
  loadProgramas()
  loadArbol()
  } catch { toast.error('Error al guardar.') }
}

async function removeProg(id: string) {
  if (await confirmDelete()) {
    try {
      await api.delete(`programas/${id}/`)
      toast.success('Eliminado.')
      loadProgramas()
      loadArbol()
    } catch { toast.error('Error al eliminar.') }
  }
}

// Objetivos
function openCreateObj() {
  editingObjId.value = null
  formObj.value = {
    programa: programas.value[0] ? (programas.value[0] as Record<string, unknown>).id_programa as string : null,
    descripcion: '',
  }
  showFormObj.value = true
}

function openEditObj(o: Record<string, unknown>) {
  editingObjId.value = o.id as number
  formObj.value = {
    programa: o.programa as string,
    descripcion: (o.descripcion as string) || '',
  }
  showFormObj.value = true
}

async function saveObj() {
  try {
    if (editingObjId.value !== null) {
      await api.patch(`objetivos-estrategicos/${editingObjId.value}/`, formObj.value)
      toast.success('Objetivo actualizado.')
    } else {
      await api.post('objetivos-estrategicos/', formObj.value)
      toast.success('Objetivo creado.')
    }
    showFormObj.value = false
    loadObjetivos()
    loadArbol()
  } catch { toast.error('Error al guardar.') }
}

async function removeObj(id: number) {
  if (await confirmDelete()) {
    try {
      await api.delete(`objetivos-estrategicos/${id}/`)
      toast.success('Eliminado.')
      loadObjetivos()
      loadArbol()
    } catch { toast.error('Error al eliminar.') }
  }
}

// Indicadores
function openCreateInd() {
  editingIndId.value = null
  formInd.value = {
    proyecto: proyectos.value[0] ? (proyectos.value[0] as Record<string, unknown>).id as number : null,
    descripcion: '', unidad_medida: '', frecuencia: '',
  }
  showFormInd.value = true
}

function openEditInd(i: Record<string, unknown>) {
  editingIndId.value = i.id as number
  formInd.value = {
    proyecto: i.proyecto as number,
    descripcion: (i.descripcion as string) || '',
    unidad_medida: (i.unidad_medida as string) || '',
    frecuencia: (i.frecuencia as string) || '',
  }
  showFormInd.value = true
}

async function saveInd() {
  try {
    if (editingIndId.value !== null) {
      await api.patch(`indicadores/${editingIndId.value}/`, formInd.value)
      toast.success('Indicador actualizado.')
    } else {
      await api.post('indicadores/', formInd.value)
      toast.success('Indicador creado.')
    }
    showFormInd.value = false
    loadIndicadores()
    loadArbol()
  } catch { toast.error('Error al guardar.') }
}

async function removeInd(id: number) {
  if (await confirmDelete()) {
    try {
      await api.delete(`indicadores/${id}/`)
      toast.success('Eliminado.')
      loadIndicadores()
      loadArbol()
    } catch { toast.error('Error al eliminar.') }
  }
}

// Export
async function exportEjes() {
  const headers = ['ID', 'Nombre']
  const rows = ejesFiltrados.value.map((e: Record<string, unknown>) => [String(e.id_eje ?? ''), String(e.nombre_eje || '')])
  await exportToCsv(headers, rows, `ejes_${new Date().toISOString().slice(0, 10)}.csv`)
}

async function exportPlanes() {
  const headers = ['ID', 'Eje', 'Nombre']
  const rows = planesFiltrados.value.map((p: Record<string, unknown>) => [
    String(p.id_plan ?? ''), String(p.eje_nombre || ''), String((p.nombre_plan || '').toString().slice(0, 80)),
  ])
  await exportToCsv(headers, rows, `planes_${new Date().toISOString().slice(0, 10)}.csv`)
}

async function exportProgramas() {
  const headers = ['Código', 'Plan', 'Nombre']
  const rows = programasFiltrados.value.map((p: Record<string, unknown>) => [
    String(p.id_programa ?? ''), String(p.plan_nombre || ''), String(p.nombre_programa || ''),
  ])
  await exportToCsv(headers, rows, `programas_${new Date().toISOString().slice(0, 10)}.csv`)
}

async function exportObjetivos() {
  const headers = ['Programa', 'Descripción']
  const rows = objetivosFiltrados.value.map((o: Record<string, unknown>) => [
    String(o.programa_nombre || ''), String((o.descripcion || '').toString().slice(0, 120)),
  ])
  await exportToCsv(headers, rows, `objetivos_${new Date().toISOString().slice(0, 10)}.csv`)
}

async function exportIndicadores() {
  const headers = ['Proyecto', 'Descripción', 'Unidad', 'Frecuencia']
  const rows = indicadoresFiltrados.value.map((i: Record<string, unknown>) => [
    String(i.proyecto_nombre || ''), String((i.descripcion || '').toString().slice(0, 80)),
    String(i.unidad_medida || ''), String(i.frecuencia || ''),
  ])
  await exportToCsv(headers, rows, `indicadores_${new Date().toISOString().slice(0, 10)}.csv`)
}
</script>

<template>
  <div class="page planificacion-panel">
    <header class="page-header">
      <h1>Planificación</h1>
      <p class="subtitle">Estructura: Eje → Plan → Programa → Objetivo → Proyecto → Indicador</p>
      <div class="tabs">
        <button
          v-for="t in tabs"
          :key="t.id"
          type="button"
          class="tab"
          :class="{ active: tabActual === t.id }"
          @click="setTab(t.id)"
        >
          <span class="tab-icon">{{ t.icon }}</span>
          {{ t.label }}
        </button>
      </div>
    </header>

    <!-- Estructura -->
    <div v-show="tabActual === 'estructura'" class="tab-content">
      <div class="toolbar">
        <button type="button" class="btn-outline" @click="expandirTodos">Expandir todo</button>
        <button type="button" class="btn-outline" @click="colapsarTodos">Colapsar todo</button>
        <button type="button" class="btn-primary" @click="loadArbol" :disabled="cargaArbol">
          {{ cargaArbol ? 'Cargando...' : 'Actualizar' }}
        </button>
        <button v-if="isAdmin" type="button" class="btn-primary" @click="openCreateEjeDesdeEstructura">
          <IconPlus class="btn-icon" /> Nuevo eje
        </button>
      </div>
      <div v-if="cargaArbol" class="cargando">Cargando estructura...</div>
      <div v-else-if="!arbol.length" class="empty-state">
        <p>No hay datos. Haga clic en "Nuevo eje" para comenzar.</p>
      </div>
      <div v-else class="arbol-container">
        <div v-for="eje in arbol" :key="'eje-' + eje.id" class="nivel">
          <div class="nodo eje" :class="{ expandido: expandidos.has('eje-' + eje.id) }" @click="toggle('eje-' + eje.id)">
            <span class="icono">{{ expandidos.has('eje-' + eje.id) ? '▼' : '▶' }}</span>
            <span class="label">Eje {{ eje.id }}:</span>
            <span class="valor">{{ eje.nombre }}</span>
            <div v-if="isAdmin" class="nodo-acciones" @click.stop>
              <button type="button" class="btn-nodo" @click="openCreatePlanDesdeEstructura(eje.id as number)" title="Agregar plan">+ Plan</button>
              <button type="button" class="btn-nodo" @click="openEditEjeDesdeEstructura(eje)" title="Editar"><IconEdit class="btn-icon-sm" /></button>
              <button type="button" class="btn-nodo btn-nodo-danger" @click="removeEje(eje.id as number)" title="Eliminar"><IconTrash class="btn-icon-sm" /></button>
            </div>
          </div>
          <div v-if="expandidos.has('eje-' + eje.id)" class="hijos">
            <div v-for="plan in (eje.planes || [])" :key="'plan-' + plan.id" class="nivel">
              <div class="nodo plan" :class="{ expandido: expandidos.has('plan-' + plan.id) }" @click="toggle('plan-' + plan.id)">
                <span class="icono">{{ expandidos.has('plan-' + plan.id) ? '▼' : '▶' }}</span>
                <span class="label">Plan {{ plan.id }}:</span>
                <span class="valor">{{ plan.nombre }}</span>
                <div v-if="isAdmin" class="nodo-acciones" @click.stop>
                  <button type="button" class="btn-nodo" @click="openCreateProgDesdeEstructura(plan.id as number)" title="Agregar programa">+ Programa</button>
                  <button type="button" class="btn-nodo" @click="openEditPlanDesdeEstructura(plan)" title="Editar"><IconEdit class="btn-icon-sm" /></button>
                  <button type="button" class="btn-nodo btn-nodo-danger" @click="removePlan(plan.id as number)" title="Eliminar"><IconTrash class="btn-icon-sm" /></button>
                </div>
              </div>
              <div v-if="expandidos.has('plan-' + plan.id)" class="hijos">
                <div v-for="prog in (plan.programas || [])" :key="'prog-' + prog.id" class="nivel">
                  <div class="nodo programa" :class="{ expandido: expandidos.has('prog-' + prog.id) }" @click="toggle('prog-' + prog.id)">
                    <span class="icono">{{ expandidos.has('prog-' + prog.id) ? '▼' : '▶' }}</span>
                    <span class="label">Programa {{ prog.id }}:</span>
                    <span class="valor">{{ prog.nombre }}</span>
                    <div v-if="isAdmin" class="nodo-acciones" @click.stop>
                      <button type="button" class="btn-nodo" @click="openCreateObjDesdeEstructura(prog.id as string)" title="Agregar objetivo">+ Objetivo</button>
                      <button type="button" class="btn-nodo" @click="openEditProgDesdeEstructura(prog)" title="Editar"><IconEdit class="btn-icon-sm" /></button>
                      <button type="button" class="btn-nodo btn-nodo-danger" @click="removeProg(prog.id as string)" title="Eliminar"><IconTrash class="btn-icon-sm" /></button>
                    </div>
                  </div>
                  <div v-if="expandidos.has('prog-' + prog.id)" class="hijos">
                    <div v-for="obj in (prog.objetivos || [])" :key="'obj-' + obj.id" class="nivel">
                      <div class="nodo objetivo" :class="{ expandido: expandidos.has('obj-' + obj.id) }" @click="toggle('obj-' + obj.id)">
                        <span class="icono">{{ expandidos.has('obj-' + obj.id) ? '▼' : '▶' }}</span>
                        <span class="label">Objetivo:</span>
                        <span class="valor">{{ obj.descripcion }}</span>
                        <div v-if="isAdmin" class="nodo-acciones" @click.stop>
                          <button type="button" class="btn-nodo" @click="openEditObjDesdeEstructura(obj)" title="Editar"><IconEdit class="btn-icon-sm" /></button>
                          <button type="button" class="btn-nodo btn-nodo-danger" @click="removeObj(obj.id as number)" title="Eliminar"><IconTrash class="btn-icon-sm" /></button>
                        </div>
                      </div>
                      <div v-if="expandidos.has('obj-' + obj.id)" class="hijos">
                        <div v-for="proy in (obj.proyectos || [])" :key="'proy-' + proy.id" class="nivel">
                          <div class="nodo proyecto clickable" @click="irAProyecto(proy.id)">
                            <span class="icono">●</span>
                            <span class="valor">{{ proy.nombre }}</span>
                            <span class="badge">{{ proy.porcentaje_avance }}%</span>
                            <span class="estado">{{ proy.estado }}</span>
                          </div>
                          <div v-if="(proy.indicadores || []).length" class="hijos indicadores">
                            <div v-for="ind in proy.indicadores" :key="'ind-' + ind.id" class="nodo indicador">
                              <span class="icono">◇</span>
                              <span class="valor">{{ ind.descripcion }}</span>
                              <span class="meta">{{ ind.unidad_medida }} · {{ ind.frecuencia }}</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Modales ABM para uso desde Estructura -->
      <div v-if="showFormEje" class="modal-overlay" @click.self="showFormEje = false">
        <div class="modal">
          <h2>{{ editingEjeId !== null ? 'Editar' : 'Nuevo' }} eje</h2>
          <form @submit.prevent="saveEje">
            <label>ID</label>
            <input v-model.number="formEje.id_eje" type="number" min="1" required :disabled="editingEjeId !== null" />
            <label>Nombre</label>
            <input v-model="formEje.nombre_eje" required />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormEje = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
      <div v-if="showFormPlan" class="modal-overlay" @click.self="showFormPlan = false">
        <div class="modal modal-wide">
          <h2>{{ editingPlanId !== null ? 'Editar' : 'Nuevo' }} plan</h2>
          <form @submit.prevent="savePlan">
            <label>ID Plan</label>
            <input v-model.number="formPlan.id_plan" type="number" min="1" required :disabled="editingPlanId !== null" />
            <label>Eje</label>
            <select v-model="formPlan.eje" required>
              <option :value="null">Seleccionar</option>
              <option v-for="e in ejes" :key="(e.id_eje as number)" :value="e.id_eje">{{ e.nombre_eje }}</option>
            </select>
            <label>Nombre</label>
            <input v-model="formPlan.nombre_plan" required />
            <label>Propósito</label>
            <textarea v-model="formPlan.proposito_politica_publica" rows="2" />
            <label>Visión estratégica</label>
            <textarea v-model="formPlan.vision_estrategica" rows="2" />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormPlan = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
      <div v-if="showFormProg" class="modal-overlay" @click.self="showFormProg = false">
        <div class="modal">
          <h2>{{ editingProgId !== null ? 'Editar' : 'Nuevo' }} programa</h2>
          <form @submit.prevent="saveProg">
            <label>Código</label>
            <input v-model="formProg.id_programa" placeholder="1.1" required :disabled="editingProgId !== null" />
            <label>Plan</label>
            <select v-model="formProg.plan" required>
              <option :value="null">Seleccionar</option>
              <option v-for="pl in planes" :key="(pl.id_plan as number)" :value="pl.id_plan">{{ pl.nombre_plan }}</option>
            </select>
            <label>Nombre</label>
            <input v-model="formProg.nombre_programa" required />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormProg = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
      <div v-if="showFormObj" class="modal-overlay" @click.self="showFormObj = false">
        <div class="modal modal-wide">
          <h2>{{ editingObjId !== null ? 'Editar' : 'Nuevo' }} objetivo</h2>
          <form @submit.prevent="saveObj">
            <label>Programa</label>
            <select v-model="formObj.programa" required>
              <option :value="null">Seleccionar</option>
              <option v-for="p in programas" :key="(p.id_programa as string)" :value="p.id_programa">{{ p.id_programa }} - {{ p.nombre_programa }}</option>
            </select>
            <label>Descripción</label>
            <textarea v-model="formObj.descripcion" rows="4" required />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormObj = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Ejes ABM -->
    <div v-show="tabActual === 'ejes'" class="tab-content">
      <div class="toolbar">
        <input v-model="buscarEje" type="search" placeholder="Buscar..." class="search-input" />
        <button type="button" class="btn-secondary" @click="exportEjes" :disabled="!ejesFiltrados.length">
          <IconDownload class="btn-icon" /> Excel
        </button>
        <button v-if="isAdmin" class="btn-primary" @click="openCreateEje"><IconPlus class="btn-icon" /> Nuevo eje</button>
      </div>
      <div class="table-wrapper">
        <table class="table">
          <thead><tr><th>ID</th><th>Nombre</th><th v-if="isAdmin" class="actions-header">Acciones</th></tr></thead>
          <tbody>
            <tr v-for="e in ejesFiltrados" :key="(e.id_eje as number)">
              <td>{{ e.id_eje }}</td>
              <td>{{ e.nombre_eje }}</td>
              <td v-if="isAdmin" class="actions-cell">
                <button type="button" class="btn-action btn-action-editar" @click="openEditEje(e)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button class="btn-action-danger" @click="removeEje(e.id_eje as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="showFormEje" class="modal-overlay" @click.self="showFormEje = false">
        <div class="modal">
          <h2>{{ editingEjeId !== null ? 'Editar' : 'Nuevo' }} eje</h2>
          <form @submit.prevent="saveEje">
            <label>ID</label>
            <input v-model.number="formEje.id_eje" type="number" min="1" required :disabled="editingEjeId !== null" />
            <label>Nombre</label>
            <input v-model="formEje.nombre_eje" required />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormEje = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Planes ABM -->
    <div v-show="tabActual === 'planes'" class="tab-content">
      <div class="toolbar">
        <input v-model="buscarPlan" type="search" placeholder="Buscar..." class="search-input" />
        <select v-model="filtroEje" class="select-filter">
          <option value="">Todos los ejes</option>
          <option v-for="e in ejes" :key="(e.id_eje as number)" :value="e.id_eje">{{ e.nombre_eje }}</option>
        </select>
        <button type="button" class="btn-secondary" @click="exportPlanes" :disabled="!planesFiltrados.length"><IconDownload class="btn-icon" /> Excel</button>
        <button v-if="isAdmin" class="btn-primary" @click="openCreatePlan"><IconPlus class="btn-icon" /> Nuevo plan</button>
      </div>
      <div class="table-wrapper">
        <table class="table">
          <thead><tr><th>ID</th><th>Eje</th><th>Nombre</th><th v-if="isAdmin" class="actions-header">Acciones</th></tr></thead>
          <tbody>
            <tr v-for="p in planesFiltrados" :key="(p.id_plan as number)">
              <td>{{ p.id_plan }}</td>
              <td>{{ p.eje_nombre }}</td>
              <td>{{ p.nombre_plan }}</td>
              <td v-if="isAdmin" class="actions-cell">
                <button type="button" class="btn-action btn-action-editar" @click="openEditPlan(p)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button class="btn-action-danger" @click="removePlan(p.id_plan as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="showFormPlan" class="modal-overlay" @click.self="showFormPlan = false">
        <div class="modal modal-wide">
          <h2>{{ editingPlanId !== null ? 'Editar' : 'Nuevo' }} plan</h2>
          <form @submit.prevent="savePlan">
            <label>ID Plan</label>
            <input v-model.number="formPlan.id_plan" type="number" min="1" required :disabled="editingPlanId !== null" />
            <label>Eje</label>
            <select v-model="formPlan.eje" required>
              <option :value="null">Seleccionar</option>
              <option v-for="e in ejes" :key="(e.id_eje as number)" :value="e.id_eje">{{ e.nombre_eje }}</option>
            </select>
            <label>Nombre</label>
            <input v-model="formPlan.nombre_plan" required />
            <label>Propósito</label>
            <textarea v-model="formPlan.proposito_politica_publica" rows="2" />
            <label>Visión estratégica</label>
            <textarea v-model="formPlan.vision_estrategica" rows="2" />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormPlan = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Programas ABM -->
    <div v-show="tabActual === 'programas'" class="tab-content">
      <div class="toolbar">
        <input v-model="buscarProg" type="search" placeholder="Buscar..." class="search-input" />
        <select v-model="filtroPlan" class="select-filter">
          <option value="">Todos los planes</option>
          <option v-for="pl in planes" :key="(pl.id_plan as number)" :value="pl.id_plan">{{ pl.nombre_plan }}</option>
        </select>
        <button type="button" class="btn-secondary" @click="exportProgramas" :disabled="!programasFiltrados.length"><IconDownload class="btn-icon" /> Excel</button>
        <button v-if="isAdmin" class="btn-primary" @click="openCreateProg"><IconPlus class="btn-icon" /> Nuevo programa</button>
      </div>
      <div class="table-wrapper">
        <table class="table">
          <thead><tr><th>Código</th><th>Plan</th><th>Nombre</th><th v-if="isAdmin" class="actions-header">Acciones</th></tr></thead>
          <tbody>
            <tr v-for="p in programasFiltrados" :key="(p.id_programa as string)">
              <td>{{ p.id_programa }}</td>
              <td>{{ p.plan_nombre }}</td>
              <td>{{ p.nombre_programa }}</td>
              <td v-if="isAdmin" class="actions-cell">
                <button type="button" class="btn-action btn-action-editar" @click="openEditProg(p)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button type="button" class="btn-action-danger" @click="removeProg(p.id_programa as string)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="showFormProg" class="modal-overlay" @click.self="showFormProg = false">
        <div class="modal">
          <h2>{{ editingProgId !== null ? 'Editar' : 'Nuevo' }} programa</h2>
          <form @submit.prevent="saveProg">
            <label>Código</label>
            <input v-model="formProg.id_programa" placeholder="1.1" required :disabled="editingProgId !== null" />
            <label>Plan</label>
            <select v-model="formProg.plan" required>
              <option :value="null">Seleccionar</option>
              <option v-for="pl in planes" :key="(pl.id_plan as number)" :value="pl.id_plan">{{ pl.nombre_plan }}</option>
            </select>
            <label>Nombre</label>
            <input v-model="formProg.nombre_programa" required />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormProg = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Objetivos ABM -->
    <div v-show="tabActual === 'objetivos'" class="tab-content">
      <div class="toolbar">
        <input v-model="buscarObj" type="search" placeholder="Buscar..." class="search-input" />
        <select v-model="filtroProg" class="select-filter">
          <option value="">Todos los programas</option>
          <option v-for="p in programas" :key="(p.id_programa as string)" :value="p.id_programa">{{ p.id_programa }} - {{ p.nombre_programa }}</option>
        </select>
        <button type="button" class="btn-secondary" @click="exportObjetivos" :disabled="!objetivosFiltrados.length"><IconDownload class="btn-icon" /> Excel</button>
        <button v-if="isAdmin" class="btn-primary" @click="openCreateObj"><IconPlus class="btn-icon" /> Nuevo objetivo</button>
      </div>
      <div class="table-wrapper">
        <table class="table">
          <thead><tr><th>Programa</th><th>Descripción</th><th v-if="isAdmin" class="actions-header">Acciones</th></tr></thead>
          <tbody>
            <tr v-for="o in objetivosFiltrados" :key="(o.id as number)">
              <td>{{ o.programa_nombre }}</td>
              <td class="desc-cell">{{ o.descripcion }}</td>
              <td v-if="isAdmin" class="actions-cell">
                <button type="button" class="btn-action btn-action-editar" @click="openEditObj(o)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button class="btn-action-danger" @click="removeObj(o.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="showFormObj" class="modal-overlay" @click.self="showFormObj = false">
        <div class="modal modal-wide">
          <h2>{{ editingObjId !== null ? 'Editar' : 'Nuevo' }} objetivo</h2>
          <form @submit.prevent="saveObj">
            <label>Programa</label>
            <select v-model="formObj.programa" required>
              <option :value="null">Seleccionar</option>
              <option v-for="p in programas" :key="(p.id_programa as string)" :value="p.id_programa">{{ p.id_programa }} - {{ p.nombre_programa }}</option>
            </select>
            <label>Descripción</label>
            <textarea v-model="formObj.descripcion" rows="4" required />
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormObj = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- Indicadores ABM -->
    <div v-show="tabActual === 'indicadores'" class="tab-content">
      <div class="toolbar">
        <input v-model="buscarInd" type="search" placeholder="Buscar..." class="search-input" />
        <select v-model="filtroProy" class="select-filter">
          <option value="">Todos los proyectos</option>
          <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
        </select>
        <button type="button" class="btn-secondary" @click="exportIndicadores" :disabled="!indicadoresFiltrados.length"><IconDownload class="btn-icon" /> Excel</button>
        <button v-if="isAdmin" class="btn-primary" @click="openCreateInd"><IconPlus class="btn-icon" /> Nuevo indicador</button>
      </div>
      <div class="table-wrapper">
        <table class="table">
          <thead><tr><th>Proyecto</th><th>Descripción</th><th>Unidad</th><th>Frecuencia</th><th v-if="isAdmin" class="actions-header">Acciones</th></tr></thead>
          <tbody>
            <tr v-for="i in indicadoresFiltrados" :key="(i.id as number)">
              <td>{{ i.proyecto_nombre }}</td>
              <td class="desc-cell">{{ i.descripcion }}</td>
              <td>{{ i.unidad_medida || '-' }}</td>
              <td>{{ i.frecuencia || '-' }}</td>
              <td v-if="isAdmin" class="actions-cell">
                <button type="button" class="btn-action btn-action-editar" @click="openEditInd(i)"><IconEdit class="btn-icon-sm" /> Editar</button>
                <button class="btn-action-danger" @click="removeInd(i.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="showFormInd" class="modal-overlay" @click.self="showFormInd = false">
        <div class="modal modal-wide">
          <h2>{{ editingIndId !== null ? 'Editar' : 'Nuevo' }} indicador</h2>
          <form @submit.prevent="saveInd">
            <label>Proyecto</label>
            <select v-model="formInd.proyecto" required>
              <option :value="null">Seleccionar</option>
              <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
            </select>
            <label>Descripción</label>
            <textarea v-model="formInd.descripcion" rows="2" />
            <label>Unidad de medida</label>
            <input v-model="formInd.unidad_medida" placeholder="Cantidad, Porcentaje..." />
            <label>Frecuencia</label>
            <select v-model="formInd.frecuencia">
              <option value="">Seleccionar</option>
              <option value="Mensual">Mensual</option>
              <option value="Trimestral">Trimestral</option>
              <option value="Semestral">Semestral</option>
              <option value="Anual">Anual</option>
            </select>
            <div class="modal-actions">
              <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
              <button type="button" class="btn-cancel" @click="showFormInd = false">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.planificacion-panel { max-width: 1000px; }
.page-header { margin-bottom: 1rem; }
.page-header h1 { margin-bottom: 0.5rem; }
.subtitle { color: #64748b; font-size: 0.9rem; margin-bottom: 1rem; }
.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #e2e8f0;
}
.tab {
  padding: 0.5rem 1rem;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  color: #64748b;
  cursor: pointer;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.35rem;
}
.tab:hover { color: #334155; }
.tab.active { color: #3b82f6; border-bottom-color: #3b82f6; font-weight: 500; }
.tab-icon { font-size: 1rem; }
.tab-content { padding-top: 0.5rem; }
.toolbar { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; margin-bottom: 1rem; }
.search-input { flex: 1; min-width: 160px; padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.select-filter { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; min-width: 180px; }
.btn-outline { background: transparent; border: 1px solid #e2e8f0; color: #475569; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; font-size: 0.9rem; }
.btn-outline:hover { background: #f8fafc; }
.btn-secondary { background: #16a34a; color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; font-size: 0.9rem; }
.btn-secondary:disabled { background: #94a3b8; cursor: not-allowed; }
.btn-primary { background: #3b82f6; color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; }
.table { width: 100%; background: white; border-radius: 8px; overflow: hidden; }
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.table th { background: #f8fafc; }
.desc-cell { max-width: 400px; }
.page .btn-action, .page .btn-action-danger { margin-right: 0.5rem; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 100; }
.modal { background: white; padding: 1.5rem; border-radius: 10px; max-width: 420px; width: 90%; }
.modal-wide { max-width: 540px; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.cargando, .empty-state { text-align: center; padding: 2rem; color: #64748b; }
.arbol-container { background: white; border-radius: 8px; padding: 1rem; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.nivel { margin-bottom: 0.25rem; }
.hijos { margin-left: 1.5rem; margin-top: 0.25rem; border-left: 2px solid #e2e8f0; padding-left: 0.75rem; }
.nodo {
  padding: 0.5rem 0.75rem;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.95rem;
}
.nodo:hover { background: #f8fafc; }
.nodo .icono { min-width: 1rem; color: #94a3b8; font-size: 0.75rem; }
.nodo.eje { color: #0d47a1; font-weight: 600; }
.nodo.plan { color: #1565c0; font-weight: 500; }
.nodo.programa { color: #1976d2; }
.nodo.objetivo { color: #334155; }
.nodo.proyecto { color: #3b82f6; }
.nodo.proyecto.clickable { cursor: pointer; }
.nodo.proyecto.clickable:hover { text-decoration: underline; }
.nodo.indicador { color: #64748b; font-size: 0.9rem; cursor: default; }
.nodo .label { color: #94a3b8; font-style: italic; }
.nodo .valor { flex: 1; }
.nodo .badge { background: #dbeafe; color: #2563eb; padding: 0.15rem 0.4rem; border-radius: 4px; font-size: 0.8rem; }
.nodo .estado, .nodo .meta { font-size: 0.8rem; color: #64748b; }
.nodo-acciones {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  margin-left: auto;
}
.btn-nodo {
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  background: #e2e8f0;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  color: #475569;
  display: flex;
  align-items: center;
}
.btn-nodo:hover { background: #cbd5e1; color: #334155; }
.btn-nodo-danger { background: #fee2e2; color: #dc2626; }
.btn-nodo-danger:hover { background: #fecaca; }
</style>
