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
const programas = ref<Record<string, unknown>[]>([])
const planes = ref<Record<string, unknown>[]>([])
const buscar = ref('')
const filtroPlan = ref<number | ''>('')
const showForm = ref(false)
const editingId = ref<string | null>(null)
const form = ref({
  id_programa: '',
  plan: null as number | null,
  nombre_programa: '',
})

const filtrados = computed(() => {
  let lista = programas.value
  if (filtroPlan.value !== '') {
    lista = lista.filter((p: Record<string, unknown>) => p.plan === Number(filtroPlan.value))
  }
  const q = buscar.value.trim().toLowerCase()
  if (q) lista = lista.filter((p: Record<string, unknown>) =>
    String(p.nombre_programa || p.id_programa || '').toLowerCase().includes(q)
  )
  return lista
})

async function descargarExcel() {
  const headers = ['Código', 'Plan', 'Nombre']
  const rows = filtrados.value.map((p: Record<string, unknown>) => [
    String(p.id_programa ?? ''),
    String(p.plan_nombre || ''),
    String(p.nombre_programa || ''),
  ])
  await exportToCsv(headers, rows, `programas_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  const [prRes, plRes] = await Promise.all([api.get('programas/'), api.get('planes/')])
  programas.value = Array.isArray(prRes.data) ? prRes.data : (prRes.data?.results || [])
  planes.value = Array.isArray(plRes.data) ? plRes.data : (plRes.data?.results || [])
}

const openCreate = () => {
  editingId.value = null
  form.value = {
    id_programa: '',
    plan: planes.value[0] ? (planes.value[0] as Record<string, unknown>).id_plan as number : null,
    nombre_programa: '',
  }
  showForm.value = true
}

const openEdit = (p: Record<string, unknown>) => {
  editingId.value = p.id_programa as string
  form.value = {
    id_programa: p.id_programa as string,
    plan: p.plan as number,
    nombre_programa: (p.nombre_programa as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  try {
    const payload = { plan: form.value.plan, nombre_programa: form.value.nombre_programa }
    if (editingId.value !== null) {
      await api.patch(`programas/${editingId.value}/`, payload)
      toast.success('Programa actualizado correctamente.')
    } else {
      await api.post('programas/', { ...payload, id_programa: form.value.id_programa })
      toast.success('Programa creado correctamente.')
    }
    showForm.value = false
    load()
  } catch {
    toast.error('Error al guardar.')
  }
}

const remove = async (id: string) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`programas/${id}/`)
      toast.success('Eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar. Verifique que no tenga objetivos o proyectos asociados.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Programas</h1>
    <div class="toolbar">
      <input v-model="buscar" type="search" placeholder="Buscar..." class="search-input" />
      <select v-model="filtroPlan" class="select-filter">
        <option value="">Todos los planes</option>
        <option v-for="pl in planes" :key="(pl.id_plan as number)" :value="pl.id_plan">{{ pl.nombre_plan }}</option>
      </select>
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!filtrados.length">
          <IconDownload class="btn-icon" /> Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" /> Nuevo programa
        </button>
      </div>
    </div>

    <table class="table">
      <thead>
        <tr>
          <th>Código</th>
          <th>Plan</th>
          <th>Nombre</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="p in filtrados" :key="(p.id_programa as string)">
          <td>{{ p.id_programa }}</td>
          <td>{{ p.plan_nombre }}</td>
          <td>{{ p.nombre_programa }}</td>
          <td class="actions-cell">
            <button class="btn-action" @click="openEdit(p)"><IconEdit class="btn-icon-sm" /> Editar</button>
            <button class="btn-action-danger" @click="remove(p.id_programa as string)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal">
        <h2>{{ editingId !== null ? 'Editar' : 'Nuevo' }} programa</h2>
        <form @submit.prevent="save">
          <label>Código (ej: 1.1, 2.3)</label>
          <input v-model="form.id_programa" placeholder="1.1" required :disabled="editingId !== null" />
          <label>Plan</label>
          <select v-model="form.plan" required>
            <option :value="null">Seleccionar</option>
            <option v-for="pl in planes" :key="(pl.id_plan as number)" :value="pl.id_plan">{{ pl.nombre_plan }}</option>
          </select>
          <label>Nombre</label>
          <input v-model="form.nombre_programa" placeholder="Nombre del programa" required />
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
.select-filter { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; min-width: 220px; }
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
.modal input, .modal select { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
</style>
