import { onMounted, onUnmounted, watch } from 'vue'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'

const SESSION_KEY = 'sistema_proyectos_session'
const HEARTBEAT_INTERVAL_MS = 2 * 60 * 1000 // 2 minutos

let heartbeatTimer: ReturnType<typeof setInterval> | null = null

function getOrCreateSessionKey(): string {
  let key = sessionStorage.getItem(SESSION_KEY)
  if (!key) {
    key = `sess_${Date.now()}_${Math.random().toString(36).slice(2, 12)}`
    sessionStorage.setItem(SESSION_KEY, key)
  }
  return key
}

async function sendHeartbeat() {
  const sessionKey = getOrCreateSessionKey()
  try {
    await api.post('backup-restore/session/heartbeat/', {
      session_key: sessionKey,
    })
  } catch {
    // Silenciar errores de heartbeat
  }
}

async function endSession() {
  const sessionKey = sessionStorage.getItem(SESSION_KEY)
  if (sessionKey) {
    try {
      await api.post('backup-restore/session/end/', { session_key: sessionKey })
    } catch {
      /* ignorar */
    }
    sessionStorage.removeItem(SESSION_KEY)
  }
}

export function useSessionHeartbeat() {
  const { user } = useAuth()

  function startHeartbeat() {
    if (heartbeatTimer) return
    const u = user.value
    if (!u?.id) return

    sendHeartbeat()

    heartbeatTimer = setInterval(() => {
      const current = user.value
      if (current?.id) {
        sendHeartbeat()
      } else {
        stopHeartbeat()
      }
    }, HEARTBEAT_INTERVAL_MS)
  }

  function stopHeartbeat() {
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer)
      heartbeatTimer = null
    }
  }

  watch(
    () => user.value?.id,
    (id) => {
      if (id) {
        startHeartbeat()
      } else {
        stopHeartbeat()
      }
    },
    { immediate: true }
  )

  onMounted(() => {
    if (user.value?.id) startHeartbeat()
  })

  onUnmounted(() => {
    stopHeartbeat()
  })

  return {
    startHeartbeat,
    stopHeartbeat,
    endSession,
  }
}
