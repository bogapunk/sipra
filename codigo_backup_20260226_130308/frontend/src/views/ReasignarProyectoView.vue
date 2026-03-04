<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'

type TipoDestino = 'area' | 'secretaria'

const route = useRoute()
const toast = useToast()
const router = useRouter()
const { user } = useAuth()

const proyectoId = computed(() => Number(route.params.id))
const proyecto = ref<Record<string, unknown> | null>(null)
const areas = ref<Record<string, unknown>[]>([])
const secretarias = ref<Record<string, unknown>[]>([])
const tipoDestino = ref<TipoDestino>('area')

const areasActuales = ref<number[]>([])
const areasSeleccionadas = ref<number[]>([])
const secretariaActual = ref<number | null>(null)
const secretariaSeleccionada = ref<number | null>(null)

const motivo = ref('')
const guardando = ref(false)
const error = ref('')

onMounted(async () => {
  try {
    const [proyRes, areasRes, secretariasRes, paRes] = await Promise.all([
      api.get(`proyectos/${proyectoId.value}/`),
      api.get('areas/'),
      api.get('secretarias/'),
      api.get('proyecto-area/', { params: { proyecto: proyectoId.value } }),
    ])
    proyecto.value = proyRes.data
    areas.value = areasRes.data || []
    secretarias.value = Array.isArray(secretariasRes.data) ? secretariasRes.data : []
    const paList = paRes.data || []
    areasActuales.value = paList.map((pa: Record<string, unknown>) => pa.area as number)
    areasSeleccionadas.value = [...areasActuales.value]
    const sec = proyecto.value?.secretaria
    const secId = sec != null && typeof sec === 'object' && !Array.isArray(sec) ? (sec as { id?: number }).id : sec
    secretariaActual.value = secId != null ? Number(secId) : null
    secretariaSeleccionada.value = secretariaActual.value
  } catch {
    error.value = 'Error al cargar los datos.'
  }
})

const areaNombre = (id: number) => {
  const a = areas.value.find((x) => (x.id as number) === id)
  return (a?.nombre as string) || `Área ${id}`
}

const secretariaNombre = (id: number | null) => {
  if (id == null) return null
  const s = secretarias.value.find((x) => (x.id as number) === id)
  return (s?.nombre as string) || `Secretaría ${id}`
}

async function guardar() {
  if (!proyecto.value || !user.value) return
  guardando.value = true
  error.value = ''
  try {
    if (tipoDestino.value === 'area') {
      if (!areasSeleccionadas.value.length) {
        alert('Seleccione al menos un área.')
        guardando.value = false
        return
      }
      const paActuales = (await api.get('proyecto-area/', { params: { proyecto: proyectoId.value } })).data
      for (const pa of paActuales) {
        await api.delete(`proyecto-area/${pa.id}/`)
      }
      for (const areaId of areasSeleccionadas.value) {
        await api.post('proyecto-area/', { proyecto: proyectoId.value, area: areaId })
      }
      if (motivo.value.trim()) {
        const textoMotivo = `Reasignación de áreas: ${areasSeleccionadas.value.map(areaNombre).join(', ')}. Motivo: ${motivo.value.trim()}`
        await api.post('comentarios-proyecto/', {
          proyecto: proyectoId.value,
          usuario: user.value.id,
          texto: textoMotivo,
        })
      }
    } else {
      await api.patch(`proyectos/${proyectoId.value}/`, {
        secretaria: secretariaSeleccionada.value,
      })
      if (motivo.value.trim()) {
        const secNombre = secretariaNombre(secretariaSeleccionada.value) || 'Sin secretaría'
        const textoMotivo = `Reasignación a secretaría: ${secNombre}. Motivo: ${motivo.value.trim()}`
        await api.post('comentarios-proyecto/', {
          proyecto: proyectoId.value,
          usuario: user.value.id,
          texto: textoMotivo,
        })
      }
    }
    toast.success('La reasignación fue guardada con éxito.')
    router.push(`/proyectos/${proyectoId.value}`)
  } catch {
    error.value = 'Error al guardar la reasignación.'
    toast.error('Error al guardar la reasignación.')
  } finally {
    guardando.value = false
  }
}

