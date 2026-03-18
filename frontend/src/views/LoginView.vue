<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import AppFooter from '@/components/AppFooter.vue'

const router = useRouter()
const { setUser } = useAuth()
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

const submit = async () => {
  error.value = ''
  if (!email.value || !password.value) {
    error.value = 'Ingrese email y contraseña'
    return
  }
  loading.value = true
  try {
    const res = await api.post('auth/login/', {
      email: email.value.trim().toLowerCase(),
      password: password.value,
    })
    const data = res.data
    if (data?.success && data?.token && data?.user) {
      const u = data.user
      setUser({
        id: u.id,
        nombre: u.nombre || '',
        apellido: u.apellido || '',
        nombreCompleto: u.nombreCompleto || `${u.nombre || ''} ${u.apellido || ''}`.trim(),
        email: u.email,
        rol: u.rol,
        rolNombre: u.rolNombre,
        area: u.area,
        areaNombre: u.areaNombre,
        secretaria: u.secretaria,
        secretariaNombre: u.secretariaNombre,
      }, data.token)
      router.push('/dashboard')
    } else {
      error.value = 'Error al iniciar sesión'
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string; code?: string }; status?: number }; code?: string; message?: string }
    if (!err.response || err.code === 'ERR_NETWORK' || err.message?.includes('Network Error') || err.response?.status === 503 || err.response?.data?.code === 'db_unavailable') {
      error.value = 'Error de conexión: No se pudo establecer comunicación con el servidor de datos. Por favor, intente nuevamente en unos minutos o contacte al soporte técnico.'
    } else {
      error.value = err.response?.data?.error || 'Credenciales incorrectas.'
    }
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-card">
      <header class="login-brand">
        <img src="/Logo-color_01-150x45.png" alt="Agencia de Innovación TDF" class="login-logo" />
        <h1 class="login-title">SIP-AIF</h1>
        <p class="system-desc">Sistema Integral de Proyectos</p>
      </header>

      <div class="login-divider" aria-hidden="true" />

      <form @submit.prevent="submit" class="login-form">
        <p class="login-subtitle">Inicie sesión para continuar</p>
        <div v-if="error" class="error-msg" role="alert">{{ error }}</div>
        <div class="form-group">
          <label for="login-email">Email</label>
          <input
            id="login-email"
            v-model="email"
            type="email"
            placeholder="usuario@ejemplo.com"
            autocomplete="email"
            required
          />
        </div>
        <div class="form-group">
          <label for="login-password">Contraseña</label>
          <input
            id="login-password"
            v-model="password"
            type="password"
            placeholder="Contraseña"
            autocomplete="current-password"
            required
          />
        </div>
        <button type="submit" class="btn-login" :disabled="loading" :aria-busy="loading">
          <span v-if="loading" class="btn-spinner" aria-hidden="true" />
          <span class="btn-text">{{ loading ? 'Iniciando sesión...' : 'Iniciar sesión' }}</span>
        </button>
      </form>
    </div>
    <AppFooter variant="login" />
  </div>
</template>

<style scoped>
/* Variables para consistencia y responsividad */
.login-page {
  --login-card-radius: 16px;
  --login-card-shadow: 0 4px 24px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.04);
  --login-card-shadow-hover: 0 8px 32px rgba(0, 0, 0, 0.12), 0 4px 12px rgba(0, 0, 0, 0.06);
  --login-input-radius: 10px;
  --login-btn-radius: 10px;
}

.login-page {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(160deg, #0d47a1 0%, #1565c0 45%, #1976d2 100%);
  padding: clamp(1rem, 4vw, 2.5rem) clamp(0.75rem, 3vw, 1.5rem);
  box-sizing: border-box;
}

.login-page > .login-card {
  flex: 0 0 auto;
  margin: auto 0;
}

.login-card {
  background: #ffffff;
  padding: clamp(1.5rem, 4vw, 2.5rem);
  border-radius: var(--login-card-radius);
  box-shadow: var(--login-card-shadow);
  max-width: 420px;
  width: 100%;
  transition: box-shadow 0.3s ease;
}

.login-card:hover {
  box-shadow: var(--login-card-shadow-hover);
}

/* Bloque de marca */
.login-brand {
  text-align: center;
  margin-bottom: 0;
}

.login-logo {
  display: block;
  margin: 0 auto clamp(0.75rem, 2vw, 1.25rem);
  height: clamp(40px, 10vw, 52px);
  width: auto;
  max-width: 100%;
  object-fit: contain;
}

.login-title {
  font-size: clamp(1.35rem, 4vw, 1.75rem);
  font-weight: 700;
  letter-spacing: 0.02em;
  color: #0d47a1;
  margin: 0 0 0.25rem;
  line-height: 1.2;
}

.system-desc {
  color: #64748b;
  font-size: clamp(0.85rem, 2vw, 0.95rem);
  margin: 0;
  font-weight: 500;
  letter-spacing: 0.01em;
}

/* Separador */
.login-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, #e2e8f0 20%, #e2e8f0 80%, transparent);
  margin: clamp(1.25rem, 3vw, 1.75rem) 0;
}

