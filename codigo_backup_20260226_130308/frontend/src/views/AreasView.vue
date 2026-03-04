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
import { exportToCsv } from '@/utils/exportCsv'

const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const areas = ref<Record<string, unknown>[]>([])
const buscarArea = ref('')
const showForm = ref(false)
const showVerModal = ref(false)
const areaVer = ref<Record<string, unknown> | null>(null)

const areasFiltradas = computed(() => {
  const q = buscarArea.value.trim().toLowerCase()
  if (!q) return areas.value
  return areas.value.filter((a: Record<string, unknown>) =>
    String(a.nombre || '').toLowerCase().includes(q)
  )
})

async function descargarExcel() {
  const lista = areasFiltradas.value
  const headers = ['Nombre', 'Descripción', 'Estado']
  const rows = lista.map((a: Record<string, unknown>) => [
    String(a.nombre || ''),
    String(a.descripcion || ''),
    (a.estado !== false ? 'Activo' : 'Inactivo'),
  ])
  await exportToCsv(headers, rows, `areas_${new Date().toISOString().slice(0, 10)}.csv`)
}
const editingId = ref<number | null>(null)
const form = ref({ nombre: '', descripcion: '', estado: true })

const load = async () => {
  areas.value = (await api.get('areas/')).data
}

const openVer = (a: Record<string, unknown>) => {
  areaVer.value = a
  showVerModal.value = true
}

const closeVerModal = () => {
  showVerModal.value = false
  areaVer.value = null
}

const openCreate = () => {
  editingId.value = null
  form.value = { nombre: '', descripcion: '', estado: true }
  showForm.value = true
}

const openEdit = (a: Record<string, unknown>) => {
  editingId.value = a.id as number
  form.value = {
    nombre: (a.nombre as string) || '',
    descripcion: (a.descripcion as string) || '',
    estado: a.estado !== false,
  }
  showForm.value = true
}

const save = async () => {
  try {
    if (editingId.value) {
      await api.patch(`areas/${editingId.value}/`, form.value)
      toast.success('Área actualizada correctamente.')
    } else {
      await api.post('areas/', form.value)
      toast.success('Área creada correctamente.')
    }
    showForm.value = false
    load()
  } catch {
    toast.error('Error al guardar el área.')
  }
}

const remove = async (id: number) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`areas/${id}/`)
      toast.success('Registro eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar el área.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Áreas</h1>
    <div class="toolbar">
      <input
        v-model="buscarArea"
        type="search"
        placeholder="Buscar por nombre..."
        class="search-input"
      />
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!areasFiltradas.length">
          <IconDownload class="btn-icon" />
          Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" />
          Nueva área
        </button>
      </div>
    </div>

    <div class="table-wrapper">
      <table class="table">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Estado</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="a in areasFiltradas" :key="(a.id as number)">
          <td>{{ a.nombre }}</td>
          <td>{{ a.estado ? 'Activo' : 'Inactivo' }}</td>
          <td class="actions-cell">
            <button class="btn-action" title="Ver" @click="openVer(a)"><IconEye class="btn-icon-sm" /> Ver</button>
            <button class="btn-action" title="Editar" @click="openEdit(a)"><IconEdit class="btn-icon-sm" /> Editar</button>
            <button class="btn-action-danger" title="Eliminar" @click="remove(a.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <!-- Modal Ver detalle área -->
    <div v-if="showVerModal && areaVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-ver">
        <h2>Detalle del área</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Nombre</span>
            <span class="detalle-valor">{{ areaVer.nombre || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Descripción</span>
            <p class="detalle-valor detalle-desc">{{ areaVer.descripcion || '-' }}</p>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Estado</span>
            <span class="detalle-valor">{{ areaVer.estado !== false ? 'Activo' : 'Inactivo' }}</span>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal">Cerrar</button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nueva' }} área</h2>
        <form @submit.prevent="save">
          <label>Nombre</label>
          <input v-model="form.nombre" placeholder="Nombre" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="3" />
          <label class="checkbox">
            <input v-model="form.estado" type="checkbox" />
            Activo
          </label>
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="showForm = false"><IconCancel class="btn-icon" /> Cancelar</button>
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
  margin-bottom: 1rem;
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
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.checkbox { display: flex; align-items: center; gap: 0.5rem; }
.modal-ver { max-width: 480px; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
.detalle-desc { white-space: pre-wrap; line-height: 1.5; margin: 0; }
</style>
