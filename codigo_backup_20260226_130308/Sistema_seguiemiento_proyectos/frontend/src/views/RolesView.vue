<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '@/services/api'

const roles = ref<Record<string, unknown>[]>([])
const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = ref({ nombre: '', descripcion: '' })

const load = async () => {
  roles.value = (await api.get('roles/')).data
}

const openCreate = () => {
  editingId.value = null
  form.value = { nombre: '', descripcion: '' }
  showForm.value = true
}

const openEdit = (r: Record<string, unknown>) => {
  editingId.value = r.id as number
  form.value = {
    nombre: (r.nombre as string) || '',
    descripcion: (r.descripcion as string) || '',
  }
  showForm.value = true
}

const save = async () => {
  if (editingId.value) {
    await api.patch(`roles/${editingId.value}/`, form.value)
  } else {
    await api.post('roles/', form.value)
  }
  showForm.value = false
  load()
}

const remove = async (id: number) => {
  if (confirm('¿Eliminar rol?')) {
    await api.delete(`roles/${id}/`)
    load()
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Roles</h1>
    <button class="btn-primary" @click="openCreate">Nuevo rol</button>

    <table class="table">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Descripción</th>
          <th>Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in roles" :key="(r.id as number)">
          <td>{{ r.nombre }}</td>
          <td>{{ r.descripcion }}</td>
          <td>
            <button class="btn-sm" @click="openEdit(r)">Editar</button>
            <button class="btn-sm btn-danger" @click="remove(r.id as number)">Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nuevo' }} rol</h2>
        <form @submit.prevent="save">
          <label>Nombre</label>
          <input v-model="form.nombre" placeholder="Nombre" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="3" />
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
.modal input, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.modal-actions { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
</style>