function toggleArea(id: number) {
  const idx = areasSeleccionadas.value.indexOf(id)
  if (idx >= 0) {
    areasSeleccionadas.value = areasSeleccionadas.value.filter((x) => x !== id)
  } else {
    areasSeleccionadas.value = [...areasSeleccionadas.value, id]
  }
}

function volver() {
  router.push(`/proyectos/${proyectoId.value}`)
}

const secretariasActivas = computed(() =>
  secretarias.value.filter((s: Record<string, unknown>) => s.activa !== false)
)
</script>

<template>
  <div class="page reasignar-page">
    <div v-if="error" class="error-msg">{{ error }}</div>

    <template v-if="proyecto">
      <header class="page-header">
        <div class="header-content">
          <h1>Reasignar proyecto</h1>
          <p class="proyecto-nombre">{{ proyecto.nombre }}</p>
          <p class="header-hint">
            El proyecto puede ser reasignado tanto a un <strong>Área</strong> como a una <strong>Secretaría</strong>.
            Seleccione el tipo de destino y complete la reasignación.
          </p>
        </div>
      </header>

      <div class="content-grid">
        <section class="card card-full">
          <h2 class="card-title">
            <span class="card-icon">🎯</span>
            Tipo de destino
          </h2>
          <div class="tipo-selector">
            <label class="tipo-option" :class="{ active: tipoDestino === 'area' }">
              <input type="radio" value="area" v-model="tipoDestino" />
              <span>Área</span>
            </label>
            <label class="tipo-option" :class="{ active: tipoDestino === 'secretaria' }">
              <input type="radio" value="secretaria" v-model="tipoDestino" />
              <span>Secretaría</span>
            </label>
          </div>
        </section>

        <template v-if="tipoDestino === 'area'">
          <section class="card">
            <h2 class="card-title">
              <span class="card-icon">📋</span>
              Áreas asignadas actualmente
            </h2>
            <div v-if="areasActuales.length" class="areas-tags">
              <span v-for="id in areasActuales" :key="id" class="tag">{{ areaNombre(id) }}</span>
            </div>
            <p v-else class="sin-areas">El proyecto no tiene áreas asignadas.</p>
          </section>

          <section class="card">
            <h2 class="card-title">
              <span class="card-icon">✓</span>
              Seleccione las áreas para el proyecto
            </h2>
            <div class="areas-grid">
              <label
                v-for="a in areas"
                :key="(a.id as number)"
                class="area-check"
                :class="{ checked: areasSeleccionadas.includes(a.id as number) }"
              >
                <input
                  type="checkbox"
                  :value="a.id"
                  :checked="areasSeleccionadas.includes(a.id as number)"
                  @change="toggleArea(a.id as number)"
                />
                <span class="area-label">{{ a.nombre }}</span>
              </label>
            </div>
          </section>
        </template>

        <template v-else>
          <section class="card">
            <h2 class="card-title">
              <span class="card-icon">📋</span>
              Secretaría asignada actualmente
            </h2>
            <p v-if="secretariaActual != null" class="tag tag-secretaria">{{ secretariaNombre(secretariaActual) }}</p>
            <p v-else class="sin-areas">El proyecto no tiene secretaría asignada.</p>
          </section>

          <section class="card">
            <h2 class="card-title">
              <span class="card-icon">✓</span>
              Seleccione la secretaría para el proyecto
            </h2>
            <div class="secretaria-select-wrapper">
              <select v-model.number="secretariaSeleccionada" class="secretaria-select">
                <option :value="null">— Sin secretaría —</option>
                <option
                  v-for="s in secretariasActivas"
                  :key="(s.id as number)"
                  :value="s.id as number"
                >
                  {{ s.nombre }}
                </option>
              </select>
            </div>
          </section>
        </template>

        <section class="card card-full">
          <h2 class="card-title">
            <span class="card-icon">📝</span>
            Motivo de la reasignación
          </h2>
          <textarea
            v-model="motivo"
            placeholder="Indique el motivo de la reasignación (ej: reorganización de cargas, cambio de prioridades, etc.)"
            rows="4"
            class="motivo-input"
          />
        </section>
      </div>

      <div class="actions">
        <button type="button" class="btn-primary" @click="guardar" :disabled="guardando">
          {{ guardando ? 'Guardando...' : 'Guardar reasignación' }}
        </button>
        <button type="button" class="btn-cancel" @click="volver">Cancelar</button>
      </div>
    </template>

    <p v-else-if="!error" class="loading">Cargando...</p>
  </div>
