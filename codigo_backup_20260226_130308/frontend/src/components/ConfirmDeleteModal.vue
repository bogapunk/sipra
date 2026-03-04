<script setup lang="ts">
import { useConfirmDelete } from '@/composables/useConfirmDelete'

const { isOpen, resolve } = useConfirmDelete()
</script>

<template>
  <Transition name="modal">
    <div v-if="isOpen" class="confirm-overlay" @click.self="resolve(false)">
      <div class="confirm-modal">
        <div class="confirm-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="3 6 5 6 21 6"/>
            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
            <line x1="10" y1="11" x2="10" y2="17"/>
            <line x1="14" y1="11" x2="14" y2="17"/>
          </svg>
        </div>
        <h3 class="confirm-title">¿Está seguro que desea eliminar el registro?</h3>
        <p class="confirm-subtitle">Esta acción no se puede deshacer.</p>
        <div class="confirm-actions">
          <button type="button" class="btn-cancel" @click="resolve(false)">
            Cancelar
          </button>
          <button type="button" class="btn-delete" @click="resolve(true)">
            Eliminar
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.confirm-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
  backdrop-filter: blur(4px);
  padding: 1rem;
}
.confirm-modal {
  background: white;
  border-radius: 16px;
  padding: 2rem;
  max-width: 420px;
  width: 100%;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  text-align: center;
}
.confirm-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto 1.25rem;
  color: #dc2626;
  opacity: 0.9;
}
.confirm-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 0.5rem;
  line-height: 1.4;
}
.confirm-subtitle {
  font-size: 0.9rem;
  color: #64748b;
  margin: 0 0 1.5rem;
}
.confirm-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: center;
  flex-wrap: wrap;
}
.btn-cancel {
  padding: 0.65rem 1.5rem;
  font-size: 0.95rem;
  font-weight: 500;
  border: 1px solid #e2e8f0;
  background: white;
  color: #64748b;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-cancel:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
  color: #475569;
}
.btn-delete {
  padding: 0.65rem 1.5rem;
  font-size: 0.95rem;
  font-weight: 500;
  border: none;
  background: #dc2626;
  color: white;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-delete:hover {
  background: #b91c1c;
}
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}
.modal-enter-active .confirm-modal,
.modal-leave-active .confirm-modal {
  transition: transform 0.2s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-from .confirm-modal,
.modal-leave-to .confirm-modal {
  transform: scale(0.95);
}
</style>
