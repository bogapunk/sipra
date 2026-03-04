<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { getProyecto } from '@/services/proyectos'
import { getTareas } from '@/services/tareas'
import { api } from '@/services/api'

const route = useRoute()
const proyecto = ref<Record<string, unknown> | null>(null)
const tareas = ref<Record<string, unknown>[]>([])
const etapas = ref<Record<string, unknown>[]>([])
const showEtapaForm = ref(false)
const etapaForm = ref({ nombre: '', orden: 1 })

const proyectoId = computed(() => Number(route.params.id))

const load = async () => {
  const id = proyectoId.value
  proyecto.value = (await getProyecto(id)).data
  tareas.value = (await getTareas({ proyecto: id })).data
  etapas.value = (await api.get('etapas/', { params: { proyecto: id } })).data
}

const addEtapa = async () => {
  await api.post('etapas/', {
    ...etapaForm.value,
    proyecto: proyectoId.value,
  })
  showEtapaForm.value = false
  etapaForm.value = { nombre: '', orden: etapas.value.length + 1 }
  load()
}

onMounted(load)
</script>

<template>
  <div class="page" v-if="proyecto">
    <h1>{{ proyecto.nombre }}</h1>
    <p class="desc">{{ proyecto.descripcion }}</p>
    <p><strong>Estado:</strong> {{ proyecto.estado }} | <strong>Avance:</strong> {{ proyecto.porcentaje_avance }}%</p>

    <section class="section">
      <h2>Etapas</h2>
      <button class="btn-sm" @click="showEtapaForm = true">Nueva etapa</button>
      <ul class="list">
        <li v-for="e in etapas" :key="(e.id as number)">{{ e.nombre }} (orden: {{ e.orden }})</li>
      </ul>
      <div v-if="showEtapaForm" class="form-inline">
        <input v-model="etapaForm.nombre" placeholder="Nombre etapa" />
        <input v-model.number="etapaForm.orden" type="number" min="1" />
        <button @click="addEtapa">Agregar</button>
        <button @click="showEtapaForm = false">Cancelar</button>
      </div>
    </section>

    <section class="section">
      <h2>Tareas</h2>
      <table class="table">
        <thead>
          <tr>
            <th>Título</th>
            <th>Estado</th>
            <th>Avance</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="t in tareas" :key="(t.id as number)">
            <td>{{ t.titulo }}</td>
            <td>{{ t.estado }}</td>
            <td>{{ t.porcentaje_avance }}%</td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 0.5rem; }
.desc { color: #64748b; margin-bottom: 1rem; }
.section { margin-top: 1.5rem; }
.section h2 { font-size: 1rem; margin-bottom: 0.5rem; }
.list { list-style: none; }
.list li { padding: 0.25rem 0; }
.form-inline { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
.table { width: 100%; border-collapse: collapse; }
.table th, .table td { padding: 0.5rem; text-align: left; }
.btn-sm { padding: 0.25rem 0.5rem; margin-bottom: 0.5rem; cursor: pointer; }
</style>
