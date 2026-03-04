<script setup lang="ts">
const props = defineProps<{
  value: number
  label: string
  size?: number
}>()
const size = props.size ?? 120
const r = size / 2 - 4
const circumference = 2 * Math.PI * r
const strokeDash = (props.value / 100) * circumference
</script>

<template>
  <div class="pie-chart">
    <svg :width="size" :height="size" :viewBox="`0 0 ${size} ${size}`">
      <circle
        :cx="size/2"
        :cy="size/2"
        :r="r"
        fill="none"
        stroke="#e2e8f0"
        stroke-width="12"
      />
      <circle
        :cx="size/2"
        :cy="size/2"
        :r="r"
        fill="none"
        stroke="#3b82f6"
        stroke-width="12"
        :stroke-dasharray="`${strokeDash} 999`"
        stroke-linecap="round"
        :transform="`rotate(-90 ${size/2} ${size/2})`"
      />
    </svg>
    <div class="pie-label">
      <span class="pie-value">{{ value }}%</span>
      <span class="pie-text">{{ label }}</span>
    </div>
  </div>
</template>

<style scoped>
.pie-chart {
  position: relative;
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}
.pie-label {
  text-align: center;
}
.pie-value {
  display: block;
  font-size: 1.25rem;
  font-weight: 700;
  color: #1e293b;
}
.pie-text {
  font-size: 0.75rem;
  color: #64748b;
}
</style>
