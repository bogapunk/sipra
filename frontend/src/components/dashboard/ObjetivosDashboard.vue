<script setup lang="ts">
import { computed } from 'vue'
import { use } from 'echarts/core'
import { PieChart } from 'echarts/charts'
import { CanvasRenderer } from 'echarts/renderers'
import { LegendComponent, TooltipComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import type { EChartsOption } from 'echarts'

use([CanvasRenderer, PieChart, LegendComponent, TooltipComponent])

type ObjetivosKpis = {
  objetivos_total?: number
  objetivos_no_iniciados?: number
  objetivos_en_progreso?: number
  objetivos_finalizados?: number
  avance_objetivos?: number
}

type ObjetivoPorEstado = {
  name: string
  value: number
  estado?: string
}

type ObjetivoPorProyecto = {
  id: number
  nombre: string
  total: number
  no_iniciado: number
  en_progreso: number
  finalizado: number
  avance: number
}

const props = withDefaults(
  defineProps<{
    kpis?: ObjetivosKpis | null
    porEstado?: ObjetivoPorEstado[]
    porProyecto?: ObjetivoPorProyecto[]
    maxProyectos?: number
  }>(),
  {
    kpis: null,
    porEstado: () => [],
    porProyecto: () => [],
    maxProyectos: 8,
  },
)

const emit = defineEmits<{ (e: 'select-proyecto', id: number): void }>()

function formatNumber(value: number | string | null | undefined): string {
  const num = Number(value ?? 0)
  return Number.isFinite(num) ? num.toLocaleString('es-CL') : '0'
}

const stats = computed(() => {
  const k = props.kpis || {}
  const total = Number(k.objetivos_total || 0)
  const noIniciados = Number(k.objetivos_no_iniciados || 0)
  const enProgreso = Number(k.objetivos_en_progreso || 0)
  const finalizados = Number(k.objetivos_finalizados || 0)
  const avance = Number(k.avance_objetivos || 0)
  const pct = (n: number) => (total > 0 ? Math.round((n / total) * 100) : 0)
  return {
    total,
    avance,
    cards: [
      { key: 'total', label: 'Objetivos totales', value: total, pct: 100, meta: 'Vinculados al portafolio', tone: 'neutral' },
      { key: 'noiniciado', label: 'No iniciados', value: noIniciados, pct: pct(noIniciados), meta: `${pct(noIniciados)}% del total`, tone: 'muted' },
      { key: 'progreso', label: 'En progreso', value: enProgreso, pct: pct(enProgreso), meta: `${pct(enProgreso)}% del total`, tone: 'warning' },
      { key: 'finalizado', label: 'Finalizados', value: finalizados, pct: pct(finalizados), meta: `${pct(finalizados)}% del total`, tone: 'success' },
    ],
  }
})

const proyectosVisibles = computed(() => (props.porProyecto || []).slice(0, props.maxProyectos))

const chartOption = computed<EChartsOption>(() => ({
  tooltip: {
    trigger: 'item',
    formatter: (params: unknown) => {
      const p = params as { name?: string; value?: number; percent?: number }
      return `${p.name || ''}<br/>${p.value ?? 0} objetivo(s) (${p.percent ?? 0}%)`
    },
  },
  legend: { bottom: 0, icon: 'circle' },
  color: ['#94a3b8', '#f59e0b', '#16a34a'],
  series: [
    {
      name: 'Objetivos',
      type: 'pie',
      radius: ['52%', '74%'],
      center: ['50%', '44%'],
      avoidLabelOverlap: true,
      label: {
        show: true,
        position: 'center',
        formatter: () => `${stats.value.avance}%\nAvance`,
        fontSize: 18,
        fontWeight: 'bold',
        color: '#0f172a',
        lineHeight: 20,
      },
      labelLine: { show: false },
      itemStyle: { borderRadius: 8, borderColor: '#fff', borderWidth: 2 },
      data: (props.porEstado || []).filter((item) => item.value > 0),
    },
  ],
}))

function avanceTone(avance: number): string {
  if (avance >= 100) return 'bar-success'
  if (avance >= 50) return 'bar-progreso'
  if (avance > 0) return 'bar-iniciado'
  return 'bar-muted'
}
</script>

<template>
  <section class="objetivos-panel">
    <div class="objetivos-panel-head">
      <div>
        <h2>Estado de los objetivos</h2>
        <p>Distribucion, avance global y porcentaje por proyecto de los objetivos vinculados.</p>
      </div>
      <span class="objetivos-avance-pill">Avance global: {{ stats.avance }}%</span>
    </div>

    <div v-if="stats.total > 0" class="objetivos-panel-body">
      <div class="objetivos-stats-grid">
        <article
          v-for="card in stats.cards"
          :key="card.key"
          class="objetivo-stat-card"
          :class="`obj-tone-${card.tone}`"
        >
          <span class="objetivo-stat-label">{{ card.label }}</span>
          <strong class="objetivo-stat-value">{{ formatNumber(card.value) }}</strong>
          <div class="objetivo-stat-track">
            <div class="objetivo-stat-fill" :style="{ width: `${card.pct}%` }" />
          </div>
          <span class="objetivo-stat-meta">{{ card.meta }}</span>
        </article>
      </div>
      <div class="objetivos-chart-wrap">
        <VChart autoresize class="chart" :option="chartOption" />
      </div>
    </div>
    <div v-else class="objetivos-empty">No hay objetivos vinculados a los proyectos con los filtros actuales.</div>

    <div v-if="proyectosVisibles.length" class="objetivos-proyectos">
      <div class="objetivos-proyectos-head">
        <h3>Avance de objetivos por proyecto</h3>
        <span class="objetivos-proyectos-sub">Mostrando {{ proyectosVisibles.length }} de {{ (porProyecto || []).length }} proyecto(s) con objetivos</span>
      </div>
      <ul class="objetivos-proyectos-list">
        <li
          v-for="proy in proyectosVisibles"
          :key="proy.id"
          class="objetivo-proyecto-row"
          role="button"
          tabindex="0"
          @click="emit('select-proyecto', proy.id)"
          @keyup.enter="emit('select-proyecto', proy.id)"
        >
          <div class="objetivo-proyecto-info">
            <span class="objetivo-proyecto-nombre">{{ proy.nombre }}</span>
            <div class="objetivo-proyecto-chips">
              <span class="op-chip op-chip-muted" title="No iniciados">{{ proy.no_iniciado }}</span>
              <span class="op-chip op-chip-progreso" title="En progreso">{{ proy.en_progreso }}</span>
              <span class="op-chip op-chip-finalizado" title="Finalizados">{{ proy.finalizado }}</span>
              <span class="op-chip-total" title="Total de objetivos">/ {{ proy.total }}</span>
            </div>
          </div>
          <div class="objetivo-proyecto-bar-wrap">
            <div class="objetivo-proyecto-bar">
              <div class="objetivo-proyecto-fill" :class="avanceTone(proy.avance)" :style="{ width: `${Math.min(100, proy.avance)}%` }" />
            </div>
            <span class="objetivo-proyecto-pct">{{ proy.avance }}%</span>
          </div>
        </li>
      </ul>
    </div>
  </section>
</template>

<style scoped>
.objetivos-panel {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.06);
  padding: 1.1rem 1.25rem 1.35rem;
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
}
.objetivos-panel-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  flex-wrap: wrap;
}
.objetivos-panel-head h2 {
  margin: 0;
  font-size: 1.05rem;
  color: #0f172a;
}
.objetivos-panel-head p {
  margin: 0.25rem 0 0;
  color: #64748b;
  font-size: 0.92rem;
}
.objetivos-avance-pill {
  display: inline-flex;
  align-items: center;
  padding: 0.45rem 0.9rem;
  border-radius: 999px;
  background: #ede9fe;
  color: #6d28d9;
  font-weight: 700;
  font-size: 0.9rem;
  white-space: nowrap;
}
.objetivos-panel-body {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 1.25rem;
  align-items: center;
}
.objetivos-stats-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.9rem;
}
.objetivo-stat-card {
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 0.9rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
}
.objetivo-stat-label {
  font-size: 0.85rem;
  color: #475569;
  font-weight: 600;
}
.objetivo-stat-value {
  font-size: 1.8rem;
  line-height: 1;
  color: #0f172a;
}
.objetivo-stat-track {
  height: 6px;
  border-radius: 999px;
  background: #e2e8f0;
  overflow: hidden;
}
.objetivo-stat-fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.4s ease;
}
.objetivo-stat-meta {
  font-size: 0.8rem;
  color: #64748b;
}
.obj-tone-neutral { border-top: 4px solid #6366f1; }
.obj-tone-neutral .objetivo-stat-fill { background: #6366f1; }
.obj-tone-muted { border-top: 4px solid #94a3b8; }
.obj-tone-muted .objetivo-stat-fill { background: #94a3b8; }
.obj-tone-warning { border-top: 4px solid #f59e0b; }
.obj-tone-warning .objetivo-stat-fill { background: #f59e0b; }
.obj-tone-success { border-top: 4px solid #16a34a; }
.obj-tone-success .objetivo-stat-fill { background: #16a34a; }
.objetivos-chart-wrap {
  height: 260px;
}
.chart {
  width: 100%;
  height: 100%;
}
.objetivos-empty {
  min-height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: #64748b;
}
.objetivos-proyectos {
  border-top: 1px solid #e2e8f0;
  padding-top: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.objetivos-proyectos-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 1rem;
  flex-wrap: wrap;
}
.objetivos-proyectos-head h3 {
  margin: 0;
  font-size: 0.98rem;
  color: #0f172a;
}
.objetivos-proyectos-sub {
  font-size: 0.82rem;
  color: #64748b;
}
.objetivos-proyectos-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.objetivo-proyecto-row {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(180px, 1fr);
  gap: 1rem;
  align-items: center;
  padding: 0.6rem 0.75rem;
  border: 1px solid #eef2f7;
  border-radius: 12px;
  cursor: pointer;
  transition: background 0.15s ease, border-color 0.15s ease;
}
.objetivo-proyecto-row:hover {
  background: #f8fafc;
  border-color: #dbeafe;
}
.objetivo-proyecto-info {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
}
.objetivo-proyecto-nombre {
  font-weight: 600;
  color: #0f172a;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.objetivo-proyecto-chips {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}
.op-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 1.4rem;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 0.05rem 0.35rem;
  border-radius: 999px;
}
.op-chip-muted { background: #f1f5f9; color: #475569; }
.op-chip-progreso { background: #fef9c3; color: #a16207; }
.op-chip-finalizado { background: #dcfce7; color: #15803d; }
.op-chip-total { font-size: 0.72rem; color: #94a3b8; font-weight: 600; }
.objetivo-proyecto-bar-wrap {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}
.objetivo-proyecto-bar {
  flex: 1;
  height: 10px;
  border-radius: 999px;
  background: #eef2f7;
  overflow: hidden;
}
.objetivo-proyecto-fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.4s ease;
}
.bar-muted { background: #cbd5e1; }
.bar-iniciado { background: #38bdf8; }
.bar-progreso { background: #f59e0b; }
.bar-success { background: #16a34a; }
.objetivo-proyecto-pct {
  font-weight: 700;
  color: #334155;
  font-size: 0.85rem;
  min-width: 2.8rem;
  text-align: right;
}
@media (max-width: 1100px) {
  .objetivos-panel-body {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 640px) {
  .objetivo-proyecto-row {
    grid-template-columns: 1fr;
  }
}
</style>
