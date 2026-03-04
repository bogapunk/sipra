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
  padding: 1.25rem 1.5rem;
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
  height: 40px;
  width: auto;
  object-fit: contain;
  opacity: 0.95;
}
.footer-copyright {
  font-size: 0.8rem;
  margin: 0;
  letter-spacing: 0.02em;
  font-weight: 400;
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
  padding: 1.5rem;
}
.footer-login .footer-logo {
  filter: brightness(0) invert(1);
  opacity: 0.9;
}
.footer-login .footer-copyright {
  color: rgba(255, 255, 255, 0.85);
  font-size: 0.75rem;
}

@media (max-width: 768px) {
  .app-footer {
    padding: 1rem;
  }
  .footer-copyright {
    font-size: 0.75rem;
  }
}
</style>