</template>

<style scoped>
.reasignar-page {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 1rem;
}
.page-header {
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #e2e8f0;
}
.header-content h1 {
  font-size: 1.5rem;
  margin: 0 0 0.5rem;
  color: #1e293b;
  font-weight: 600;
}
.proyecto-nombre {
  font-size: 1.1rem;
  color: #64748b;
  margin: 0 0 0.5rem;
}
.header-hint {
  font-size: 0.9rem;
  color: #64748b;
  margin: 0;
  line-height: 1.5;
}
.content-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}
.card {
  background: white;
  border-radius: 12px;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  border: 1px solid #f1f5f9;
}
.card-full {
  grid-column: 1 / -1;
}
.card-title {
  font-size: 1rem;
  margin: 0 0 1rem;
  color: #334155;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.card-icon {
  font-size: 1.1rem;
  opacity: 0.9;
}
.tipo-selector {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}
.tipo-option {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  background: #fafbfc;
  transition: all 0.2s;
}
.tipo-option:hover {
  border-color: #93c5fd;
}
.tipo-option.active {
  border-color: #3b82f6;
  background: #eff6ff;
}
.tipo-option input {
  margin: 0;
  accent-color: #3b82f6;
}
.areas-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
.tag {
  background: #e0f2fe;
  color: #0369a1;
  padding: 0.35rem 0.75rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
}
.tag-secretaria {
  display: inline-block;
}
.sin-areas {
  color: #94a3b8;
  font-style: italic;
  font-size: 0.9rem;
}
.areas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 0.75rem;
}
.area-check {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  background: #fafbfc;
  transition: all 0.2s;
}
.area-check:hover {
  border-color: #93c5fd;
  background: #f8fafc;
}
.area-check.checked {
  border-color: #3b82f6;
  background: #eff6ff;
}
.area-check input {
  margin: 0;
  width: 18px;
  height: 18px;
  accent-color: #3b82f6;
}
.area-label {
  font-size: 0.95rem;
  font-weight: 500;
  color: #334155;
}
.secretaria-select-wrapper {
  width: 100%;
}
.secretaria-select {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  font-size: 0.95rem;
  background: white;
  cursor: pointer;
  transition: border-color 0.2s;
}
.secretaria-select:focus {
  outline: none;
  border-color: #3b82f6;
}
.motivo-input {
  width: 100%;
  padding: 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 0.95rem;
  resize: vertical;
  transition: border-color 0.2s;
}
.motivo-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}
.actions {
  display: flex;
  gap: 1rem;
  margin-top: 1.5rem;
  flex-wrap: wrap;
}
.btn-primary {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 0.65rem 1.5rem;
  border-radius: 10px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}
.btn-primary:hover:not(:disabled) {
  background: #2563eb;
}
.btn-primary:disabled {
  background: #94a3b8;
  cursor: not-allowed;
}
.btn-cancel {
  background: white;
  color: #475569;
  border: 1px solid #e2e8f0;
  padding: 0.65rem 1.5rem;
  border-radius: 10px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-cancel:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}
.error-msg {
  background: #fef2f2;
  color: #dc2626;
  padding: 0.75rem 1rem;
  border-radius: 10px;
  margin-bottom: 1rem;
  border: 1px solid #fecaca;
}
.loading {
  color: #64748b;
  text-align: center;
  padding: 2rem;
  font-size: 1rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}
@media (max-width: 640px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
  .areas-grid {
    grid-template-columns: 1fr;
  }
}
</style>
