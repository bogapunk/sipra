<script setup lang="ts">
defineProps<{
  texto?: string
  inline?: boolean
}>()
</script>

<template>
  <div class="loader-wrapper" :class="{ inline: inline }">
    <div class="loader-spinner">
      <div class="spinner"></div>
      <p v-if="texto" class="loader-text">{{ texto }}</p>
    </div>
  </div>
</template>

<style scoped>
.loader-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 180px;
  padding: 2rem;
}
.loader-wrapper.inline {
  min-height: 80px;
  padding: 1rem;
}
.loader-spinner {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}
.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #e2e8f0;
  border-top-color: #1565c0;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
.loader-text {
  font-size: 0.9rem;
  color: #64748b;
  margin: 0;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
