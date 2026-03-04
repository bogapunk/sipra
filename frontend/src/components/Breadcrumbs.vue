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
  margin-bottom: 1rem;
}
.breadcrumbs-list {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.25rem;
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 0.9rem;
}
.breadcrumb-item {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}
.breadcrumb-link {
  color: #64748b;
  text-decoration: none;
  transition: color 0.2s;
}
.breadcrumb-link:hover {
  color: #0d47a1;
}
.breadcrumb-current {
  color: #1e293b;
  font-weight: 500;
}
.breadcrumb-sep {
  color: #94a3b8;
  margin-left: 0.25rem;
}
</style>
