<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useSessionHeartbeat } from '@/composables/useSessionHeartbeat'
import AppFooter from '@/components/AppFooter.vue'
import AssistenteChatbot from '@/components/AssistenteChatbot.vue'
import Breadcrumbs from '@/components/Breadcrumbs.vue'

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
      { to: '/calendario', label: 'Calendario' },
      { to: '/areas', label: 'Áreas' },
      { to: '/secretarias', label: 'Secretarías' },
      { to: '/usuarios', label: 'Usuarios' },
      { to: '/roles', label: 'Roles' },
      { to: '/backup-restore', label: 'Backup & Restore' },
      { to: '/auditoria-comentarios', label: 'Auditoría comentarios y adjuntos' },
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
      { to: '/calendario', label: 'Calendario' },
    ]
  }
  if (isCarga.value) {
    return [
      { to: '/dashboard', label: 'Mis Proyectos' },
      { to: '/cargar', label: 'Cargar Avances' },
      { to: '/calendario', label: 'Calendario' },
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
      <div v-if="user" class="user-block">
        <p class="user-name">{{ user.nombreCompleto || (user.nombre + ' ' + (user.apellido || '')).trim() || user.nombre }}</p>
        <p v-if="user.areaNombre || user.secretariaNombre" class="user-meta">
          {{ user.areaNombre ? `Área: ${user.areaNombre}` : user.secretariaNombre ? `Secretaría: ${user.secretariaNombre}` : '' }}
        </p>
        <p v-if="user.rolNombre" class="user-rol">{{ user.rolNombre }}</p>
      </div>
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
        <Breadcrumbs />
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
/* Variables para consistencia con login */
.layout {
  --panel-radius: 12px;
  --panel-shadow: 0 4px 24px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.04);
  --panel-shadow-strong: 0 8px 32px rgba(0, 0, 0, 0.12);
}

.layout {
  display: flex;
  min-height: 100vh;
  min-height: 100dvh;
}

/* Sidebar refinado */
.sidebar {
  width: 260px;
  background: linear-gradient(175deg, #0d47a1 0%, #1565c0 50%, #1976d2 100%);
  color: #fff;
  padding: clamp(1.25rem, 2.5vw, 1.75rem);
  display: flex;
  flex-direction: column;
  box-shadow: 2px 0 12px rgba(0, 0, 0, 0.08);
  flex-shrink: 0;
}

.logo-link {
  display: block;
  margin-bottom: clamp(1rem, 2vw, 1.25rem);
  transition: opacity 0.2s;
}
.logo-link:hover {
  opacity: 0.9;
}

.sidebar-logo {
  height: clamp(38px, 8vw, 46px);
  width: auto;
  max-width: 100%;
  filter: brightness(0) invert(1);
  object-fit: contain;
}

.user-block {
  margin-bottom: clamp(0.875rem, 2vw, 1.125rem);
  padding-bottom: clamp(0.875rem, 2vw, 1.125rem);
  border-bottom: 1px solid rgba(255, 255, 255, 0.18);
}

.user-name {
  font-size: clamp(0.88rem, 2vw, 0.98rem);
  font-weight: 600;
  color: #fff;
  margin: 0 0 0.2rem;
  line-height: 1.35;
  letter-spacing: 0.01em;
}

.user-meta {
  font-size: clamp(0.72rem, 1.8vw, 0.78rem);
  color: rgba(255, 255, 255, 0.88);
  margin: 0 0 0.1rem;
}

.user-rol {
  font-size: clamp(0.65rem, 1.6vw, 0.72rem);
  color: rgba(255, 255, 255, 0.65);
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

nav {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  flex: 1;
  min-height: 0;
}

nav a {
  color: rgba(255, 255, 255, 0.9);
  text-decoration: none;
  padding: clamp(0.5rem, 1.5vw, 0.65rem) clamp(0.75rem, 2vw, 0.95rem);
  border-radius: 10px;
  font-size: clamp(0.88rem, 2vw, 0.92rem);
  font-weight: 500;
  transition: background 0.2s, color 0.2s, transform 0.15s;
}

nav a:hover {
  background: rgba(255, 255, 255, 0.18);
  color: #fff;
}

nav a.router-link-active {
  background: rgba(255, 255, 255, 0.28);
  color: #fff;
}

.sidebar-footer {
  margin-top: auto;
  padding-top: clamp(1rem, 2vw, 1.25rem);
  border-top: 1px solid rgba(255, 255, 255, 0.2);
  flex-shrink: 0;
}

.sidebar-footer.footer-inline {
  margin-top: clamp(1rem, 2vw, 1.25rem);
}

.btn-logout {
  width: 100%;
  padding: clamp(0.55rem, 1.5vw, 0.7rem) clamp(1rem, 2.5vw, 1.25rem);
  min-height: 44px;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.5);
  color: #fff;
  border-radius: 10px;
  font-size: clamp(0.85rem, 2vw, 0.92rem);
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s, transform 0.15s;
}

.btn-logout:hover {
  background: rgba(255, 255, 255, 0.18);
  border-color: rgba(255, 255, 255, 0.9);
}

.main-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  min-height: 100dvh;
  min-width: 0;
}

/* Área de contenido: fondo sutil */
.content {
  flex: 1;
  padding: clamp(1rem, 2.5vw, 1.75rem);
  overflow: auto;
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 50%, #eef2f7 100%);
}

/* Modal confirm: alineado con login */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
  animation: modalFadeIn 0.2s ease;
}

