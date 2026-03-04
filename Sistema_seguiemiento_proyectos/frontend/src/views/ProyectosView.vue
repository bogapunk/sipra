<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '@/services/api'

const proyectos = ref<Record<string, unknown>[]>([])
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({
  nombre: '',
  descripcion: '',
  fecha_inicio: '',
  fecha_fin_estimada: '',
  estado: 'Activo',
  creado_por: 1,
})
const usuarios = ref<Record<string, unknown>[]>([])

const load = async () => {
  const [p, u] = await Promise.all([
    api.get('proyectos/'),
    api.get('usuarios/'),
  ])
  proyectos.value = p.data
  usuarios.value = u.data
  if (usuarios.value.length && !form.value.creado_por) {
    form.value.creado_por = (usuarios.value[0] as Record<string, unknown>).id as number
  }
}

const openCreate = () => {
  editingId.value = null
  form.value = {
    nombre: '',
    descripcion: '',
    fecha_inicio: '',
    fecha_fin_estimada: '',
    estado: 'Activo',
    creado_por: usuarios.value?.length ? (usuarios.value[0] as Record<string, unknown>).id as number : 1,
  }
  showForm.value = true
}

const openEdit = (p: Record<string, unknown>) => {
  editingId.value = p.id as number
  form.value = {
    nombre: (p.nombre as string) || '',
    descripcion: (p.descripcion as string) || '',
    fecha_inicio: (p.fecha_inicio as string) || '',
    fecha_fin_estimada: (p.fecha_fin_estimada as string) || '',
    estado: (p.estado as string) || 'Activo',
    creado_por: p.creado_por as number,
  }
  showForm.value = true
}

const save = async () => {
  if (editingId.value) {
    await api.patch(`proyectos/${editingId.value}/`, form.value)
  } else {
    await api.post('proyectos/', form.value)
  }
  showForm.value = false
  load()
}

const remove = async (id: number) => {
  if (confirm('¿Eliminar proyecto?')) {
    await api.delete(`proyectos/${id}/`)
    load()
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Proyectos</h1>
    <button class="btn-primary" @click="openCreate">Nuevo proyecto</button>

    <table class="table">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Estado</th>
          <th>Avance</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="p in proyectos" :key="(p.id as number)">
          <td>
            <router-link :to="`/proyectos/${p.id}`">{{ p.nombre }}</router-link>
          </td>
          <td>{{ p.estado }}</td>
          <td>{{ p.porcentaje_avance }}%</td>
          <td>
            <button class="btn-sm" @click="openEdit(p)">Editar</button>
            <button class="btn-sm btn-danger" @click="remove(p.id as number)">Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nuevo' }} proyecto</h2>
        <form @submit.prevent="save">
          <label>Nombre</label>
          <input v-model="form.nombre" placeholder="Nombre" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="3" />
          <label>Fecha inicio</label>
          <input v-model="form.fecha_inicio" type="date" required />
          <label>Fecha fin estimada</label>
          <input v-model="form.fecha_fin_estimada" type="date" required />
          <label>Estado</label>
          <select v-model="form.estado">
            <option value="Activo">Activo</option>
            <option value="En pausa">En pausa</option>
            <option value="Finalizado">Finalizado</option>
          </select>
          <label>Creado por</label>
          <select v-model="form.creado_por">
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">
              {{ u.nombre }}
            </option>
          </select>
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
.btn-primary {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  margin-bottom: 1rem;
  cursor: pointer;
}
.table {
  width: 100%;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.table th { background: #f8fafc; font-weight: 600; }
.table tbody tr:nth-child(even) { background: #f8fafc; }
.btn-sm {
  padding: 0.25rem 0.5rem;
  margin-right: 0.25rem;
  border-radius: 4px;
  border: 1px solid #e2e8f0;
  cursor: pointer;
}
.btn-danger { color: #dc2626; border-color: #fecaca; }
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
.modal h2 { margin-bottom: 1rem; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.modal-actions { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
a { color: #3b82f6; text-decoration: none; }
a:hover { text-decoration: underline; }
</style>
