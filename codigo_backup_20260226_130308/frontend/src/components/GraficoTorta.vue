<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  avance: number
  size?: number
}>()

const gradId = 'grad-' + Math.random().toString(36).slice(2, 9)
const size = computed(() => props.size ?? 160)
const avanceNorm = computed(() => Math.min(100, Math.max(0, props.avance)))
const pendiente = computed(() => 100 - avanceNorm.value)

// SVG circle: radius 45, circumference = 2*PI*45 ≈ 282.7
// Avance % = avanceNorm/100 of circumference
const radio = 45
const circum = 2 * Math.PI * radio
const offset = circum * (avanceNorm.value / 100)
const strokeDasharray = computed(() => `${offset} ${circum - offset}`)
</script>

<template>
  <div class="grafico-torta-wrap">
    <svg
      class="grafico-torta"
      :viewBox="`0 0 ${size} ${size}`"
      :width="size"
      :height="size"
    >
      <defs>
        <linearGradient :id="gradId" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#22c55e" />
          <stop offset="100%" stop-color="#16a34a" />
        </linearGradient>
      </defs>
      <!-- Fondo (pendiente) -->
      <circle
        class="torta-fondo"
        :cx="size / 2"
        :cy="size / 2"
        :r="radio"
        fill="none"
        stroke-width="14"
      />
      <!-- Avance (empieza desde arriba, sentido horario) -->
      <circle
        class="torta-avance"
        :cx="size / 2"
        :cy="size / 2"
        :r="radio"
        fill="none"
        :stroke="`url(#${gradId})`"
        stroke-width="14"
        stroke-linecap="round"
        stroke-dasharray="282.7"
        :stroke-dashoffset="282.7 - (282.7 * avanceNorm) / 100"
        :transform="`rotate(-90 ${size / 2} ${size / 2})`"
      />
      <text
        :x="size / 2"
        :y="size / 2"
        text-anchor="middle"
        dominant-baseline="central"
        class="torta-valor-central"
      >
        {{ avanceNorm.toFixed(0) }}%
      </text>
    </svg>
    <div class="grafico-leyenda">
      <div class="leyenda-item avance">
        <span class="leyenda-dot" />
        <span class="leyenda-texto">Avance: {{ avanceNorm.toFixed(1) }}%</span>
      </div>
      <div class="leyenda-item pendiente">
        <span class="leyenda-dot" />
        <span class="leyenda-texto">Pendiente: {{ pendiente.toFixed(1) }}%</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.grafico-torta-wrap {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1rem 1.25rem;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  margin: 0 1.25rem 1.25rem;
}

.grafico-torta {
  flex-shrink: 0;
}

.torta-fondo {
  stroke: #e2e8f0;
}

.torta-avance {
  transition: stroke-dashoffset 0.5s ease;
}

.torta-valor-central {
  font-size: 1.5rem;
  font-weight: 700;
  fill: #1e293b;
  font-family: system-ui, -apple-system, sans-serif;
}

.grafico-leyenda {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.leyenda-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
  font-weight: 500;
}

.leyenda-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.avance .leyenda-dot {
  background: linear-gradient(135deg, #22c55e, #16a34a);
}

.pendiente .leyenda-dot {
  background: #e2e8f0;
}

.leyenda-texto {
  color: #334155;
}
</style>
