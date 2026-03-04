<script setup lang="ts">
import { useToast } from '@/composables/useToast'

const { messages, remove } = useToast()
</script>

<template>
  <div class="toast-container">
    <TransitionGroup name="toast">
      <div
        v-for="msg in messages"
        :key="msg.id"
        class="toast"
        :class="`toast-${msg.type}`"
      >
        <span class="toast-icon">
          <svg v-if="msg.type === 'success'" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
          </svg>
          <svg v-else-if="msg.type === 'error'" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <line x1="15" y1="9" x2="9" y2="15"/>
            <line x1="9" y1="9" x2="15" y2="15"/>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="16" x2="12" y2="12"/>
            <line x1="12" y1="8" x2="12.01" y2="8"/>
          </svg>
        </span>
        <span class="toast-text">{{ msg.text }}</span>
        <button type="button" class="toast-close" aria-label="Cerrar" @click="remove(msg.id)">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-container {
  position: fixed;
  top: 1.5rem;
  right: 1.5rem;
  z-index: 10001;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-width: 380px;
}
.toast {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  border-radius: 10px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
  font-size: 0.95rem;
  font-weight: 500;
}
.toast-success {
  background: #16a34a;
  color: white;
}
.toast-error {
  background: #dc2626;
  color: white;
}
.toast-info {
  background: #1565c0;
  color: white;
}
.toast-icon {
  flex-shrink: 0;
}
.toast-text {
  flex: 1;
}
.toast-close {
  flex-shrink: 0;
  background: rgba(255,255,255,0.25);
  border: none;
  border-radius: 6px;
  padding: 0.25rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}
.toast-close:hover {
  background: rgba(255,255,255,0.4);
}
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateX(100%);
}
.toast-move {
  transition: transform 0.3s ease;
}
</style>
