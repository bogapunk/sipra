<script setup lang="ts">
withDefaults(defineProps<{
  variant?: 'default' | 'login'
}>(), { variant: 'default' })
</script>

<template>
  <footer class="app-footer" :class="[variant === 'login' ? 'footer-login' : 'footer-default']">
    <div class="footer-content">
      <img
        src="/Logo-color_01-150x45.png"
        alt="Agencia de Innovación TDF"
        class="footer-logo"
      />
      <p class="footer-copyright">
        © 2026 - Todos los derechos reservados | Las Islas Malvinas son argentinas.
      </p>
    </div>
  </footer>
</template>

<style scoped>
.app-footer {
  margin-top: auto;
  padding: clamp(1rem, 2.5vw, 1.5rem) clamp(1rem, 3vw, 1.5rem);
  flex-shrink: 0;
}
.footer-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  gap: 0.5rem;
}
.footer-logo {
  height: clamp(32px, 8vw, 40px);
  width: auto;
  max-width: 100%;
  object-fit: contain;
  opacity: 0.95;
}
.footer-copyright {
  font-size: clamp(0.7rem, 2vw, 0.8rem);
  margin: 0;
  letter-spacing: 0.02em;
  font-weight: 400;
  line-height: 1.4;
}

/* Variante para paneles (con fondo) */
.footer-default {
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
}
.footer-default .footer-copyright {
  color: #64748b;
}

/* Variante para login (elegante, sin caja) */
.footer-login {
  background: transparent;
  padding: clamp(1rem, 2.5vw, 1.5rem);
}
.footer-login .footer-logo {
  filter: brightness(0) invert(1);
  opacity: 0.9;
}
.footer-login .footer-copyright {
  color: rgba(255, 255, 255, 0.85);
  font-size: clamp(0.65rem, 1.8vw, 0.75rem);
}

@media (max-width: 480px) {
  .footer-copyright {
    max-width: 90%;
    word-break: break-word;
  }
}

@supports (padding: max(0px)) {
  .app-footer {
    padding-bottom: max(clamp(1rem, 2.5vw, 1.5rem), env(safe-area-inset-bottom));
  }
}
</style>