/* Formulario */
.login-form {
  display: flex;
  flex-direction: column;
  gap: clamp(0.875rem, 2.5vw, 1.25rem);
}

.login-subtitle {
  color: #64748b;
  font-size: clamp(0.8rem, 2vw, 0.9rem);
  margin: 0 0 0.25rem;
  text-align: center;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.login-form label {
  font-weight: 500;
  color: #374151;
  font-size: clamp(0.85rem, 2vw, 0.9rem);
}

.login-form input {
  padding: clamp(0.65rem, 2vw, 0.85rem) clamp(0.9rem, 2.5vw, 1.1rem);
  min-height: 44px;
  border: 1px solid #e2e8f0;
  border-radius: var(--login-input-radius);
  font-size: clamp(0.95rem, 2.5vw, 1rem);
  background: #fafbfc;
  transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
  -webkit-appearance: none;
  appearance: none;
}

.login-form input:hover {
  border-color: #cbd5e1;
}

.login-form input:focus {
  outline: none;
  border-color: #1565c0;
  box-shadow: 0 0 0 3px rgba(21, 101, 192, 0.15);
  background: #fff;
}

.login-form input::placeholder {
  color: #94a3b8;
}

.error-msg {
  background: #fef2f2;
  color: #dc2626;
  padding: clamp(0.5rem, 1.5vw, 0.65rem) clamp(0.75rem, 2vw, 1rem);
  border-radius: 8px;
  font-size: clamp(0.8rem, 2vw, 0.9rem);
  line-height: 1.4;
}

.btn-login {
  position: relative;
  padding: clamp(0.7rem, 2vw, 0.85rem) clamp(1.25rem, 3vw, 1.5rem);
  min-height: 48px;
  background: linear-gradient(180deg, #1565c0 0%, #0d47a1 100%);
  color: white;
  border: none;
  border-radius: var(--login-btn-radius);
  font-size: clamp(0.95rem, 2.5vw, 1rem);
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.15s, box-shadow 0.2s;
  box-shadow: 0 2px 8px rgba(13, 71, 161, 0.35);
}

.btn-login:hover:not(:disabled) {
  opacity: 0.95;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(13, 71, 161, 0.4);
}

.btn-login:active:not(:disabled) {
  transform: translateY(0);
}

.btn-login:disabled {
  cursor: not-allowed;
  opacity: 0.85;
}

.btn-spinner {
  display: inline-block;
  width: 1.1em;
  height: 1.1em;
  margin-right: 0.5em;
  vertical-align: -0.15em;
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-top-color: #fff;
  border-radius: 50%;
  animation: login-spin 0.7s linear infinite;
}

@keyframes login-spin {
  to { transform: rotate(360deg); }
}

/* Responsive: móvil pequeño */
@media (max-width: 360px) {
  .login-card {
    padding: 1.25rem;
  }
  .login-form input {
    min-height: 48px;
  }
}

/* Responsive: tablet y desktop */
@media (min-width: 768px) {
  .login-page {
    padding: 2rem 1.5rem;
  }
  .login-card {
    padding: 2.25rem;
  }
}

/* Soporte para safe-area (notch, barra de navegación móvil) */
@supports (padding: max(0px)) {
  .login-page {
    padding-left: max(clamp(0.75rem, 3vw, 1.5rem), env(safe-area-inset-left));
    padding-right: max(clamp(0.75rem, 3vw, 1.5rem), env(safe-area-inset-right));
    padding-bottom: max(clamp(1rem, 4vw, 2.5rem), env(safe-area-inset-bottom));
  }
}
</style>
