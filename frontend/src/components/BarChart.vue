<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  items: { label: string; value: number }[]
  maxItems?: number
  barColor?: string
}>()

const displayItems = computed(() => {
  const list = props.items || []
  const max = props.maxItems ?? 12
  return list.slice(0, max)
})

const maxVal = computed(() => {
  const vals = displayItems.value.map((i) => i.value)
  return Math.max(100, ...vals, 1)
})

const barColor = props.barColor ?? '#3b82f6'
</script>

<template>
  <div class="bar-chart">
    <div v-for="(item, i) in displayItems" :key="i" class="bar-row">
      <span class="bar-label">{{ (item.label || '').slice(0, 26) }}{{ (item.label || '').length > 26 ? '…' : '' }}</span>
      <div class="bar-track">
        <div
          class="bar-fill"
          :style="{
            width: Math.max(2, (item.value / maxVal) * 100) + '%',
            backgroundColor: barColor,
          }"
        ></div>
      </div>
      <span class="bar-value">{{ item.value }}%</span>
    </div>
  </div>
</template>

<style scoped>
.bar-chart {
  width: 100%;
  max-width: 340px;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.bar-row {
  display: grid;
  grid-template-columns: 1fr 2fr 3rem;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
}
.bar-label {
  color: #475569;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.bar-track {
  height: 1rem;
  background: #f1f5f9;
  border-radius: 6px;
  overflow: hidden;
}
.bar-fill {
  height: 100%;
  border-radius: 6px;
  min-width: 2px;
  transition: width 0.3s ease;
}
.bar-value {
  font-weight: 600;
  color: #64748b;
  text-align: right;
}
</style>
