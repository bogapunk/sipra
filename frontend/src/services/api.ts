import axios from 'axios'
import { useAuth } from '@/composables/useAuth'

export const api = axios.create({
  baseURL: (import.meta.env.VITE_API_BASE_URL as string) || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Caché para catálogos y listados (5 min TTL) - acelera navegación entre paneles
// Excluidos: areas, secretarias, usuarios, roles, backup-restore (paneles que requieren datos siempre frescos)
const CACHE_TTL_MS = 5 * 60 * 1000
const cache = new Map<string, { data: unknown; timestamp: number }>()
const CACHEABLE = [
  /^usuarios\/selector\/?(\?|$)/,
  /^ejes\/?(\?|$)/, /^planes\/?(\?|$)/, /^planes\/\d+\/?(\?|$)/,
  /^programas\/?(\?|$)/, /^programas\/[\w-]+\/?(\?|$)/,
  /^objetivos-estrategicos\/\d+\/?(\?|$)/,
  /^objetivos-estrategicos\/?(\?|$)/, /^indicadores\/?(\?|$)/,
  /^dashboard\/proyectos\/\d+\//,
  // dashboard/proyectos/ NO cacheado: el Dashboard debe mostrar siempre el conteo real
  /^dashboard\/usuarios\/\d+\/proyectos\/?(\?|$)/,
  /^tareas\/?(\?|$)/, /^planificacion\/arbol\/?(\?|$)/,
  /^avances\/por-area\/?(\?|$)/, /^avances\/por-secretaria\/?(\?|$)/,
  /^proyecto-area\/?(\?|$)/, /^proyecto-equipo\/?(\?|$)/,
  /^etapas\/?(\?|$)/, /^historial\/?(\?|$)/,
  /^comentarios-proyecto\/?(\?|$)/,
]
function cacheKey(url: string, params?: Record<string, unknown>): string {
  if (!params || !Object.keys(params).length) return url
  return `${url}?${new URLSearchParams(params as Record<string, string>).toString()}`
}
function isCacheable(url: string): boolean {
  return CACHEABLE.some((p) => p.test(url))
}
const originalGet = api.get.bind(api)
api.get = function (url: string, config?: { params?: Record<string, unknown> }) {
  const key = cacheKey(url, config?.params)
  const entry = cache.get(key)
  if (entry && Date.now() - entry.timestamp < CACHE_TTL_MS) {
    return Promise.resolve({
      data: entry.data,
      status: 200,
      statusText: 'OK',
      headers: {},
      config: { url, params: config?.params } as never,
    })
  }
  return originalGet(url, config).then((res) => {
    if (isCacheable(url)) cache.set(key, { data: res.data, timestamp: Date.now() })
    return res
  })
} as typeof api.get

/** Invalida caché (ej. tras crear/editar). */
export function invalidateApiCache(pattern?: string) {
  if (!pattern) {
    cache.clear()
    return
  }
  for (const k of cache.keys()) {
    if (k.startsWith(pattern)) cache.delete(k)
  }
}

api.interceptors.request.use((config) => {
  // Tras POST/PATCH/PUT/DELETE, limpiamos caché para forzar refresco de paneles.
  const method = (config.method || 'get').toLowerCase()
  if (method !== 'get') {
    invalidateApiCache()
  }
  const token = localStorage.getItem('sistema_proyectos_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  if (config.data instanceof FormData) {
    delete config.headers['Content-Type']
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && !error.config.url?.includes('/auth/login')) {
      const { logout } = useAuth()
      logout()
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)
