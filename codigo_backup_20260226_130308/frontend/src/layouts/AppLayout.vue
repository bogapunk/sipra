<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useSessionHeartbeat } from '@/composables/useSessionHeartbeat'
import AppFooter from '@/components/AppFooter.vue'
import AssistenteChatbot from '@/components/AssistenteChatbot.vue'

const router = useRouter()
const { user, isAdmin, isVisualizador, isCarga, logout } = useAuth()
const { endSession } = useSessionHeartbeat()
const showLogoutConfirm = ref(false)
const showScrollTop = ref(false)
const sidebarOpen = ref(false)
const contentRef = ref<HTMLElement | null>(null)

watch(() => router.currentRoute.value.path, () => {
  sidebarOpen.value = false
})

const SCROLL_THRESHOLD = 150

function checkScroll() {
  const el = contentRef.value
  const winScroll = window.scrollY ?? document.documentElement?.scrollTop ?? 0
  const elScroll = el?.scrollTop ?? 0
  showScrollTop.value = winScroll > SCROLL_THRESHOLD || elScroll > SCROLL_THRESHOLD
}

function scrollToTop() {
  const el = contentRef.value
  if (el && el.scrollTop > 0) {
    el.scrollTo({ top: 0, behavior: 'smooth' })
  }
  if (window.scrollY > 0) {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

let scrollCheckInterval: ReturnType<typeof setInterval> | null = null

onMounted(() => {
  window.addEventListener('scroll', checkScroll, { passive: true })
  nextTick(() => {
    const el = contentRef.value
    if (el) {
      el.addEventListener('scroll', checkScroll)
      checkScroll()
    }
    scrollCheckInterval = setInterval(checkScroll, 400)
  })
})

onUnmounted(() => {
  contentRef.value?.removeEventListener('scroll', checkScroll)
  window.removeEventListener('scroll', checkScroll)
  if (scrollCheckInterval) {
    clearInterval(scrollCheckInterval)
    scrollCheckInterval = null
  }
})

const navItems = computed(() => {
  if (isAdmin.value) {
    return [
      { to: '/dashboard', label: 'Dashboard' },
      { to: '/avances-por-area', label: 'Avances por área' },
      { to: '/avances-por-secretaria', label: 'Avances por secretaría' },
      { to: '/planificacion', label: 'Planificación' },
      { to: '/proyectos', label: 'Proyectos' },
      { to: '/tareas', label: 'Tareas' },
      { to: '/areas', label: 'Áreas' },
      { to: '/secretarias', label: 'Secretarías' },
      { to: '/usuarios', label: 'Usuarios' },
      { to: '/roles', label: 'Roles' },
      { to: '/backup-restore', label: 'Backup & Restore' },
    ]
  }
  if (isVisualizador.value) {
    return [
      { to: '/dashboard', label: 'Dashboard' },
      { to: '/avances-por-area', label: 'Avances por área' },
      { to: '/avances-por-secretaria', label: 'Avances por secretaría' },
      { to: '/planificacion', label: 'Planificación' },
      { to: '/proyectos', label: 'Proyectos' },
      { to: '/tareas', label: 'Tareas' },
    ]
  }
  if (isCarga.value) {
    return [
      { to: '/dashboard', label: 'Mis Proyectos' },
      { to: '/cargar', label: 'Cargar Avances' },
    ]
  }
  return [{ to: '/dashboard', label: 'Dashboard' }]
})

function confirmLogout() {
  showLogoutConfirm.value = true
}

function cancelLogout() {
  showLogoutConfirm.value = false
}

async function doLogout() {
  await endSession()
  logout()
  showLogoutConfirm.value = false
  router.push('/login')
}

function prefetchRoute(path: string) {
  try {
    const resolved = router.resolve(path)
    const comp = resolved.matched[0]?.components?.default
    if (typeof comp === 'function') {
      ;(comp as () => Promise<unknown>)()
    }
  } catch {
    /* ignorar */
  }
}
</script>

<template>
  <div class="layout">
    <button
      type="button"
      class="btn-hamburger"
      :class="{ open: sidebarOpen }"
      aria-label="Abrir menú"
      @click="sidebarOpen = !sidebarOpen"
    >
      <span class="hamburger-line" />
      <span class="hamburger-line" />
      <span class="hamburger-line" />
    </button>
    <div v-if="sidebarOpen" class="sidebar-overlay" @click="sidebarOpen = false" />
    <aside class="sidebar" :class="{ open: sidebarOpen }">
      <a href="https://www.aif.gob.ar/" target="_blank" rel="noopener" class="logo-link">
        <img src="/Logo-color_01-150x45.png" alt="Agencia de Innovación TDF" class="sidebar-logo" />
      </a>
      <p v-if="user" class="user-info">{{ user.nombreCompleto || (user.nombre + ' ' + (user.apellido || '')).trim() || user.nombre }}</p>
      <nav>
        <router-link
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          @mouseenter="prefetchRoute(item.to)"
        >
          {{ item.label }}
        </router-link>
      </nav>
      <div class="sidebar-footer" :class="{ 'footer-inline': isAdmin }">
        <button type="button" class="btn-logout" @click="confirmLogout">
          Cerrar sesión
        </button>
      </div>
    </aside>
    <div class="main-wrapper">
      <main ref="contentRef" class="content">
        <slot />
      </main>
      <AppFooter />
      <AssistenteChatbot />
      <Transition name="scroll-top">
        <button
          v-show="showScrollTop"
          type="button"
          class="btn-scroll-top"
          title="Volver al inicio"
          aria-label="Volver al inicio de la página"
          @click="scrollToTop"
        >
          <span class="btn-scroll-icon">↑</span>
        </button>
      </Transition>
    </div>

    <div v-if="showLogoutConfirm" class="modal-overlay" @click.self="cancelLogout">
      <div class="modal-confirm">
        <h3>¿Realmente desea salir del sistema?</h3>
        <div class="modal-actions">
          <button type="button" class="btn-cancel-modal" @click="cancelLogout">Cancelar</button>
          <button type="button" class="btn-accept" @click="doLogout">Aceptar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.layout {
  display: flex;
  min-height: 100vh;
}
.sidebar {
  width: 240px;
  background: linear-gradient(180deg, #0d47a1 0%, #1565c0 100%);
  color: #fff;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
}
.logo-link {
  display: block;
  margin-bottom: 1rem;
}
.sidebar-logo {
  height: 42px;
  width: auto;
  filter: brightness(0) invert(1);
}
.main-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}
.user-info {
  font-size: 0.8rem;
  color: rgba(255,255,255,0.75);
  margin-bottom: 1rem;
}
nav {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
nav a {
  color: rgba(255,255,255,0.85);
  text-decoration: none;
  padding: 0.5rem 0.75rem;
  border-radius: 6px;
  transition: all 0.2s;
}
nav a:hover {
  background: rgba(255,255,255,0.15);
  color: #fff;
}
nav a.router-link-active {
  background: rgba(255,255,255,0.25);
  color: #fff;
}
.sidebar-footer {
  margin-top: auto;
  padding-top: 1rem;
  border-top: 1px solid rgba(255,255,255,0.2);
}
.sidebar-footer.footer-inline {
  margin-top: 1rem;
}
.btn-logout {
  width: 100%;
  padding: 0.6rem 1rem;
  background: transparent;
  border: 1px solid rgba(255,255,255,0.6);
  color: #fff;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-logout:hover {
  background: rgba(255,255,255,0.15);
  border-color: #fff;
}
.content {
  flex: 1;
  padding: 1.5rem;
  overflow: auto;
  background: #f1f5f9;
}
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-confirm {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  max-width: 400px;
  width: 90%;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
}
.modal-confirm h3 {
  margin-bottom: 1rem;
  font-size: 1.1rem;
  color: #0d47a1;
}
.modal-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
}
.btn-cancel-modal {
  padding: 0.5rem 1.25rem;
  background: white;
  color: #475569;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
}
.btn-cancel-modal:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}
.btn-accept {
  padding: 0.5rem 1.25rem;
  background: #1565c0;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
}
.btn-accept:hover {
  background: #0d47a1;
}

/* Botón flotante volver al inicio */
.btn-scroll-top {
  position: fixed;
  bottom: 1.5rem;
  right: 5.25rem;
  z-index: 998;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: linear-gradient(135deg, #475569 0%, #64748b 100%);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 3px 12px rgba(71, 85, 105, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s, box-shadow 0.2s, opacity 0.2s;
}
.btn-scroll-top:hover {
  transform: scale(1.08);
  box-shadow: 0 4px 16px rgba(71, 85, 105, 0.45);
  background: linear-gradient(135deg, #334155 0%, #475569 100%);
}
.btn-scroll-top:active {
  transform: scale(0.98);
}
.btn-scroll-icon {
  font-size: 1.25rem;
  font-weight: 600;
  line-height: 1;
}
.scroll-top-enter-active,
.scroll-top-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.scroll-top-enter-from,
.scroll-top-leave-to {
  opacity: 0;
  transform: translateY(8px);
}

/* Responsive: menú hamburguesa y sidebar móvil */
.btn-hamburger {
  display: none;
  position: fixed;
  top: 1rem;
  left: 1rem;
  z-index: 1001;
  width: 44px;
  height: 44px;
  padding: 0;
  background: linear-gradient(135deg, #0d47a1 0%, #1565c0 100%);
  border: none;
  border-radius: 8px;
  cursor: pointer;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  box-shadow: 0 2px 10px rgba(13, 71, 161, 0.35);
  transition: background 0.2s, transform 0.2s;
}
.btn-hamburger:hover {
  background: linear-gradient(135deg, #1565c0 0%, #1976d2 100%);
}
.btn-hamburger:active {
  transform: scale(0.96);
}
.hamburger-line {
  display: block;
  width: 22px;
  height: 2.5px;
  background: white;
  border-radius: 2px;
  transition: transform 0.25s, opacity 0.25s;
}
.btn-hamburger.open .hamburger-line:nth-child(1) {
  transform: translateY(7.5px) rotate(45deg);
}
.btn-hamburger.open .hamburger-line:nth-child(2) {
  opacity: 0;
}
.btn-hamburger.open .hamburger-line:nth-child(3) {
  transform: translateY(-7.5px) rotate(-45deg);
}
.sidebar-overlay {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  z-index: 999;
  animation: fadeIn 0.2s ease;
}
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@media (max-width: 768px) {
  .btn-hamburger {
    display: flex;
  }
  .sidebar-overlay {
    display: block;
  }
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    width: 280px;
    max-width: 85vw;
    z-index: 1000;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
    box-shadow: 4px 0 20px rgba(0, 0, 0, 0.15);
  }
  .sidebar.open {
    transform: translateX(0);
  }
  .content {
    padding: 1rem;
    padding-top: 4rem;
  }
  .btn-scroll-top {
    right: 1rem;
    bottom: 1rem;
  }
}

@media (min-width: 769px) {
  .sidebar {
    position: relative;
    transform: none !important;
    width: 240px;
    box-shadow: none;
  }
}
</style>
