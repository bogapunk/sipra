<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getDashboard } from '@/services/dashboard'

const data = ref<Record<string, unknown> | null>(null)

onMounted(async () => {
  try {
    const res = await getDashboard()
    data.value = res.data
  } catch (e) {
    data.value = null
  }
})
</script>

<template>
  <div class="dashboard">
    <h1>Dashboard Ejecutivo</h1>
    <div v-if="data" class="kpi-grid">
      <div class="kpi-card">
        <span class="kpi-value">{{ data.total_proyectos }}</span>
        <span class="kpi-label">Total Proyectos</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-value">{{ data.proyectos_activos }}</span>
        <span class="kpi-label">Proyectos Activos</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-value">{{ data.total_tareas }}</span>
        <span class="kpi-label">Total Tareas</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-value">{{ data.tareas_finalizadas }}</span>
        <span class="kpi-label">Tareas Finalizadas</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-value">{{ data.tareas_bloqueadas }}</span>
        <span class="kpi-label">Tareas Bloqueadas</span>
      </div>
      <div class="kpi-card accent">
        <span class="kpi-value">{{ data.avance_global }}%</span>
        <span class="kpi-label">Avance Global</span>
      </div>
    </div>
    <p v-else class="loading">Cargando datos del dashboard...</p>
  </div>
</template>

<style scoped>
.dashboard h1 {
  margin-bottom: 1.5rem;
  color: #1e293b;
}
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 1rem;
}
.kpi-card {
  background: white;
  padding: 1.25rem;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.kpi-card.accent {
  background: #3b82f6;
  color: white;
}
.kpi-value {
  font-size: 1.75rem;
  font-weight: 700;
}
.kpi-label {
  font-size: 0.875rem;
  color: #64748b;
}
.kpi-card.accent .kpi-label {
  color: rgba(255,255,255,0.9);
}
.loading {
  color: #64748b;
}
</style>
