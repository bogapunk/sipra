<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  tareas: Record<string, unknown>[]
  titulo?: string
  maxBarras?: number
}>()

const tareasOrdenadas = computed(() => {
  const list = [...(props.tareas || [])]
  return list
    .map((t) => ({ ...t, pct: Number(t.porcentaje_avance) || 0 }))
    .sort((a, b) => b.pct - a.pct)
})

const tareasMostrar = computed(() => {
  const max = props.maxBarras ?? 12
  return tareasOrdenadas.value.slice(0, max)
})

function claseAvance(pct: number): string {
  if (pct >= 100) return 'completo'
  if (pct >= 70) return 'avanzado'
  if (pct >= 40) return 'en-proceso'
  return 'pendiente'
}

function tituloCorto(t: Record<string, unknown>): string {
  const s = String(t.titulo || t.proyecto_nombre || 'Tarea')
  return s.length > 35 ? s.slice(0, 32) + '...' : s
}
</script>

<template>
  <div class="grafico-barras-wrap">
    <h4 class="grafico-barras-titulo">{{ titulo || 'Avance por tarea' }}</h4>
    <div class="grafico-leyenda-barras">
      <span class="leyenda-b"><span class="dot pendiente" /> Pendiente (0-39%)</span>
      <span class="leyenda-b"><span class="dot en-proceso" /> En proceso (40-69%)</span>
      <span class="leyenda-b"><span class="dot avanzado" /> Avanzado (70-99%)</span>
      <span class="leyenda-b"><span class="dot completo" /> Completado (100%)</span>
    </div>
    <div v-if="tareasMostrar.length" class="grafico-barras">
      <div
        v-for="t in tareasMostrar"
        :key="(t.id as number)"
        class="barra-fila"
      >
        <span class="barra-label" :title="t.titulo as string">{{ tituloCorto(t) }}</span>
        <div class="barra-wrap">
          <div
            class="barra-fill"
            :class="claseAvance(t.pct)"
            :style="{ width: `${Math.min(100, t.pct)}%` }"
          />
          <span class="barra-valor">{{ t.pct }}%</span>
        </div>
      </div>
    </div>
    <p v-else class="sin-datos">Sin tareas para mostrar</p>
  </div>
</template>

<style scoped>
.grafico-barras-wrap {
  padding: 1rem 1.25rem;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  margin: 0 1.25rem 1.25rem;
}

.grafico-barras-titulo {
  margin: 0 0 1rem;
  font-size: 0.95rem;
  font-weight: 600;
  color: #334155;
}

.grafico-barras {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.barra-fila {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 28px;
}

.barra-label {
  flex: 0 0 140px;
  font-size: 0.82rem;
  color: #475569;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.barra-wrap {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.barra-fill {
  height: 18px;
  border-radius: 6px;
  transition: width 0.4s ease;
  min-width: 4px;
}

.barra-fill.pendiente {
  background: linear-gradient(90deg, #fbbf24, #f59e0b);
}

.barra-fill.en-proceso {
  background: linear-gradient(90deg, #60a5fa, #3b82f6);
}

.barra-fill.avanzado {
  background: linear-gradient(90deg, #4ade80, #22c55e);
}

.barra-fill.completo {
  background: linear-gradient(90deg, #22c55e, #16a34a);
}

.barra-valor {
  font-size: 0.9rem;
  font-weight: 500;
  color: #1e293b;
  min-width: 2.5rem;
}

.sin-datos {
  margin: 0;
  font-size: 0.9rem;
  color: #94a3b8;
  font-style: italic;
}

.grafico-leyenda-barras {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.25rem;
  margin-bottom: 1rem;
  font-size: 0.78rem;
  color: #64748b;
}

.leyenda-b {
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.leyenda-b .dot {
  width: 8px;
  height: 8px;
  border-radius: 4px;
}

.leyenda-b .dot.pendiente { background: linear-gradient(90deg, #fbbf24, #f59e0b); }
.leyenda-b .dot.en-proceso { background: linear-gradient(90deg, #60a5fa, #3b82f6); }
.leyenda-b .dot.avanzado { background: linear-gradient(90deg, #4ade80, #22c55e); }
.leyenda-b .dot.completo { background: linear-gradient(90deg, #22c55e, #16a34a); }
</style>
