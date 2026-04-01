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
const indicadores = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const buscar = ref('')
const filtroProyecto = ref<number | ''>('')
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({
  proyecto: null as number | null,
  descripcion: '',
  unidad_medida: '',
  frecuencia: '',
})

const filtrados = computed(() => {
  let lista = indicadores.value
  if (filtroProyecto.value !== '') {
    lista = lista.filter((i: Record<string, unknown>) => i.proyecto === Number(filtroProyecto.value))
  }
  const q = buscar.value.trim().toLowerCase()
  if (q) lista = lista.filter((i: Record<string, unknown>) =>
    String(i.descripcion || i.proyecto_nombre || '').toLowerCase().includes(q)
  )
  return lista
})

async function descargarExcel() {
  const headers = ['Proyecto', 'Descripción', 'Unidad', 'Frecuencia']
  const rows = filtrados.value.map((i: Record<string, unknown>) => [
    String(i.proyecto_nombre || ''),
    String((i.descripcion || '').toString().slice(0, 80)),
    String(i.unidad_medida || ''),
    String(i.frecuencia || ''),
  ])
  await exportToCsv(headers, rows, `indicadores_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  try {
    const [iRes, pRes] = await Promise.all([
      api.get('indicadores/'),
      api.get('proyectos/'),
    ])
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

const openCreate = () => {
  editingId.value = null
  form.value = {
    proyecto: proyectos.value[0] ? (proyectos.value[0] as Record<string, unknown>).id as number : null,
    descripcion: '',
    unidad_medida: '',
    frecuencia: '',
  }
  showForm.value = true
}

const openEdit = (i: Record<string, unknown>) => {
  editingId.value = i.id as number
  form.value = {
    proyecto: i.proyecto as number,
    descripcion: (i.descripcion as string) || '',
    unidad_medida: (i.unidad_medida as string) || '',
    frecuencia: (i.frecuencia as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  try {
    const payload = { ...form.value }
    if (editingId.value !== null) {
      await api.patch(`indicadores/${editingId.value}/`, payload)
      toast.success('Indicador actualizado correctamente.')
    } else {
      await api.post('indicadores/', payload)
      toast.success('Indicador creado correctamente.')
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
      await api.delete(`indicadores/${id}/`)
      toast.success('Eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Indicadores</h1>
    <p class="subtitle">Indicadores de seguimiento asociados a proyectos</p>
    <div class="toolbar">
      <input v-model="buscar" type="search" placeholder="Buscar..." class="search-input" />
      <select v-model="filtroProyecto" class="select-filter">
        <option value="">Todos los proyectos</option>
        <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
      </select>
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!filtrados.length">
          <IconDownload class="btn-icon" /> Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" /> Nuevo indicador
        </button>
      </div>
    </div>

    <div class="table-wrapper">
      <table class="table">
        <thead>
          <tr>
            <th>Proyecto</th>
            <th>Descripción</th>
            <th>Unidad</th>
            <th>Frecuencia</th>
            <th class="actions-header">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="i in filtrados" :key="(i.id as number)">
            <td>{{ i.proyecto_nombre }}</td>
            <td class="desc-cell">{{ i.descripcion }}</td>
            <td>{{ i.unidad_medida || '-' }}</td>
            <td>{{ i.frecuencia || '-' }}</td>
            <td class="actions-cell">
              <button type="button" class="btn-action btn-action-editar" @click="openEdit(i)"><IconEdit class="btn-icon-sm" /> Editar</button>
              <button type="button" class="btn-action-danger" @click="remove(i.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal modal-wide">
        <h2>{{ editingId !== null ? 'Editar' : 'Nuevo' }} indicador</h2>
        <form @submit.prevent="save">
          <label>Proyecto</label>
          <select v-model="form.proyecto" required>
            <option :value="null">Seleccionar</option>
            <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
          </select>
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Ej: Cantidad de participantes" rows="2" />
          <label>Unidad de medida</label>
          <input v-model="form.unidad_medida" placeholder="Ej: Cantidad, Porcentaje, Índice" />
          <label>Frecuencia</label>
          <select v-model="form.frecuencia">
            <option value="">Seleccionar</option>
            <option value="Mensual">Mensual</option>
            <option value="Trimestral">Trimestral</option>
            <option value="Semestral">Semestral</option>
            <option value="Anual">Anual</option>
          </select>
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
.search-input { flex: 1; min-width: 180px; padding: 0.5rem 0.75rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.select-filter { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; min-width: 220px; }
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.btn-secondary { background: #16a34a; color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; font-size: 0.9rem; }
.btn-secondary:disabled { background: #94a3b8; cursor: not-allowed; }
.btn-primary { background: #3b82f6; color: white; border: none; padding: 0.5rem 1rem; border-radius: 6px; cursor: pointer; }
.table { width: 100%; background: white; border-radius: 8px; overflow: hidden; }
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.table th { background: #f8fafc; }
.desc-cell { max-width: 300px; }
.page .btn-action, .page .btn-action-danger { margin-right: 0.5rem; }
.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 100; }
.modal { background: white; padding: 1.5rem; border-radius: 10px; max-width: 420px; width: 90%; }
.modal-wide { max-width: 480px; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
</style>
