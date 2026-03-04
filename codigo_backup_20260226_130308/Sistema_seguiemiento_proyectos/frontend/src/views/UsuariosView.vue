<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '@/services/api'

const usuarios = ref<Record<string, unknown>[]>([])
const roles = ref<Record<string, unknown>[]>([])
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({
  nombre: '',
  email: '',
  password: '',
  rol: null as number | null,
  estado: true,
})

const load = async () => {
  const [u, r] = await Promise.all([
    api.get('usuarios/'),
    api.get('roles/'),
  ])
  usuarios.value = u.data
  roles.value = r.data
}

const openCreate = () => {
  editingId.value = null
  form.value = {
    nombre: '',
    email: '',
    password: '',
    rol: null,
    estado: true,
  }
  showForm.value = true
}

const openEdit = (u: Record<string, unknown>) => {
  editingId.value = u.id as number
  form.value = {
    nombre: (u.nombre as string) || '',
    email: (u.email as string) || '',
    password: '',
    rol: u.rol as number,
    estado: u.estado !== false,
  }
  showForm.value = true
}

const save = async () => {
  const payload = { ...form.value }
  if (!payload.password) delete (payload as Record<string, unknown>).password

  if (editingId.value) {
    await api.patch(`usuarios/${editingId.value}/`, payload)
  } else {
    await api.post('usuarios/', payload)
  }
  showForm.value = false
  load()
}

const remove = async (id: number) => {
  if (confirm('¿Eliminar usuario?')) {
    await api.delete(`usuarios/${id}/`)
    load()
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Usuarios</h1>
    <button class="btn-primary" @click="openCreate">Nuevo usuario</button>

    <table class="table">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Email</th>
          <th>Estado</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="u in usuarios" :key="(u.id as number)">
          <td>{{ u.nombre }}</td>
          <td>{{ u.email }}</td>
          <td>{{ u.estado ? 'Activo' : 'Inactivo' }}</td>
          <td>
            <button class="btn-sm" @click="openEdit(u)">Editar</button>
            <button class="btn-sm btn-danger" @click="remove(u.id as number)">Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nuevo' }} usuario</h2>
        <form @submit.prevent="save">
          <label>Nombre</label>
          <input v-model="form.nombre" placeholder="Nombre" required />
          <label>Email</label>
          <input v-model="form.email" type="email" placeholder="Email" required />
          <label>Contraseña</label>
          <input v-model="form.password" type="password" placeholder="Contraseña" :required="!editingId" />
          <label>Rol</label>
          <select v-model="form.rol" required>
            <option :value="null">Seleccionar</option>
            <option v-for="r in roles" :key="(r.id as number)" :value="r.id">{{ r.nombre }}</option>
          </select>
          <label class="checkbox">
            <input v-model="form.estado" type="checkbox" />
            Activo
          </label>
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
}
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.checkbox { display: flex; align-items: center; gap: 0.5rem; }
.modal-actions { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
</style>
