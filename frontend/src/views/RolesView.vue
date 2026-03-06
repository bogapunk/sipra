<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconPlus from '@/components/icons/IconPlus.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconEye from '@/components/icons/IconEye.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { useModalClose } from '@/composables/useModalClose'
import { exportToCsv } from '@/utils/exportCsv'
import { extraerMensajeError } from '@/utils/apiError'
import EmptyState from '@/components/EmptyState.vue'

const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const roles = ref<Record<string, unknown>[]>([])
const buscarRol = ref('')
const showForm = ref(false)
const showVerModal = ref(false)
const rolVer = ref<Record<string, unknown> | null>(null)
const editingId = ref<number | null>(null)
const form = ref({ nombre: '', descripcion: '' })
const errorNombre = ref('')

function parseListResponse(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

function validarNombre() {
  if (!form.value.nombre.trim()) {
    errorNombre.value = 'El nombre es obligatorio.'
    return false
  }
  errorNombre.value = ''
  return true
}

const rolesFiltrados = computed(() => {
  const q = buscarRol.value.trim().toLowerCase()
  if (!q) return roles.value
  return roles.value.filter((r: Record<string, unknown>) =>
    String(r.nombre || '').toLowerCase().includes(q) ||
    String(r.descripcion || '').toLowerCase().includes(q)
  )
})

async function descargarExcel() {
  const lista = rolesFiltrados.value
  const headers = ['Nombre', 'Descripción']
  const rows = lista.map((r: Record<string, unknown>) => [
    String(r.nombre || ''),
    String(r.descripcion || ''),
  ])
  await exportToCsv(headers, rows, `roles_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  try {
    const res = await api.get('roles/')
    roles.value = parseListResponse(res.data)
  } catch (e) {
    roles.value = []
    toast.error(extraerMensajeError(e, 'No se pudieron cargar los roles.'))
  }
}

const openVer = (r: Record<string, unknown>) => {
  rolVer.value = r
  showVerModal.value = true
}

const closeVerModal = () => {
  showVerModal.value = false
  rolVer.value = null
}
const closeForm = () => { showForm.value = false }
useModalClose(showVerModal, closeVerModal)
useModalClose(showForm, closeForm)

const openCreate = () => {
  editingId.value = null
  form.value = { nombre: '', descripcion: '' }
  showForm.value = true
}

const openEdit = (r: Record<string, unknown>) => {
  editingId.value = r.id as number
  form.value = {
    nombre: (r.nombre as string) || '',
    descripcion: (r.descripcion as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  if (!validarNombre()) return
  try {
    if (editingId.value) {
      await api.patch(`roles/${editingId.value}/`, form.value)
      toast.success('Rol actualizado correctamente.')
    } else {
      await api.post('roles/', form.value)
      toast.success('Rol creado correctamente.')
    }
    showForm.value = false
    load()
  } catch {
    toast.error('Error al guardar el rol.')
  }
}

const remove = async (id: number) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`roles/${id}/`)
      toast.success('Registro eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar el rol.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Roles</h1>
    <div class="toolbar">
      <input
        v-model="buscarRol"
        type="search"
        placeholder="Buscar por nombre o descripción..."
        class="search-input"
      />
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!rolesFiltrados.length">
          <IconDownload class="btn-icon" />
          Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" />
          Nuevo rol
        </button>
      </div>
    </div>

    <EmptyState
      v-if="!rolesFiltrados.length"
      :titulo="buscarRol.trim() ? 'Sin resultados' : 'No hay roles'"
      :mensaje="buscarRol.trim() ? 'No se encontraron roles que coincidan con la búsqueda.' : 'Aún no hay roles cargados. Use el botón «Nuevo rol» para crear el primero.'"
      icono="lista"
    />
    <div v-else class="table-wrapper">
      <table class="table">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Descripción</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in rolesFiltrados" :key="(r.id as number)">
          <td>{{ r.nombre }}</td>
          <td>{{ r.descripcion }}</td>
          <td class="actions-cell">
            <button class="btn-action" title="Ver" @click="openVer(r)"><IconEye class="btn-icon-sm" /> Ver</button>
            <button class="btn-action" title="Editar" @click="openEdit(r)"><IconEdit class="btn-icon-sm" /> Editar</button>
            <button class="btn-action-danger" title="Eliminar" @click="remove(r.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <!-- Modal Ver detalle rol -->
    <div v-if="showVerModal && rolVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-ver">
        <h2>Detalle del rol</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Nombre</span>
            <span class="detalle-valor">{{ rolVer.nombre || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Descripción</span>
            <p class="detalle-valor detalle-desc">{{ rolVer.descripcion || '-' }}</p>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal">Cerrar</button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nuevo' }} rol</h2>
        <form @submit.prevent="save">
          <label>Nombre <span class="required">*</span></label>
          <input
            v-model="form.nombre"
            placeholder="Nombre"
            :class="{ 'input-error': errorNombre }"
            @blur="validarNombre"
          />
          <span v-if="errorNombre" class="error-msg">{{ errorNombre }}</span>
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="3" />
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
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.required { color: #dc2626; }
.input-error { border-color: #dc2626 !important; }
.error-msg { font-size: 0.85rem; color: #dc2626; margin-top: -0.25rem; }
.modal-ver { max-width: 480px; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
.detalle-desc { white-space: pre-wrap; line-height: 1.5; margin: 0; }
</style>
