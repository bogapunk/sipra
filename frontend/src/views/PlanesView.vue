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
const planes = ref<Record<string, unknown>[]>([])
const ejes = ref<Record<string, unknown>[]>([])
const buscar = ref('')
const filtroEje = ref<number | ''>('')
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({
  id_plan: 0,
  eje: null as number | null,
  nombre_plan: '',
  proposito_politica_publica: '',
  vision_estrategica: '',
})

const filtrados = computed(() => {
  let lista = planes.value
  if (filtroEje.value !== '') {
    lista = lista.filter((p: Record<string, unknown>) => p.eje === Number(filtroEje.value))
  }
  const q = buscar.value.trim().toLowerCase()
  if (q) lista = lista.filter((p: Record<string, unknown>) =>
    String(p.nombre_plan || '').toLowerCase().includes(q)
  )
  return lista
})

async function descargarExcel() {
  const headers = ['ID', 'Eje', 'Nombre', 'Propósito', 'Visión']
  const rows = filtrados.value.map((p: Record<string, unknown>) => [
    String(p.id_plan ?? ''),
    String(p.eje_nombre || ''),
    String(p.nombre_plan || ''),
    String((p.proposito_politica_publica || '').toString().slice(0, 80)),
    String((p.vision_estrategica || '').toString().slice(0, 80)),
  ])
  await exportToCsv(headers, rows, `planes_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  const [pRes, eRes] = await Promise.all([api.get('planes/'), api.get('ejes/')])
  planes.value = Array.isArray(pRes.data) ? pRes.data : (pRes.data?.results || [])
  ejes.value = Array.isArray(eRes.data) ? eRes.data : (eRes.data?.results || [])
}

const openCreate = () => {
  editingId.value = null
  const maxId = planes.value.length ? Math.max(...planes.value.map((p: Record<string, unknown>) => (p.id_plan as number) || 0)) : 0
  form.value = {
    id_plan: maxId + 1,
    eje: ejes.value[0] ? (ejes.value[0] as Record<string, unknown>).id_eje as number : null,
    nombre_plan: '',
    proposito_politica_publica: '',
    vision_estrategica: '',
  }
  showForm.value = true
}

const openEdit = (p: Record<string, unknown>) => {
  editingId.value = p.id_plan as number
  form.value = {
    id_plan: p.id_plan as number,
    eje: p.eje as number,
    nombre_plan: (p.nombre_plan as string) || '',
    proposito_politica_publica: (p.proposito_politica_publica as string) || '',
    vision_estrategica: (p.vision_estrategica as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  try {
    const payload = { ...form.value }
    if (editingId.value !== null) {
      await api.patch(`planes/${editingId.value}/`, payload)
      toast.success('Plan actualizado correctamente.')
    } else {
      await api.post('planes/', payload)
      toast.success('Plan creado correctamente.')
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
      await api.delete(`planes/${id}/`)
      toast.success('Eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar. Verifique que no tenga programas asociados.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Planes</h1>
    <div class="toolbar">
      <input v-model="buscar" type="search" placeholder="Buscar por nombre..." class="search-input" />
      <select v-model="filtroEje" class="select-filter">
        <option value="">Todos los ejes</option>
        <option v-for="e in ejes" :key="(e.id_eje as number)" :value="e.id_eje">{{ e.nombre_eje }}</option>
      </select>
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!filtrados.length">
          <IconDownload class="btn-icon" /> Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" /> Nuevo plan
        </button>
      </div>
    </div>

    <div class="table-wrapper">
      <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Eje</th>
            <th>Nombre</th>
            <th class="actions-header">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in filtrados" :key="(p.id_plan as number)">
            <td>{{ p.id_plan }}</td>
            <td>{{ p.eje_nombre }}</td>
            <td>{{ p.nombre_plan }}</td>
            <td class="actions-cell">
              <button type="button" class="btn-action btn-action-editar" @click="openEdit(p)"><IconEdit class="btn-icon-sm" /> Editar</button>
              <button type="button" class="btn-action-danger" @click="remove(p.id_plan as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal modal-wide">
        <h2>{{ editingId !== null ? 'Editar' : 'Nuevo' }} plan</h2>
        <form @submit.prevent="save">
          <label>ID Plan</label>
          <input v-model.number="form.id_plan" type="number" min="1" required :disabled="editingId !== null" />
          <label>Eje</label>
          <select v-model="form.eje" required>
            <option :value="null">Seleccionar</option>
            <option v-for="e in ejes" :key="(e.id_eje as number)" :value="e.id_eje">{{ e.nombre_eje }}</option>
          </select>
          <label>Nombre</label>
          <input v-model="form.nombre_plan" placeholder="Nombre del plan" required />
          <label>Propósito política pública</label>
          <textarea v-model="form.proposito_politica_publica" rows="2" />
          <label>Visión estratégica</label>
          <textarea v-model="form.vision_estrategica" rows="2" />
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
.page h1 { margin-bottom: 1rem; }
.toolbar { display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center; margin-bottom: 1rem; }
.search-input { flex: 1; min-width: 180px; padding: 0.5rem 0.75rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.select-filter { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; min-width: 200px; }
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
.modal-wide { max-width: 520px; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
</style>
