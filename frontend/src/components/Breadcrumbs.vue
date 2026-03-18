<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

interface BreadcrumbItem {
  label: string
  to?: string
}

const route = useRoute()

const items = computed<BreadcrumbItem[]>(() => {
  const path = route.path
  const result: BreadcrumbItem[] = [{ label: 'Inicio', to: '/dashboard' }]

  if (path === '/auditoria-comentarios') {
    result.push({ label: 'Auditoría de comentarios y adjuntos' })
  } else if (path.startsWith('/proyectos')) {
    result.push({ label: 'Proyectos', to: '/proyectos' })
    const id = route.params.id
    if (id) {
      const nombre = (route.meta?.proyectoNombre as string) || `Proyecto ${id}`
      if (path.endsWith('/reasignar')) {
        result.push({ label: nombre, to: `/proyectos/${id}` })
        result.push({ label: 'Reasignar' })
      } else {
        result.push({ label: nombre })
      }
    }
  }

  return result
})

const mostrar = computed(() => items.value.length >= 3)
</script>

<template>
  <nav v-if="mostrar" class="breadcrumbs" aria-label="Navegación">
    <ol class="breadcrumbs-list">
      <li v-for="(item, i) in items" :key="i" class="breadcrumb-item">
        <router-link v-if="item.to" :to="item.to" class="breadcrumb-link">{{ item.label }}</router-link>
        <span v-else class="breadcrumb-current">{{ item.label }}</span>
        <span v-if="i < items.length - 1" class="breadcrumb-sep" aria-hidden="true">›</span>
      </li>
    </ol>
  </nav>
</template>

<style scoped>
.breadcrumbs {
  margin-bottom: clamp(0.875rem, 2vw, 1.125rem);
}

.breadcrumbs-list {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.35rem;
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: clamp(0.82rem, 2vw, 0.92rem);
  line-height: 1.4;
}

.breadcrumb-item {
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.breadcrumb-link {
  color: #64748b;
  text-decoration: none;
  transition: color 0.2s;
  font-weight: 500;
}

.breadcrumb-link:hover {
  color: #0d47a1;
}

.breadcrumb-current {
  color: #1e293b;
  font-weight: 600;
  letter-spacing: 0.01em;
}

.breadcrumb-sep {
  color: #94a3b8;
  margin-left: 0.15rem;
  font-weight: 400;
  user-select: none;
}

@media (max-width: 640px) {
  .breadcrumbs {
    margin-bottom: 0.75rem;
  }
  .breadcrumbs-list {
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
    padding-bottom: 0.25rem;
    gap: 0.25rem;
  }
  .breadcrumb-item {
    flex-shrink: 0;
  }
}
</style>
