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

function mapUserPayload(u: Record<string, unknown>): User {
  return {
    id: Number(u.id),
    nombre: String(u.nombre || ''),
    apellido: String(u.apellido || ''),
    nombreCompleto: String(u.nombreCompleto || `${u.nombre || ''} ${u.apellido || ''}`.trim()),
    email: String(u.email || ''),
    rol: Number(u.rol || 0),
    rolNombre: u.rolNombre as RolNombre | undefined,
    area: u.area ? Number(u.area) : undefined,
    areaNombre: u.areaNombre ? String(u.areaNombre) : undefined,
    secretaria: u.secretaria ? Number(u.secretaria) : undefined,
    secretariaNombre: u.secretariaNombre ? String(u.secretariaNombre) : undefined,
  }
}

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
        localStorage.removeItem(STORAGE_KEY)
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

  async function syncUserFromServer(): Promise<boolean> {
    const token = getToken()
    if (!token) {
      logout()
      return false
    }
    const baseUrl = ((import.meta.env.VITE_API_BASE_URL as string) || '/api').replace(/\/+$/, '')
    try {
      const response = await fetch(`${baseUrl}/auth/me/`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      })
      if (!response.ok) {
        logout()
        return false
      }
      const data = await response.json() as { success?: boolean; user?: Record<string, unknown> }
      if (!data?.success || !data.user) {
        logout()
        return false
      }
      setUser(mapUserPayload(data.user), token)
      return true
    } catch {
      logout()
      return false
    }
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
    syncUserFromServer,
  }
}
