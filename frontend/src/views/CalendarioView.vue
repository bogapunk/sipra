<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import LoaderSpinner from '@/components/LoaderSpinner.vue'

const router = useRouter()
const { isAdmin, isVisualizador, isCarga, user } = useAuth()
const tareas = ref<Record<string, unknown>[]>([])
const carga = ref(true)
const mesActual = ref(new Date())

const anio = computed(() => mesActual.value.getFullYear())
const mes = computed(() => mesActual.value.getMonth())

const diasDelMes = computed(() => {
  const year = anio.value
  const month = mes.value
  const primerDia = new Date(year, month, 1)
  const ultimoDia = new Date(year, month + 1, 0)
  const dias: { fecha: Date; dia: number; esHoy: boolean; esOtroMes: boolean }[] = []
  const inicioSemana = primerDia.getDay()
  const diasAntes = inicioSemana === 0 ? 6 : inicioSemana - 1
  for (let i = 0; i < diasAntes; i++) {
    const d = new Date(year, month, -diasAntes + i + 1)
    dias.push({ fecha: d, dia: d.getDate(), esHoy: false, esOtroMes: true })
  }
  for (let d = 1; d <= ultimoDia.getDate(); d++) {
    const fecha = new Date(year, month, d)
    const hoy = new Date()
    dias.push({
      fecha,
      dia: d,
      esHoy: fecha.toDateString() === hoy.toDateString(),
      esOtroMes: false,
    })
  }
  const sobrantes = 42 - dias.length
  for (let i = 1; i <= sobrantes; i++) {
    const d = new Date(year, month + 1, i)
    dias.push({ fecha: d, dia: d.getDate(), esHoy: false, esOtroMes: true })
  }
  return dias
})

const tareasPorFecha = computed(() => {
  const map = new Map<string, Record<string, unknown>[]>()
  for (const t of tareas.value) {
    const fv = t.fecha_vencimiento as string
    if (!fv) continue
    const key = fv.slice(0, 10)
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(t)
  }
  return map
})

function tareasDelDia(fecha: Date): Record<string, unknown>[] {
  const key = fecha.getFullYear() + '-' + String(fecha.getMonth() + 1).padStart(2, '0') + '-' + String(fecha.getDate()).padStart(2, '0')
  return tareasPorFecha.value.get(key) || []
}

function mesAnterior() {
  mesActual.value = new Date(anio.value, mes.value - 1)
}

function mesSiguiente() {
  mesActual.value = new Date(anio.value, mes.value + 1)
}

function irATarea(t: Record<string, unknown>) {
  if (t.proyecto) {
    router.push(`/proyectos/${t.proyecto}`)
  } else {
    router.push('/tareas')
  }
}

const nombresMeses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
const nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']

async function load() {
  carga.value = true
  try {
    const params: Record<string, string | number> = {}
    if (isCarga.value && user.value) {
      params.usuario = user.value.id
    }
    const res = await api.get('tareas/', { params })
    tareas.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
  } catch {
    tareas.value = []
  } finally {
    carga.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Calendario de tareas</h1>
    <p class="subtitle">Vista mensual por fecha de vencimiento</p>

    <LoaderSpinner v-if="carga" texto="Cargando tareas..." />

    <div v-else class="calendario-wrapper">
      <div class="calendario-header">
        <button type="button" class="btn-nav" @click="mesAnterior">←</button>
        <h2 class="mes-titulo">{{ nombresMeses[mes] }} {{ anio }}</h2>
        <button type="button" class="btn-nav" @click="mesSiguiente">→</button>
      </div>

      <div class="calendario-grid">
        <div v-for="d in nombresDias" :key="d" class="calendario-dia-header">{{ d }}</div>
        <div
          v-for="(celda, idx) in diasDelMes"
          :key="idx"
          class="calendario-celda"
          :class="{
            'celda-otro-mes': celda.esOtroMes,
            'celda-hoy': celda.esHoy,
          }"
        >
          <span class="celda-numero">{{ celda.dia }}</span>
          <div class="celda-tareas">
            <button
              v-for="t in tareasDelDia(celda.fecha).slice(0, 3)"
              :key="(t.id as number)"
              type="button"
              class="tarea-mini"
              :class="claseVencimiento(estadoVencimiento(t.fecha_vencimiento, t.estado))"
              :title="(t.titulo as string) || ''"
              @click="irATarea(t)"
            >
              {{ (t.titulo as string)?.slice(0, 20) || 'Tarea' }}{{ (t.titulo as string)?.length > 20 ? '…' : '' }}
            </button>
            <span v-if="tareasDelDia(celda.fecha).length > 3" class="tarea-mas">
              +{{ tareasDelDia(celda.fecha).length - 3 }} más
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 0.5rem; }
.subtitle { color: #64748b; margin-bottom: 1rem; }
.calendario-wrapper {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.calendario-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}
.btn-nav {
  padding: 0.5rem 1rem;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1rem;
}
.btn-nav:hover { background: #e2e8f0; }
.mes-titulo { margin: 0; font-size: 1.25rem; color: #1e293b; }
.calendario-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background: #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}
.calendario-dia-header {
  padding: 0.5rem;
  background: #64748b;
  color: white;
  font-size: 0.8rem;
  font-weight: 600;
  text-align: center;
}
.calendario-celda {
  min-height: 100px;
  background: white;
  padding: 0.5rem;
  display: flex;
  flex-direction: column;
}
.celda-otro-mes { background: #f8fafc; }
.celda-otro-mes .celda-numero { color: #94a3b8; }
.celda-hoy { background: #eff6ff; }
.celda-numero {
  font-size: 0.9rem;
  font-weight: 600;
  color: #334155;
  margin-bottom: 0.35rem;
}
.celda-tareas {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
  overflow: hidden;
}
.tarea-mini {
  font-size: 0.7rem;
  padding: 0.2rem 0.4rem;
  text-align: left;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  background: #e2e8f0;
  color: #334155;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tarea-mini:hover { background: #cbd5e1; }
.tarea-mini.vencimiento-vencida { background: #fecaca; color: #991b1b; }
.tarea-mini.vencimiento-proxima { background: #fef08a; color: #854d0e; }
.tarea-mini.vencimiento-dentro-plazo { background: #bbf7d0; color: #166534; }
.tarea-mas { font-size: 0.7rem; color: #64748b; }
</style>
