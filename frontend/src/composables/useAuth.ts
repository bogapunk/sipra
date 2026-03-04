import { ref, computed } from 'vue'

export type RolNombre = 'Administrador' | 'Visualización' | 'Carga'

export interface User {
  id: number
  nombre: string
  apellido?: string
  nombreCompleto?: string
  email: string
  rol: number
  rolNombre?: RolNombre
  area?: number
  areaNombre?: string
  secretaria?: number
  secretariaNombre?: string
}

const user = ref<User | null>(null)
const STORAGE_KEY = 'sistema_proyectos_user'
const TOKEN_KEY = 'sistema_proyectos_token'

export function useAuth() {
  const isAdmin = computed(() => user.value?.rolNombre === 'Administrador')
  const isVisualizador = computed(() => user.value?.rolNombre === 'Visualización')
  const isCarga = computed(() => user.value?.rolNombre === 'Carga')

  function setUser(u: User | null, token?: string) {
    user.value = u
    if (u) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(u))
      if (token) {
        localStorage.setItem(TOKEN_KEY, token)
      }
    } else {
      localStorage.removeItem(STORAGE_KEY)
      localStorage.removeItem(TOKEN_KEY)
    }
  }

  function getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY)
  }

  function loadStoredUser() {
    const stored = localStorage.getItem(STORAGE_KEY)
    const token = localStorage.getItem(TOKEN_KEY)
    if (stored && token) {
      try {
        user.value = JSON.parse(stored)
      } catch {
        user.value = null
        localStorage.removeItem(TOKEN_KEY)
      }
    } else {
      user.value = null
    }
  }

  function logout() {
    user.value = null
    localStorage.removeItem(STORAGE_KEY)
    localStorage.removeItem(TOKEN_KEY)
  }

  loadStoredUser()

  return {
    user: computed(() => user.value),
    isAdmin,
    isVisualizador,
    isCarga,
    setUser,
    logout,
    getToken,
  }
}
