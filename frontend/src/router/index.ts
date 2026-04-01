import { nextTick } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useLoading } from '@/composables/useLoading'

/** Scroll del área principal (main.content) al cambiar de panel — mejora percepción de rapidez */
function scrollPanelPrincipalArriba() {
  const el = document.querySelector('.layout main.content')
  if (el instanceof HTMLElement) el.scrollTop = 0
  window.scrollTo({ top: 0, left: 0, behavior: 'auto' })
}

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/login', component: () => import('@/views/LoginView.vue'), meta: { public: true } },
  { path: '/dashboard', component: () => import('@/views/DashboardView.vue') },
  { path: '/proyectos', component: () => import('@/views/ProyectosView.vue') },
  { path: '/proyectos/:id/reasignar', component: () => import('@/views/ReasignarProyectoView.vue') },
  { path: '/proyectos/:id/asignaciones', redirect: (to) => ({ path: `/proyectos/${to.params.id}/vinculos` }) },
  { path: '/proyectos/:id/vinculos', component: () => import('@/views/ProyectoVinculosView.vue') },
  { path: '/proyectos/:id', component: () => import('@/views/ProyectoDetalleView.vue') },
  { path: '/tareas', component: () => import('@/views/TareasView.vue') },
  { path: '/areas', component: () => import('@/views/AreasView.vue') },
  { path: '/secretarias', component: () => import('@/views/SecretariasView.vue') },
  { path: '/usuarios', component: () => import('@/views/UsuariosView.vue') },
  { path: '/roles', component: () => import('@/views/RolesView.vue') },
  { path: '/backup-restore', component: () => import('@/views/BackupRestoreView.vue') },
  { path: '/auditoria-comentarios', component: () => import('@/views/AuditoriaComentariosView.vue') },
  { path: '/avances-por-area', component: () => import('@/views/AvancesPorAreaView.vue') },
  { path: '/avances-por-secretaria', component: () => import('@/views/AvancesPorSecretariaView.vue') },
  { path: '/cargar', component: () => import('@/views/CargarView.vue') },
  { path: '/calendario', component: () => import('@/views/CalendarioView.vue') },
  { path: '/planificacion', component: () => import('@/views/PlanificacionView.vue') },
  { path: '/planificacion/:tab(ejes|planes|programas|objetivos|indicadores)', redirect: to => ({ path: '/planificacion', hash: '#' + to.params.tab }) },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(_to, _from, savedPosition) {
    if (savedPosition) return savedPosition
    return { left: 0, top: 0 }
  },
})

/** Retraso antes del overlay: evita parpadeos en navegaciones muy rápidas (chunks ya en caché) */
const LOADING_OVERLAY_DELAY_MS = 120

let loadingTimer: ReturnType<typeof setTimeout> | null = null
router.beforeEach((to, _from, next) => {
  if (loadingTimer) {
    clearTimeout(loadingTimer)
    loadingTimer = null
  }
  loadingTimer = setTimeout(() => useLoading().show(), LOADING_OVERLAY_DELAY_MS)
  const { user, isAdmin, isVisualizador, isCarga } = useAuth()
  const isLogin = to.path === '/login'
  if (!isLogin && !user.value) {
    next('/login')
    return
  }
  if (isLogin && user.value) {
    next('/dashboard')
    return
  }
  const restrictedForVisualizador = ['/areas', '/usuarios', '/roles', '/cargar', '/secretarias', '/backup-restore', '/auditoria-comentarios']
  const restrictedForCarga = ['/areas', '/usuarios', '/roles', '/avances-por-area', '/avances-por-secretaria', '/planificacion', '/secretarias', '/backup-restore', '/auditoria-comentarios']
  if (to.path === '/auditoria-comentarios' && !isAdmin.value) {
    next('/dashboard')
    return
  }
  if (isVisualizador.value && restrictedForVisualizador.some(p => to.path.startsWith(p))) {
    next('/dashboard')
    return
  }
  if (isCarga.value && restrictedForCarga.some(p => to.path.startsWith(p))) {
    next('/dashboard')
    return
  }
  next()
})

router.afterEach(() => {
  if (loadingTimer) {
    clearTimeout(loadingTimer)
    loadingTimer = null
  }
  requestAnimationFrame(() => {
    useLoading().hide()
    nextTick(() => scrollPanelPrincipalArriba())
  })
})

export default router