@keyframes modalFadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-confirm {
  background: #ffffff;
  padding: clamp(1.5rem, 4vw, 2rem);
  border-radius: 16px;
  max-width: 420px;
  width: 100%;
  box-shadow: var(--panel-shadow-strong);
  border: 1px solid rgba(226, 232, 240, 0.8);
  animation: modalSlideIn 0.25s ease;
}

@keyframes modalSlideIn {
  from {
    opacity: 0;
    transform: translateY(-12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.modal-confirm h3 {
  margin: 0 0 1.25rem;
  font-size: clamp(1.05rem, 2.5vw, 1.15rem);
  font-weight: 600;
  color: #0d47a1;
  line-height: 1.4;
}

.modal-confirm .modal-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
  flex-wrap: wrap;
}

.btn-cancel-modal {
  padding: 0.6rem 1.35rem;
  min-height: 44px;
  background: #fff;
  color: #475569;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-weight: 500;
  font-size: 0.95rem;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}

.btn-cancel-modal:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.btn-accept {
  padding: 0.6rem 1.35rem;
  min-height: 44px;
  background: linear-gradient(180deg, #1565c0 0%, #0d47a1 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  font-size: 0.95rem;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(13, 71, 161, 0.3);
  transition: opacity 0.2s, transform 0.15s;
}

.btn-accept:hover {
  opacity: 0.95;
  transform: translateY(-1px);
}

/* Botón scroll-top: refinado + safe-area */
.btn-scroll-top {
  position: fixed;
  bottom: clamp(1.25rem, 3vw, 1.5rem);
  right: 5.5rem;
  z-index: 998;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #475569 0%, #64748b 100%);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(71, 85, 105, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s, box-shadow 0.2s, opacity 0.2s;
}

.btn-scroll-top:hover {
  transform: scale(1.06);
  box-shadow: 0 6px 20px rgba(71, 85, 105, 0.5);
  background: linear-gradient(135deg, #334155 0%, #475569 100%);
}

.btn-scroll-top:active {
  transform: scale(0.97);
}

.btn-scroll-icon {
  font-size: 1.3rem;
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
  transform: translateY(10px);
}

/* Hamburguesa */
.btn-hamburger {
  display: none;
  position: fixed;
  top: clamp(0.875rem, 2vw, 1.125rem);
  left: clamp(0.875rem, 2vw, 1.125rem);
  z-index: 1001;
  width: 48px;
  height: 48px;
  padding: 0;
  background: linear-gradient(135deg, #0d47a1 0%, #1565c0 100%);
  border: none;
  border-radius: 10px;
  cursor: pointer;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  box-shadow: 0 4px 16px rgba(13, 71, 161, 0.4);
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
  background: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  z-index: 999;
  animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Responsive móvil */
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
    width: min(300px, 88vw);
    z-index: 1000;
    transform: translateX(-100%);
    transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 4px 0 24px rgba(0, 0, 0, 0.15);
  }
  .sidebar.open {
    transform: translateX(0);
  }
  .content {
    padding: clamp(1rem, 3vw, 1.25rem);
    padding-top: 4.5rem;
  }
  .btn-scroll-top {
    right: clamp(1rem, 3vw, 1.25rem);
    bottom: clamp(1rem, 3vw, 1.25rem);
  }
}

@media (min-width: 769px) {
  .sidebar {
    position: relative;
    transform: none !important;
    width: 260px;
    box-shadow: 2px 0 12px rgba(0, 0, 0, 0.06);
  }
}

/* Safe-area para notch y barras del sistema */
@supports (padding: max(0px)) {
  .btn-hamburger {
    top: max(clamp(0.875rem, 2vw, 1.125rem), env(safe-area-inset-top));
    left: max(clamp(0.875rem, 2vw, 1.125rem), env(safe-area-inset-left));
  }
  .btn-scroll-top {
    bottom: max(clamp(1.25rem, 3vw, 1.5rem), env(safe-area-inset-bottom));
  }
  @media (max-width: 768px) {
    .btn-scroll-top {
      right: max(clamp(1rem, 3vw, 1.25rem), env(safe-area-inset-right));
      bottom: max(clamp(1rem, 3vw, 1.25rem), env(safe-area-inset-bottom));
    }
  }
  .content {
    padding-left: max(clamp(1rem, 2.5vw, 1.75rem), env(safe-area-inset-left));
    padding-right: max(clamp(1rem, 2.5vw, 1.75rem), env(safe-area-inset-right));
  }
}
</style>
