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
import EmptyState from '@/components/EmptyState.vue'

const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const areas = ref<Record<string, unknown>[]>([])
const buscarArea = ref('')
const showForm = ref(false)
const showVerModal = ref(false)
const areaVer = ref<Record<string, unknown> | null>(null)

const closeVerModal = () => {
  showVerModal.value = false
  areaVer.value = null
}
const closeForm = () => { showForm.value = false }

useModalClose(showVerModal, closeVerModal)
useModalClose(showForm, closeForm)

const areasFiltradas = computed(() => {
  const q = buscarArea.value.trim().toLowerCase()
  if (!q) return areas.value
  return areas.value.filter((a: Record<string, unknown>) =>
    String(a.nombre || '').toLowerCase().includes(q)
  )
})

const resumenAreas = computed(() => {
  const total = areasFiltradas.value.length
  const activas = areasFiltradas.value.filter((a) => a.estado !== false).length
  return [
    { key: 'total', title: 'Areas visibles', value: total, meta: 'Resultado actual de la vista', tone: 'neutral' },
    { key: 'activas', title: 'Activas', value: activas, meta: `${Math.max(0, total - activas)} inactivas`, tone: 'success' },
  ]
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
const errorNombre = ref('')

const load = async () => {
  areas.value = (await api.get('areas/')).data
}

const openVer = (a: Record<string, unknown>) => {
  areaVer.value = a
  showVerModal.value = true
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

function validarNombre() {
  const n = form.value.nombre.trim()
  if (!n) {
    errorNombre.value = 'El nombre es obligatorio.'
    return false
  }
  errorNombre.value = ''
  return true
}

const save = async () => {
  if (!validarNombre()) return
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
    <div class="page-hero">
      <div>
        <h1>Áreas</h1>
        <p class="page-subtitle">Gestión y consulta de áreas con una vista consistente del catálogo organizacional.</p>
      </div>
    </div>

    <section class="summary-grid areas-summary">
      <article v-for="card in resumenAreas" :key="card.key" class="summary-card" :class="`tone-${card.tone}`">
        <span class="summary-title">{{ card.title }}</span>
        <strong class="summary-value">{{ card.value }}</strong>
        <span class="summary-meta">{{ card.meta }}</span>
      </article>
    </section>

    <div class="toolbar toolbar-card">
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

    <EmptyState
      v-if="!areasFiltradas.length"
      :titulo="buscarArea.trim() ? 'Sin resultados' : 'No hay áreas'"
      :mensaje="buscarArea.trim() ? 'No se encontraron áreas que coincidan con la búsqueda. Intente con otros términos.' : 'Aún no hay áreas cargadas. Use el botón «Nueva área» para crear la primera.'"
      :icono="buscarArea.trim() ? 'busqueda' : 'lista'"
    />
    <div v-else class="table-wrapper app-table-wrapper">
      <table class="table app-table">
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
          <td>
            <span class="status-chip" :class="a.estado ? 'status-active' : 'status-inactive'">
              {{ a.estado ? 'Activo' : 'Inactivo' }}
            </span>
          </td>
          <td class="actions-cell">
            <button type="button" class="btn-action btn-action-ver" title="Ver" @click="openVer(a)"><IconEye class="btn-icon-sm" /> Ver</button>
            <button type="button" class="btn-action btn-action-editar" title="Editar" @click="openEdit(a)"><IconEdit class="btn-icon-sm" /> Editar</button>
            <button type="button" class="btn-action-danger" title="Eliminar" @click="remove(a.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <!-- Modal Ver detalle área -->
    <div v-if="showVerModal && areaVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-ver app-modal app-modal-md">
        <h2>Detalle del área</h2>
        <div class="detalle-content app-detail-content">
          <div class="detalle-row app-detail-row">
            <span class="detalle-label app-detail-label">Nombre</span>
            <span class="detalle-valor app-detail-value">{{ areaVer.nombre || '-' }}</span>
          </div>
          <div class="detalle-row app-detail-row">
            <span class="detalle-label app-detail-label">Descripción</span>
            <p class="detalle-valor detalle-desc app-detail-value app-detail-desc">{{ areaVer.descripcion || '-' }}</p>
          </div>
          <div class="detalle-row app-detail-row">
            <span class="detalle-label app-detail-label">Estado</span>
            <span class="detalle-valor app-detail-value">{{ areaVer.estado !== false ? 'Activo' : 'Inactivo' }}</span>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal">Cerrar</button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal app-modal app-modal-sm">
        <h2>{{ editingId ? 'Editar' : 'Nueva' }} área</h2>
        <form class="app-form" @submit.prevent="save">
          <label>Nombre <span class="required">*</span></label>
          <input
            v-model="form.nombre"
            placeholder="Nombre"
            class="app-input"
            :class="{ 'input-error': errorNombre }"
            @blur="validarNombre"
          />
          <span v-if="errorNombre" class="error-msg">{{ errorNombre }}</span>
          <label>Descripción</label>
          <textarea v-model="form.descripcion" class="app-textarea" placeholder="Descripción" rows="3" />
          <label class="checkbox app-checkbox">
            <input v-model="form.estado" type="checkbox" />
            Activo
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
.page { display: flex; flex-direction: column; gap: 1rem; }
.page h1 { margin: 0; }
.areas-summary { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
}
.search-input {
  flex: 1;
  min-width: 200px;
  padding: 0.7rem 0.9rem;
  font-size: 0.9rem;
}
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; align-items: stretch; }
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
.checkbox { display: flex; align-items: center; gap: 0.5rem; }
.required { color: #dc2626; }
.input-error { border-color: #dc2626 !important; }
.error-msg { font-size: 0.85rem; color: #dc2626; margin-top: -0.25rem; }
@media (max-width: 700px) {
  .areas-summary { grid-template-columns: 1fr; }
}
</style>
