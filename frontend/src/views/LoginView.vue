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
    if (err.code === 'ERR_NETWORK' || err.message?.includes('Network Error')) {
      error.value = 'No se pudo conectar al servidor. Verifique que el backend esté iniciado y que PostgreSQL esté disponible.'
    } else if (err.response?.status === 503 || err.response?.data?.code === 'db_unavailable') {
      error.value = 'No hay conexión con la base de datos PostgreSQL. Revise la base antes de iniciar sesión.'
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
      <img src="/Logo-color_01-150x45.png" alt="Agencia de Innovación TDF" class="login-logo" />
      <h1>Sistema de Seguimiento de Proyectos</h1>
      <p class="subtitle">Inicie sesión para continuar</p>

      <form @submit.prevent="submit" class="login-form">
        <div v-if="error" class="error-msg">{{ error }}</div>
        <label>Email</label>
        <input
          v-model="email"
          type="email"
          placeholder="usuario@ejemplo.com"
          required
        />
        <label>Contraseña</label>
        <input
          v-model="password"
          type="password"
          placeholder="Contraseña"
          required
        />
        <button type="submit" class="btn-login" :disabled="loading">
        {{ loading ? 'Iniciando sesión...' : 'Iniciar sesión' }}
      </button>
      </form>
    </div>
    <AppFooter variant="login" />
  </div>
</template>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(135deg, #0d47a1 0%, #1565c0 50%, #1976d2 100%);
  padding: 2rem 0;
}
.login-page > .login-card {
  flex: 0 0 auto;
}
.login-card {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
  max-width: 400px;
  width: 90%;
}
@media (max-width: 480px) {
  .login-page {
    padding: 1rem 0.75rem;
  }
  .login-card {
    padding: 1.5rem;
    width: 100%;
  }
  .login-card h1 {
    font-size: 1.25rem;
  }
}
.login-logo {
  display: block;
  margin: 0 auto 1rem;
  height: 48px;
  width: auto;
}
.login-card h1 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #0d47a1;
  text-align: center;
}
.subtitle {
  color: #64748b;
  margin-bottom: 1.5rem;
  text-align: center;
}
.login-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.login-form label {
  font-weight: 500;
  color: #374151;
  font-size: 0.9rem;
}
.login-form input {
  padding: 0.75rem 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
}
.login-form input:focus {
  outline: none;
  border-color: #1565c0;
  box-shadow: 0 0 0 3px rgba(21, 101, 192, 0.2);
}
.error-msg {
  background: #fef2f2;
  color: #dc2626;
  padding: 0.5rem 0.75rem;
  border-radius: 6px;
  font-size: 0.9rem;
}
.btn-login {
  padding: 0.75rem 1.5rem;
  background: #1565c0;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}
.btn-login:hover {
  background: #0d47a1;
}
</style>
