<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  data: { fecha: string; porcentaje: number }[]
  label: string
  width?: number
  height?: number
  chartId?: string
}>()

const gradientId = computed(() => props.chartId || 'lineGrad-default')

const width = props.width ?? 300
const height = props.height ?? 160
const padding = { top: 20, right: 16, bottom: 40, left: 44 }
const chartWidth = width - padding.left - padding.right
const chartHeight = height - padding.top - padding.bottom

function formatFecha(f: string): string {
  try {
    const d = new Date(f)
    if (isNaN(d.getTime())) return f.slice(0, 10)
    return `${d.getDate()}/${d.getMonth() + 1}`
  } catch {
    return f.slice(0, 10)
  }
}

const chartData = computed(() => {
  const arr = props.data
  if (!arr?.length) return { points: '', pathD: '', areaPathD: '', xLabels: [], yLabels: [] }
  const maxPct = Math.max(100, ...arr.map((d) => d.porcentaje), 1)
  const minPct = Math.min(0, ...arr.map((d) => d.porcentaje))
  const range = maxPct - minPct || 1
  const coords = arr.map((d, i) => {
    const x = padding.left + (i / Math.max(1, arr.length - 1)) * chartWidth
    const y = padding.top + chartHeight - ((d.porcentaje - minPct) / range) * chartHeight
    return { x, y, fecha: d.fecha, porcentaje: d.porcentaje }
  })
  const pointsStr = coords.map((c) => `${c.x},${c.y}`).join(' ')
  const pathD = coords.reduce((acc, c, i) => acc + (i === 0 ? `M ${c.x} ${c.y}` : ` L ${c.x} ${c.y}`), '')
  const firstX = coords[0]?.x ?? padding.left
  const lastX = coords[coords.length - 1]?.x ?? width - padding.right
  const bottom = height - padding.bottom
  const areaPathD = `${pathD} L ${lastX} ${bottom} L ${firstX} ${bottom} Z`
  const maxXLabels = 6
  const step = arr.length <= maxXLabels ? 1 : Math.max(1, Math.floor(arr.length / maxXLabels))
  const indicesToShow: number[] = []
  for (let i = 0; i < arr.length; i += step) indicesToShow.push(i)
  if (arr.length > 1 && indicesToShow[indicesToShow.length - 1] !== arr.length - 1) {
    indicesToShow.push(arr.length - 1)
  }
  const xLabels = indicesToShow.map((j) => ({
    x: padding.left + (j / Math.max(1, arr.length - 1)) * chartWidth,
    text: formatFecha(arr[j].fecha),
  }))
  const yTicks = [0, 25, 50, 75, 100].filter((v) => v >= minPct && v <= maxPct)
  if (yTicks.length === 0) yTicks.push(minPct, maxPct)
  const yLabels = yTicks.map((pct) => ({
    y: padding.top + chartHeight - ((pct - minPct) / range) * chartHeight,
    text: `${Math.round(pct)}%`,
  }))
  return { points: pointsStr, pathD, areaPathD, xLabels, yLabels }
})
</script>

<template>
  <div class="line-chart">
    <svg :width="width" :height="height" :viewBox="`0 0 ${width} ${height}`">
      <path
        v-if="chartData.areaPathD"
        class="area-path"
        :d="chartData.areaPathD"
        :fill="`url(#${gradientId})`"
      />
      <path
        class="line-path"
        :d="chartData.pathD"
        fill="none"
        stroke="#3b82f6"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <g v-for="(lb, i) in chartData.xLabels" :key="'x'+i" class="axis-label axis-x">
        <text :x="lb.x" :y="height - 8" text-anchor="middle">{{ lb.text }}</text>
      </g>
      <g v-for="(lb, i) in chartData.yLabels" :key="'y'+i" class="axis-label axis-y">
        <text :x="padding.left - 6" :y="lb.y + 4" text-anchor="end">{{ lb.text }}</text>
      </g>
      <text :x="width/2" :y="height - 6" class="axis-title">Días (día/mes)</text>
      <defs>
        <linearGradient :id="gradientId" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#3b82f6" stop-opacity="0.3" />
          <stop offset="100%" stop-color="#3b82f6" stop-opacity="0" />
        </linearGradient>
      </defs>
    </svg>
    <div class="line-label">{{ label }}</div>
  </div>
</template>

<style scoped>
.line-chart {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}
.line-path {
  vector-effect: non-scaling-stroke;
}
.area-path {
  vector-effect: non-scaling-stroke;
}
.line-label {
  font-size: 0.75rem;
  color: #64748b;
  text-align: center;
}
.axis-label text {
  font-size: 9px;
  fill: #64748b;
}
.axis-title {
  font-size: 9px;
  fill: #94a3b8;
}
</style>
