<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '@/services/api'

const tareas = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const areas = ref<Record<string, unknown>[]>([])
const usuarios = ref<Record<string, unknown>[]>([])
const showForm = ref(false)
const editingId = ref<number | null>(null)
const filtroEstado = ref('')
const form = ref({
  proyecto: null as number | null,
  etapa: null as number | null,
  area: null as number | null,
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
  const [t, p, a, u] = await Promise.all([
    api.get('tareas/', { params }),
    api.get('proyectos/'),
    api.get('areas/'),
    api.get('usuarios/'),
  ])
  tareas.value = t.data
  proyectos.value = p.data
  areas.value = a.data
  usuarios.value = u.data
}

const openCreate = () => {
  editingId.value = null
  form.value = {
    proyecto: null,
    etapa: null,
    area: null,
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
  form.value = {
    proyecto: t.proyecto as number,
    etapa: t.etapa as number | null,
    area: t.area as number,
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

const save = async () => {
  const payload = { ...form.value }
  if (editingId.value) {
    await api.patch(`tareas/${editingId.value}/`, payload)
  } else {
    await api.post('tareas/', payload)
  }
  showForm.value = false
  load()
}

const remove = async (id: number) => {
  if (confirm('¿Eliminar tarea?')) {
    await api.delete(`tareas/${id}/`)
    load()
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Tareas</h1>
    <div class="toolbar">
      <select v-model="filtroEstado" @change="load">
        <option value="">Todos los estados</option>
        <option value="Pendiente">Pendiente</option>
        <option value="En proceso">En proceso</option>
        <option value="Finalizada">Finalizada</option>
        <option value="Bloqueada">Bloqueada</option>
      </select>
      <button class="btn-primary" @click="openCreate">Nueva tarea</button>
    </div>

    <table class="table">
      <thead>
        <tr>
          <th>Título</th>
          <th>Estado</th>
          <th>Avance</th>
          <th>Prioridad</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="t in tareas" :key="(t.id as number)">
          <td>{{ t.titulo }}</td>
          <td>{{ t.estado }}</td>
          <td>{{ t.porcentaje_avance }}%</td>
          <td>{{ t.prioridad }}</td>
          <td>
            <button class="btn-sm" @click="openEdit(t)">Editar</button>
            <button class="btn-sm btn-danger" @click="remove(t.id as number)">Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal modal-wide">
        <h2>{{ editingId ? 'Editar' : 'Nueva' }} tarea</h2>
        <form @submit.prevent="save">
          <label>Título</label>
          <input v-model="form.titulo" placeholder="Título" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="2" />
          <label>Proyecto</label>
          <select v-model="form.proyecto" required>
            <option :value="null">Seleccionar</option>
            <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
          </select>
          <label>Área</label>
          <select v-model="form.area" required>
            <option :value="null">Seleccionar</option>
            <option v-for="a in areas" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
          </select>
          <label>Responsable</label>
          <select v-model="form.responsable" required>
            <option :value="null">Seleccionar</option>
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">{{ u.nombre }}</option>
          </select>
          <div class="row">
            <div>
              <label>Fecha inicio</label>
              <input v-model="form.fecha_inicio" type="date" required />
            </div>
            <div>
              <label>Fecha vencimiento</label>
              <input v-model="form.fecha_vencimiento" type="date" required />
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
            <div>
              <label>Prioridad</label>
              <select v-model="form.prioridad">
                <option value="Baja">Baja</option>
                <option value="Media">Media</option>
                <option value="Alta">Alta</option>
              </select>
            </div>
          </div>
          <div class="modal-actions">
            <button type="submit" class="btn-primary">Guardar</button>
            <button type="button" @click="showForm = false">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 1rem; }
.toolbar { display: flex; gap: 1rem; margin-bottom: 1rem; align-items: center; }
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
.btn-sm { padding: 0.25rem 0.5rem; margin-right: 0.25rem; border-radius: 4px; cursor: pointer; }
.btn-danger { color: #dc2626; border: 1px solid #fecaca; }
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
.row { display: flex; gap: 1rem; }
.row > div { flex: 1; }
.modal-actions { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
</style>
