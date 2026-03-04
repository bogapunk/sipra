<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
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

const { isVisualizador } = useAuth()
const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const tareas = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const areas = ref<Record<string, unknown>[]>([])
const secretarias = ref<Record<string, unknown>[]>([])
const usuarios = ref<Record<string, unknown>[]>([])
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

const load = async () => {
  const params: Record<string, string | number> = {}
  if (filtroEstado.value) params.estado = filtroEstado.value
  const [t, p, a, s, uRes] = await Promise.all([
    api.get('tareas/', { params }),
    api.get('proyectos/'),
    api.get('areas/', { params: { estado: 'true' } }),
    api.get('secretarias/', { params: { activa: 'true' } }),
    api.get('usuarios/selector/').catch(() => api.get('usuarios/').then(r => ({
      data: Array.isArray(r.data) ? r.data : (r.data?.results ?? []),
    })).catch(() => ({ data: [] }))),
  ])
  tareas.value = Array.isArray(t.data) ? t.data : (t.data?.results ?? [])
  proyectos.value = Array.isArray(p.data) ? p.data : (p.data?.results ?? [])
  areas.value = Array.isArray(a.data) ? a.data : (a.data?.results ?? [])
  secretarias.value = Array.isArray(s.data) ? s.data : (s.data?.results ?? [])
  usuarios.value = Array.isArray(uRes.data) ? uRes.data : (uRes.data?.results ?? [])
}

const openCreate = () => {
  editingId.value = null
  tipoOrganizacion.value = 'area'
  form.value = {
    proyecto: null,
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
}

const openEdit = (t: Record<string, unknown>) => {
  editingId.value = t.id as number
  const areaId = t.area ? (typeof t.area === 'object' ? (t.area as { id?: number }).id : t.area) : null
  const secretariaId = t.secretaria ? (typeof t.secretaria === 'object' ? (t.secretaria as { id?: number }).id : t.secretaria) : null
  tipoOrganizacion.value = secretariaId ? 'secretaria' : (areaId ? 'area' : 'ninguna')
  const proyId = t.proyecto ? (typeof t.proyecto === 'object' ? (t.proyecto as { id?: number }).id : t.proyecto) : null
  form.value = {
    proyecto: proyId != null ? Number(proyId) : null,
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

const openVer = (t: Record<string, unknown>) => {
  tareaVer.value = t
  showVerModal.value = true
}

const closeVerModal = () => {
  showVerModal.value = false
  tareaVer.value = null
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
  const headers = ['Título', 'Área/Secretaría', 'Usuario responsable', 'Estado', 'Avance %', 'Prioridad', 'Proyecto']
  const rows = lista.map((t: Record<string, unknown>) => [
    String(t.titulo || ''),
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
  if (!q) return lista
  return lista.filter((t: Record<string, unknown>) =>
    String(t.titulo || '').toLowerCase().includes(q)
  )
})

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Tareas</h1>
    <p v-if="isVisualizador" class="subtitle-rol">Vista de solo lectura: puede consultar y exportar todas las tareas del sistema.</p>
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

    <div class="table-wrapper">
      <table class="table">
      <thead>
        <tr>
          <th>Título</th>
          <th>Área / Secretaría</th>
          <th>Usuario</th>
          <th>Estado</th>
          <th>Avance</th>
          <th>Prioridad</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="!tareasFiltradas.length" class="empty-row">
          <td colspan="7">
            {{ buscarTitulo.trim() ? 'No hay tareas que coincidan con la búsqueda.' : 'No hay tareas cargadas.' }}
          </td>
        </tr>
        <tr v-for="t in tareasFiltradas" :key="(t.id as number)">
          <td>{{ t.titulo }}</td>
          <td>{{ t.organizacion_nombre || t.area_nombre || t.secretaria_nombre || '-' }}</td>
          <td>{{ t.responsable_nombre || '-' }}</td>
          <td>{{ t.estado }}</td>
          <td>{{ t.porcentaje_avance }}%</td>
          <td>{{ t.prioridad }}</td>
          <td class="actions-cell">
            <button class="btn-action" title="Ver" @click="openVer(t)"><IconEye class="btn-icon-sm" /> Ver</button>
            <template v-if="!isVisualizador">
              <button class="btn-action" title="Asignar" @click="openAsignar(t)"><IconPlus class="btn-icon-sm" /> Asignar</button>
              <button class="btn-action" title="Editar" @click="openEdit(t)"><IconEdit class="btn-icon-sm" /> Editar</button>
              <button class="btn-action-danger" title="Eliminar" @click="remove(t.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
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
          <select v-model="form.responsable" required>
            <option :value="null">Seleccionar</option>
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">{{ u.nombre_completo || u.nombre }}</option>
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
            <button type="button" class="btn-cancel" @click="showForm = false"><IconCancel class="btn-icon" /> Cancelar</button>
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
.toolbar .btn-primary {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
}
.table { width: 100%; background: white; border-radius: 8px; overflow: hidden; }
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
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
</style>
