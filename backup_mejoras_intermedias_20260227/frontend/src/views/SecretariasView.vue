<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/services/api'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconPlus from '@/components/icons/IconPlus.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconEye from '@/components/icons/IconEye.vue'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import { useModalClose } from '@/composables/useModalClose'
import { exportToCsv } from '@/utils/exportCsv'
import { extraerMensajeError } from '@/utils/apiError'
import EmptyState from '@/components/EmptyState.vue'

const router = useRouter()
const { isAdmin } = useAuth()
const toast = useToast()
const secretarias = ref<Record<string, unknown>[]>([])
const buscarSecretaria = ref('')
const filtroEstado = ref<'all' | 'activa' | 'inactiva'>('all')
const showForm = ref(false)
const showVerModal = ref(false)
const secretariaVer = ref<Record<string, unknown> | null>(null)
const editingId = ref<number | null>(null)
const form = ref({ codigo: '', nombre: '', descripcion: '', activa: true })
const errorCodigo = ref('')
const errorNombre = ref('')

function parseListResponse(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

function validarCampos() {
  let ok = true
  if (!form.value.codigo.trim()) {
    errorCodigo.value = 'El código es obligatorio.'
    ok = false
  } else errorCodigo.value = ''
  if (!form.value.nombre.trim()) {
    errorNombre.value = 'El nombre es obligatorio.'
    ok = false
  } else errorNombre.value = ''
  return ok
}

const secretariasFiltradas = computed(() => {
  let list = secretarias.value
  if (filtroEstado.value === 'activa') list = list.filter((s: Record<string, unknown>) => s.activa !== false)
  if (filtroEstado.value === 'inactiva') list = list.filter((s: Record<string, unknown>) => s.activa === false)
  const q = buscarSecretaria.value.trim().toLowerCase()
  if (!q) return list
  return list.filter((s: Record<string, unknown>) =>
    String(s.codigo || '').toLowerCase().includes(q) ||
    String(s.nombre || '').toLowerCase().includes(q)
  )
})

async function descargarExcel() {
  const lista = secretariasFiltradas.value
  const headers = ['Código', 'Nombre', 'Descripción', 'Estado']
  const rows = lista.map((s: Record<string, unknown>) => [
    String(s.codigo || ''),
    String(s.nombre || ''),
    String(s.descripcion || ''),
    s.activa !== false ? 'Activa' : 'Inactiva',
  ])
  await exportToCsv(headers, rows, `secretarias_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  try {
    const res = await api.get('secretarias/')
    secretarias.value = parseListResponse(res.data)
  } catch (e) {
    secretarias.value = []
    toast.error(extraerMensajeError(e, 'No se pudieron cargar las secretarías.'))
  }
}

const openVer = (s: Record<string, unknown>) => {
  secretariaVer.value = s
  showVerModal.value = true
}

const closeVerModal = () => {
  showVerModal.value = false
  secretariaVer.value = null
}
const closeForm = () => { showForm.value = false }
useModalClose(showVerModal, closeVerModal)
useModalClose(showForm, closeForm)

const openCreate = () => {
  editingId.value = null
  form.value = { codigo: '', nombre: '', descripcion: '', activa: true }
  showForm.value = true
}

const openEdit = (s: Record<string, unknown>) => {
  editingId.value = s.id as number
  form.value = {
    codigo: (s.codigo as string) || '',
    nombre: (s.nombre as string) || '',
    descripcion: (s.descripcion as string) || '',
    activa: s.activa !== false,
  }
  showForm.value = true
}

const save = async () => {
  if (!validarCampos()) return
  try {
    if (editingId.value) {
      await api.patch(`secretarias/${editingId.value}/`, form.value)
      toast.success('Secretaría actualizada correctamente.')
    } else {
      await api.post('secretarias/', form.value)
      toast.success('Secretaría creada correctamente.')
    }
    showForm.value = false
    load()
  } catch {
    toast.error('Error al guardar la secretaría.')
  }
}

const toggleActiva = async (s: Record<string, unknown>) => {
  try {
    const nuevaActiva = !(s.activa !== false)
    await api.patch(`secretarias/${s.id}/`, { activa: nuevaActiva })
    toast.success(nuevaActiva ? 'Secretaría activada.' : 'Secretaría desactivada.')
    load()
  } catch {
    toast.error('Error al cambiar el estado.')
  }
}

function verProyectos(s: Record<string, unknown>) {
  router.push({ path: '/proyectos', query: { secretaria: String(s.id) } })
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Secretarías</h1>
    <div class="toolbar">
      <input
        v-model="buscarSecretaria"
        type="search"
        placeholder="Buscar por código o nombre..."
        class="search-input"
      />
      <select v-model="filtroEstado" class="filter-select">
        <option value="all">Todas</option>
        <option value="activa">Activas</option>
        <option value="inactiva">Inactivas</option>
      </select>
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!secretariasFiltradas.length">
          <IconDownload class="btn-icon" />
          Descargar Excel
        </button>
        <button v-if="isAdmin" class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" />
          Nueva Secretaría
        </button>
      </div>
    </div>

    <EmptyState
      v-if="!secretariasFiltradas.length"
      :titulo="buscarSecretaria.trim() ? 'Sin resultados' : 'No hay secretarías'"
      :mensaje="buscarSecretaria.trim() ? 'No se encontraron secretarías que coincidan con la búsqueda. Intente con otros términos.' : 'Aún no hay secretarías cargadas. Use el botón «Nueva Secretaría» para crear la primera.'"
      icono="lista"
    />
    <div v-else class="table-wrapper">
      <table class="table">
      <thead>
        <tr>
          <th>Código</th>
          <th>Nombre</th>
          <th>Descripción</th>
          <th>Estado</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="s in secretariasFiltradas" :key="(s.id as number)">
          <td>{{ s.codigo }}</td>
          <td>{{ s.nombre }}</td>
          <td>{{ (s.descripcion || '').toString().slice(0, 60) }}{{ (s.descripcion || '').toString().length > 60 ? '...' : '' }}</td>
          <td>
            <span :class="['badge', s.activa !== false ? 'badge-activa' : 'badge-inactiva']">
              {{ s.activa !== false ? 'Activa' : 'Inactiva' }}
            </span>
          </td>
          <td class="actions-cell">
            <button class="btn-action" title="Ver" @click="openVer(s)"><IconEye class="btn-icon-sm" /> Ver</button>
            <button class="btn-action" title="Ver proyectos" @click="verProyectos(s)">🔎 Ver proyectos</button>
            <template v-if="isAdmin">
              <button class="btn-action" title="Editar" @click="openEdit(s)"><IconEdit class="btn-icon-sm" /> Editar</button>
              <button
                :class="['btn-action', s.activa !== false ? 'btn-action-warn' : 'btn-action-success']"
                @click="toggleActiva(s)"
              >
                {{ s.activa !== false ? '🔄 Desactivar' : '🔄 Activar' }}
              </button>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <!-- Modal Ver detalle secretaría -->
    <div v-if="showVerModal && secretariaVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-ver">
        <h2>Detalle de la secretaría</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Código</span>
            <span class="detalle-valor">{{ secretariaVer.codigo || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Nombre</span>
            <span class="detalle-valor">{{ secretariaVer.nombre || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Descripción</span>
            <p class="detalle-valor detalle-desc">{{ secretariaVer.descripcion || '-' }}</p>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Estado</span>
            <span class="detalle-valor">{{ secretariaVer.activa !== false ? 'Activa' : 'Inactiva' }}</span>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal">Cerrar</button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nueva' }} secretaría</h2>
        <form @submit.prevent="save">
          <label>Código <span class="required">*</span></label>
          <input
            v-model="form.codigo"
            placeholder="Ej: EC, CYT"
            :readonly="!!editingId"
            :class="{ 'input-error': errorCodigo }"
            @blur="validarCampos"
          />
          <span v-if="errorCodigo" class="error-msg">{{ errorCodigo }}</span>
          <label>Nombre <span class="required">*</span></label>
          <input
            v-model="form.nombre"
            placeholder="Nombre"
            :class="{ 'input-error': errorNombre }"
            @blur="validarCampos"
          />
          <span v-if="errorNombre" class="error-msg">{{ errorNombre }}</span>
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="3" />
          <label v-if="editingId" class="checkbox">
            <input v-model="form.activa" type="checkbox" />
            Activa
          </label>
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="closeForm"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </form>
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
.filter-select {
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.9rem;
}
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; }
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
.btn-primary {
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
.badge { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.85rem; }
.badge-activa { background: #dcfce7; color: #166534; }
.badge-inactiva { background: #fee2e2; color: #991b1b; }
.page .btn-action, .page .btn-action-warn, .page .btn-action-success { margin-right: 0.5rem; }
.btn-action-warn { color: #b45309; }
.btn-action-success { color: #15803d; }
.empty-msg { color: #64748b; margin-top: 0.5rem; }
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
  max-width: 450px;
  width: 90%;
}
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.modal input[readonly] { background: #f1f5f9; }
.checkbox { display: flex; align-items: center; gap: 0.5rem; }
.modal-ver { max-width: 480px; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
.detalle-desc { white-space: pre-wrap; line-height: 1.5; margin: 0; }
.required { color: #dc2626; }
.input-error { border-color: #dc2626 !important; }
.error-msg { font-size: 0.85rem; color: #dc2626; margin-top: -0.25rem; }
</style>
