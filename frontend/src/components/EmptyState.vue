<script setup lang="ts">
defineProps<{
  titulo?: string
  mensaje?: string
  icono?: 'lista' | 'busqueda' | 'proyectos' | 'tareas' | 'backup' | 'general'
}>()
</script>

<template>
  <div class="empty-state">
    <div class="empty-icon" aria-hidden="true">
      <svg v-if="icono === 'busqueda'" xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="11" cy="11" r="8"/>
        <path d="m21 21-4.35-4.35"/>
      </svg>
      <svg v-else-if="icono === 'proyectos'" xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M2 20h20"/>
        <path d="M5 20V8l7-4 7 4v12"/>
        <path d="M5 8h14"/>
      </svg>
      <svg v-else-if="icono === 'tareas'" xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M9 11l3 3L22 4"/>
        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
      </svg>
      <svg v-else-if="icono === 'backup'" xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
        <polyline points="7 10 12 15 17 10"/>
        <line x1="12" y1="15" x2="12" y2="3"/>
      </svg>
      <svg v-else xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <rect width="18" height="18" x="3" y="3" rx="2"/>
        <path d="M3 9h18"/>
        <path d="M9 21V9"/>
      </svg>
    </div>
    <h3 class="empty-titulo">{{ titulo || 'No hay datos' }}</h3>
    <p class="empty-mensaje">{{ mensaje || 'Aún no se han cargado registros. Use el botón de crear para agregar el primero.' }}</p>
  </div>
</template>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 2rem;
  text-align: center;
  background: #f8fafc;
  border-radius: 12px;
  border: 1px dashed #cbd5e1;
  min-height: 200px;
}
.empty-icon {
  color: #94a3b8;
  margin-bottom: 1rem;
  opacity: 0.85;
}
.empty-titulo {
  font-size: 1.1rem;
  font-weight: 600;
  color: #475569;
  margin: 0 0 0.5rem;
}
.empty-mensaje {
  font-size: 0.95rem;
  color: #64748b;
  margin: 0;
  max-width: 360px;
  line-height: 1.5;
}
</style>
