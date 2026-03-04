<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { getProyecto } from '@/services/proyectos'
import { getTareas } from '@/services/tareas'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'

const route = useRoute()
const toast = useToast()
const { isVisualizador } = useAuth()
const proyecto = ref<Record<string, unknown> | null>(null)
const tareas = ref<Record<string, unknown>[]>([])
const etapas = ref<Record<string, unknown>[]>([])
const indicadores = ref<Record<string, unknown>[]>([])
const showEtapaForm = ref(false)
const showIndicadorForm = ref(false)
const etapaForm = ref({ nombre: '', orden: 1 })
const indicadorForm = ref({ descripcion: '', unidad_medida: '', frecuencia: '' })

const proyectoId = computed(() => Number(route.params.id))

const load = async () => {
  const id = proyectoId.value
  proyecto.value = (await getProyecto(id)).data
  tareas.value = (await getTareas({ proyecto: id })).data
  etapas.value = (await api.get('etapas/', { params: { proyecto: id } })).data
  const indRes = await api.get('indicadores/', { params: { proyecto: id } })
  indicadores.value = Array.isArray(indRes.data) ? indRes.data : (indRes.data?.results || [])
}

const addEtapa = async () => {
  try {
    await api.post('etapas/', {
      ...etapaForm.value,
      proyecto: proyectoId.value,
    })
    toast.success('Etapa creada correctamente.')
    showEtapaForm.value = false
    etapaForm.value = { nombre: '', orden: etapas.value.length + 1 }
    load()
  } catch {
    toast.error('Error al crear la etapa.')
  }
}

const addIndicador = async () => {
  try {
    await api.post('indicadores/', {
      ...indicadorForm.value,
      proyecto: proyectoId.value,
    })
    toast.success('Indicador creado correctamente.')
    showIndicadorForm.value = false
    indicadorForm.value = { descripcion: '', unidad_medida: '', frecuencia: '' }
    load()
  } catch {
    toast.error('Error al crear el indicador.')
  }
}

const removeIndicador = async (id: number) => {
  if (confirm('¿Eliminar este indicador?')) {
    try {
      await api.delete(`indicadores/${id}/`)
      toast.success('Indicador eliminado.')
      load()
    } catch {
      toast.error('Error al eliminar.')
    }
  }
}

onMounted(load)
</script>

<template>
  <div class="page" v-if="proyecto">
    <div class="header-row">
      <h1>{{ proyecto.nombre }}</h1>
      <router-link :to="`/proyectos/${proyectoId}/reasignar`" class="btn-reasignar">
        Reasignar Proyecto
      </router-link>
    </div>
    <p class="desc">{{ proyecto.descripcion }}</p>
    <p><strong>Estado:</strong> {{ proyecto.estado }} | <strong>Avance:</strong> {{ proyecto.porcentaje_avance }}%</p>

    <section class="section">
      <h2>Etapas</h2>
      <button v-if="!isVisualizador" class="btn-primary" @click="showEtapaForm = true">Nueva etapa</button>
      <ul class="list">
        <li v-for="e in etapas" :key="(e.id as number)">{{ e.nombre }} (orden: {{ e.orden }})</li>
      </ul>
      <div v-if="showEtapaForm && !isVisualizador" class="form-inline">
        <input v-model="etapaForm.nombre" placeholder="Nombre etapa" />
        <input v-model.number="etapaForm.orden" type="number" min="1" />
        <button type="button" class="btn-primary" @click="addEtapa">Agregar</button>
        <button type="button" class="btn-cancel" @click="showEtapaForm = false">Cancelar</button>
      </div>
    </section>

    <section class="section">
      <h2>Indicadores</h2>
      <button v-if="!isVisualizador" class="btn-primary" @click="showIndicadorForm = true">Nuevo indicador</button>
      <ul v-if="indicadores.length" class="list indicadores-list">
        <li v-for="i in indicadores" :key="(i.id as number)" class="indicador-item">
          <span>{{ i.descripcion }}</span>
          <span class="meta">{{ i.unidad_medida }} · {{ i.frecuencia }}</span>
          <button v-if="!isVisualizador" type="button" class="btn-small-danger" @click="removeIndicador(i.id as number)">Eliminar</button>
        </li>
      </ul>
      <p v-else class="hint">Sin indicadores. Agregue indicadores de seguimiento para este proyecto.</p>
      <div v-if="showIndicadorForm && !isVisualizador" class="form-inline form-block">
        <input v-model="indicadorForm.descripcion" placeholder="Descripción (ej: Cantidad de participantes)" />
        <input v-model="indicadorForm.unidad_medida" placeholder="Unidad (ej: Cantidad)" />
        <select v-model="indicadorForm.frecuencia">
          <option value="">Frecuencia</option>
          <option value="Mensual">Mensual</option>
          <option value="Trimestral">Trimestral</option>
          <option value="Semestral">Semestral</option>
          <option value="Anual">Anual</option>
        </select>
        <button type="button" class="btn-primary" @click="addIndicador">Agregar</button>
        <button type="button" class="btn-cancel" @click="showIndicadorForm = false">Cancelar</button>
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
.header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
}
.page h1 { margin: 0; }
.btn-reasignar {
  padding: 0.5rem 1rem;
  background: #16a34a;
  color: white;
  border-radius: 8px;
  text-decoration: none;
  font-size: 0.9rem;
}
.btn-reasignar:hover {
  background: #15803d;
}
.desc { color: #64748b; margin-bottom: 1rem; }
.section { margin-top: 1.5rem; }
.section h2 { font-size: 1rem; margin-bottom: 0.5rem; }
.list { list-style: none; }
.list li { padding: 0.25rem 0; }
.form-inline { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
.table { width: 100%; border-collapse: collapse; }
.table th, .table td { padding: 0.5rem; text-align: left; }
.section .btn-primary {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  margin-bottom: 0.5rem;
}
.indicadores-list { list-style: none; padding: 0; }
.indicador-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid #e2e8f0;
}
.indicador-item .meta { color: #64748b; font-size: 0.9rem; }
.btn-small-danger {
  margin-left: auto;
  padding: 0.25rem 0.5rem;
  font-size: 0.8rem;
  background: #fee2e2;
  color: #dc2626;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.form-block { flex-wrap: wrap; }
.hint { color: #94a3b8; font-size: 0.9rem; }
</style>
