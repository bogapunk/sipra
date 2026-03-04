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
const objetivos = ref<Record<string, unknown>[]>([])
const programas = ref<Record<string, unknown>[]>([])
const buscar = ref('')
const filtroPrograma = ref<string | ''>('')
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({ programa: null as string | null, descripcion: '' })

const filtrados = computed(() => {
  let lista = objetivos.value
  if (filtroPrograma.value !== '') {
    lista = lista.filter((o: Record<string, unknown>) => String(o.programa) === String(filtroPrograma.value))
  }
  const q = buscar.value.trim().toLowerCase()
  if (q) lista = lista.filter((o: Record<string, unknown>) =>
    String(o.descripcion || '').toLowerCase().includes(q)
  )
  return lista
})

async function descargarExcel() {
  const headers = ['ID', 'Programa', 'Descripción']
  const rows = filtrados.value.map((o: Record<string, unknown>) => [
    String(o.id ?? ''),
    String(o.programa_nombre || ''),
    String((o.descripcion || '').toString().slice(0, 120)),
  ])
  await exportToCsv(headers, rows, `objetivos_${new Date().toISOString().slice(0, 10)}.csv`)
}

const load = async () => {
  const [oRes, pRes] = await Promise.all([api.get('objetivos-estrategicos/'), api.get('programas/')])
  objetivos.value = Array.isArray(oRes.data) ? oRes.data : (oRes.data?.results || [])
  programas.value = Array.isArray(pRes.data) ? pRes.data : (pRes.data?.results || [])
}

const openCreate = () => {
  editingId.value = null
  form.value = {
    programa: programas.value[0] ? (programas.value[0] as Record<string, unknown>).id_programa as string : null,
    descripcion: '',
  }
  showForm.value = true
}

const openEdit = (o: Record<string, unknown>) => {
  editingId.value = o.id as number
  form.value = {
    programa: o.programa as string,
    descripcion: (o.descripcion as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  try {
    const payload = { programa: form.value.programa, descripcion: form.value.descripcion }
    if (editingId.value !== null) {
      await api.patch(`objetivos-estrategicos/${editingId.value}/`, payload)
      toast.success('Objetivo actualizado correctamente.')
    } else {
      await api.post('objetivos-estrategicos/', payload)
      toast.success('Objetivo creado correctamente.')
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
      await api.delete(`objetivos-estrategicos/${id}/`)
      toast.success('Eliminado correctamente.')
      load()
    } catch {
      toast.error('Error al eliminar. Verifique que no tenga proyectos asociados.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Objetivos estratégicos</h1>
    <div class="toolbar">
      <input v-model="buscar" type="search" placeholder="Buscar por descripción..." class="search-input" />
      <select v-model="filtroPrograma" class="select-filter">
        <option value="">Todos los programas</option>
        <option v-for="p in programas" :key="(p.id_programa as string)" :value="p.id_programa">{{ p.id_programa }} - {{ p.nombre_programa }}</option>
      </select>
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!filtrados.length">
          <IconDownload class="btn-icon" /> Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" /> Nuevo objetivo
        </button>
      </div>
    </div>

    <table class="table">
      <thead>
        <tr>
          <th>Programa</th>
          <th>Descripción</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="o in filtrados" :key="(o.id as number)">
          <td>{{ o.programa_nombre }}</td>
          <td class="desc-cell">{{ o.descripcion }}</td>
          <td class="actions-cell">
            <button class="btn-action" @click="openEdit(o)"><IconEdit class="btn-icon-sm" /> Editar</button>
            <button class="btn-action-danger" @click="remove(o.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal modal-wide">
        <h2>{{ editingId !== null ? 'Editar' : 'Nuevo' }} objetivo estratégico</h2>
        <form @submit.prevent="save">
          <label>Programa</label>
          <select v-model="form.programa" required>
            <option :value="null">Seleccionar</option>
            <option v-for="p in programas" :key="(p.id_programa as string)" :value="p.id_programa">{{ p.id_programa }} - {{ p.nombre_programa }}</option>
          </select>
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción del objetivo" rows="4" required />
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
.select-filter { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; min-width: 280px; }
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; }
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
.modal select, .modal textarea { padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
</style>
