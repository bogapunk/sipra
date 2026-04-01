<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconPlus from '@/components/icons/IconPlus.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import IconSave from '@/components/icons/IconSave.vue'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { exportToCsv } from '@/utils/exportCsv'

const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const ejes = ref<Record<string, unknown>[]>([])
const buscar = ref('')
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({ id_eje: 0, nombre_eje: '' })

const filtrados = computed(() => {
  const q = buscar.value.trim().toLowerCase()
  if (!q) return ejes.value
  return ejes.value.filter((e: Record<string, unknown>) =>
    String(e.nombre_eje || '').toLowerCase().includes(q)
  )
})

async function descargarExcel() {
  const headers = ['ID', 'Nombre']
  const rows = filtrados.value.map((e: Record<string, unknown>) => [
    String(e.id_eje ?? ''),
    String(e.nombre_eje || ''),
  ])
  await exportToCsv(headers, rows, `ejes_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  ejes.value = (await api.get('ejes/')).data
}

const openCreate = () => {
  editingId.value = null
  const maxId = ejes.value.length ? Math.max(...ejes.value.map((e: Record<string, unknown>) => (e.id_eje as number) || 0)) : 0
  form.value = { id_eje: maxId + 1, nombre_eje: '' }
  showForm.value = true
}

const openEdit = (e: Record<string, unknown>) => {
  editingId.value = e.id_eje as number
  form.value = {
    id_eje: e.id_eje as number,
    nombre_eje: (e.nombre_eje as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  try {
    if (editingId.value !== null) {
      await api.patch(`ejes/${editingId.value}/`, form.value)
      toast.success('Eje actualizado correctamente.')
    } else {
      await api.post('ejes/', form.value)
      toast.success('Eje creado correctamente.')
    }
    showForm.value = false
    load()
  } catch {
    toast.error('Error al guardar.')
  }
}

const remove = async (id: number) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`ejes/${id}/`)
      toast.success('Eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar. Verifique que no tenga planes asociados.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Ejes estratégicos</h1>
    <p class="subtitle">Estructura de planificación: Eje → Plan → Programa → Objetivo → Proyecto → Indicador</p>
    <div class="toolbar">
      <input v-model="buscar" type="search" placeholder="Buscar..." class="search-input" />
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!filtrados.length">
          <IconDownload class="btn-icon" /> Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" /> Nuevo eje
        </button>
      </div>
    </div>

    <div class="table-wrapper">
      <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Nombre</th>
            <th class="actions-header">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in filtrados" :key="(e.id_eje as number)">
            <td>{{ e.id_eje }}</td>
            <td>{{ e.nombre_eje }}</td>
            <td class="actions-cell">
              <button type="button" class="btn-action btn-action-editar" @click="openEdit(e)"><IconEdit class="btn-icon-sm" /> Editar</button>
              <button type="button" class="btn-action-danger" @click="remove(e.id_eje as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal">
        <h2>{{ editingId !== null ? 'Editar' : 'Nuevo' }} eje</h2>
        <form @submit.prevent="save">
          <label>ID</label>
          <input v-model.number="form.id_eje" type="number" min="1" required :disabled="editingId !== null" />
          <label>Nombre</label>
          <input v-model="form.nombre_eje" placeholder="Nombre del eje" required />
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="showForm = false">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 0.5rem; }
.subtitle { color: #64748b; font-size: 0.9rem; margin-bottom: 1rem; }
.toolbar { display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center; margin-bottom: 1rem; }
.search-input { flex: 1; min-width: 200px; padding: 0.5rem 0.75rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.btn-secondary { background: #16a34a; color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; font-size: 0.9rem; }
.btn-secondary:disabled { background: #94a3b8; cursor: not-allowed; }
.btn-primary { background: #3b82f6; color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; }
.table { width: 100%; background: white; border-radius: 8px; overflow: hidden; }
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.table th { background: #f8fafc; }
.page .btn-action, .page .btn-action-danger { margin-right: 0.5rem; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 100; }
.modal { background: white; padding: 1.5rem; border-radius: 10px; max-width: 420px; width: 90%; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
</style>
