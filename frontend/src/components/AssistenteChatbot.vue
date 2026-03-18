<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { obtenerAyuda } from '@/data/ayudaContextual'
import {
  buscarRespuesta,
  obtenerSugerenciasPorRuta,
  type RespuestaChatbot,
} from '@/data/baseConocimientoChatbot'

const route = useRoute()
const { user } = useAuth()
const mostrarChatbot = computed(() => !!user.value)
const abierto = ref(false)
const pregunta = ref('')
const mensajes = ref<{ tipo: 'usuario' | 'bot'; texto: string; respuesta?: RespuestaChatbot }[]>([])
const enviando = ref(false)

const ayudaContextual = computed(() => obtenerAyuda(route.path))
const sugerencias = computed(() => obtenerSugerenciasPorRuta(route.path))

watch(() => route.path, () => {
  if (abierto.value) {
    abierto.value = true
  }
})

function formatearRespuesta(r: RespuestaChatbot): string {
  let html = ''
  if (r.titulo) html += `<strong>${r.titulo}</strong><br><br>`
  html += r.contenido
  if (r.pasos?.length) {
    html += '<br><br><strong>Cómo hacerlo:</strong><ol>'
    r.pasos.forEach((p) => { html += `<li>${p}</li>` })
    html += '</ol>'
  }
  if (r.ejemplo) {
    html += `<br><br><em>Ejemplo: ${r.ejemplo}</em>`
  }
  if (r.modulo) {
    html += `<br><br><span class="modulo-tag">Módulo: ${r.modulo}</span>`
  }
  return html
}

function enviarPregunta() {
  const texto = pregunta.value.trim()
  if (!texto || enviando.value) return

  mensajes.value.push({ tipo: 'usuario', texto })
  pregunta.value = ''
  enviando.value = true

  const respuesta = buscarRespuesta(texto)
  if (respuesta) {
    mensajes.value.push({
      tipo: 'bot',
      texto: formatearRespuesta(respuesta),
      respuesta,
    })
  } else {
    mensajes.value.push({
      tipo: 'bot',
      texto: 'No encontré una respuesta específica para su pregunta. Intente reformularla o elija una de las sugerencias según el módulo actual. También puede revisar la ayuda contextual de esta pantalla.',
    })
  }
  enviando.value = false

  setTimeout(() => {
    const cont = document.querySelector('.chat-mensajes')
    if (cont) cont.scrollTop = cont.scrollHeight
  }, 50)
}

function usarSugerencia(s: string) {
  pregunta.value = s
}

function limpiarChat() {
  mensajes.value = []
}
</script>

<template>
  <div v-if="mostrarChatbot" class="assistente-wrap">
    <button
      type="button"
      class="assistente-btn"
      :class="{ abierto }"
      :title="abierto ? 'Cerrar asistente' : 'Abrir asistente'"
      @click="abierto = !abierto"
    >
      <span class="assistente-icono">{{ abierto ? '✕' : '?' }}</span>
    </button>

    <Transition name="panel">
      <div v-if="abierto" class="assistente-panel">
        <div class="assistente-header">
          <h3>Asistente del sistema</h3>
          <p class="assistente-sub">Pregunte sobre módulos, procesos y permisos</p>
        </div>

        <div class="assistente-contenido">
          <!-- Ayuda contextual rápida -->
          <div v-if="ayudaContextual" class="ayuda-rapida">
            <h4>{{ ayudaContextual.titulo }}</h4>
            <p class="ayuda-desc">{{ ayudaContextual.descripcion }}</p>
          </div>

          <!-- Chat -->
          <div class="chat-seccion">
            <div class="chat-mensajes" v-if="mensajes.length">
              <div
                v-for="(m, i) in mensajes"
                :key="i"
                class="mensaje"
                :class="m.tipo"
              >
                <span v-if="m.tipo === 'usuario'" class="mensaje-texto">{{ m.texto }}</span>
                <span
                  v-else
                  class="mensaje-texto bot-html"
                  v-html="m.texto"
                />
              </div>
            </div>

            <div v-else class="chat-bienvenida">
              <p>Escriba su pregunta o elija una sugerencia:</p>
              <div class="sugerencias">
                <button
                  v-for="(s, i) in sugerencias"
                  :key="i"
                  type="button"
                  class="btn-sugerencia"
                  @click="usarSugerencia(s)"
                >
                  {{ s }}
                </button>
              </div>
            </div>

            <form class="chat-form" @submit.prevent="enviarPregunta">
              <input
                v-model="pregunta"
                type="text"
                placeholder="Ej: ¿Cómo reasigno un proyecto?"
                class="chat-input"
                :disabled="enviando"
              />
              <button type="submit" class="chat-enviar" :disabled="!pregunta.trim() || enviando">
                Enviar
              </button>
            </form>
            <button v-if="mensajes.length" type="button" class="btn-limpiar" @click="limpiarChat">
              Limpiar conversación
            </button>
          </div>
        </div>

        <div class="assistente-footer">
          <span class="assistente-leyenda">SIP-AIF - Sistema Integral de Proyectos</span>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.assistente-wrap {
  position: fixed;
  bottom: clamp(1.25rem, 3vw, 1.5rem);
  right: clamp(1.25rem, 3vw, 1.5rem);
  z-index: 999;
}

.assistente-btn {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: linear-gradient(135deg, #0d47a1 0%, #1565c0 100%);
  color: white;
  border: none;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(13, 71, 161, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.4rem;
  font-weight: 700;
  transition: transform 0.2s, box-shadow 0.2s;
}

.assistente-btn:hover {
  transform: scale(1.05);
  box-shadow: 0 6px 20px rgba(13, 71, 161, 0.5);
}

.assistente-btn.abierto {
  background: linear-gradient(135deg, #475569 0%, #64748b 100%);
}

.assistente-panel {
  position: absolute;
  bottom: 60px;
  right: 0;
  width: min(380px, calc(100vw - 2.5rem));
  max-height: min(520px, calc(100vh - 8rem));
  background: white;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12), 0 2px 8px rgba(0, 0, 0, 0.06);
  border: 1px solid rgba(226, 232, 240, 0.8);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.assistente-header {
  padding: 1rem 1.25rem;
  background: linear-gradient(135deg, #0d47a1 0%, #1565c0 100%);
  color: white;
  flex-shrink: 0;
}

.assistente-header h3 {
  margin: 0;
  font-size: 1.1rem;
}

.assistente-sub {
  margin: 0.25rem 0 0;
  font-size: 0.8rem;
  opacity: 0.9;
}

.assistente-contenido {
  padding: 0.75rem 1rem;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.ayuda-rapida {
  padding: 0.6rem 0.75rem;
  background: #f0f9ff;
  border-radius: 8px;
  border-left: 4px solid #0d47a1;
}

.ayuda-rapida h4 {
  margin: 0 0 0.35rem;
  font-size: 0.95rem;
  color: #1e293b;
}

.ayuda-desc {
  margin: 0;
  font-size: 0.85rem;
  color: #475569;
  line-height: 1.45;
}

.chat-seccion {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.chat-mensajes {
  max-height: 220px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  padding: 0.5rem 0;
}

.mensaje {
  padding: 0.5rem 0.75rem;
  border-radius: 8px;
  font-size: 0.88rem;
  line-height: 1.45;
}

.mensaje.usuario {
  background: #e0f2fe;
  color: #0369a1;
  margin-left: 1.5rem;
  align-self: flex-end;
}

.mensaje.bot {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  margin-right: 1.5rem;
  align-self: flex-start;
}

.mensaje-texto {
  display: block;
}

.bot-html :deep(strong) {
  color: #1e293b;
}

.bot-html :deep(ol) {
  margin: 0.35rem 0 0;
  padding-left: 1.2rem;
}

.bot-html :deep(li) {
  margin-bottom: 0.2rem;
}

.bot-html :deep(em) {
  color: #64748b;
  font-size: 0.85rem;
}

.bot-html :deep(.modulo-tag) {
  font-size: 0.75rem;
  color: #94a3b8;
}

.chat-bienvenida p {
  margin: 0 0 0.5rem;
  font-size: 0.88rem;
  color: #64748b;
}

.sugerencias {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.btn-sugerencia {
  padding: 0.4rem 0.6rem;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.82rem;
  color: #475569;
  text-align: left;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}

.btn-sugerencia:hover {
  background: #f0f9ff;
  border-color: #0d47a1;
  color: #0d47a1;
}

.chat-form {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

.chat-input {
  flex: 1;
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
}

.chat-input:focus {
  outline: none;
  border-color: #0d47a1;
}

.chat-enviar {
  padding: 0.5rem 1rem;
  background: #0d47a1;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
}

.chat-enviar:hover:not(:disabled) {
  background: #1565c0;
}

.chat-enviar:disabled {
  background: #94a3b8;
  cursor: not-allowed;
}

.btn-limpiar {
  font-size: 0.75rem;
  color: #94a3b8;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.25rem 0;
  align-self: flex-start;
}

.btn-limpiar:hover {
  color: #64748b;
}

.assistente-footer {
  padding: 0.6rem 1.25rem;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.assistente-leyenda {
  font-size: 0.75rem;
  color: #94a3b8;
}

.panel-enter-active,
.panel-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.panel-enter-from,
.panel-leave-to {
  opacity: 0;
  transform: translateY(8px);
}

/* Responsive: panel más estrecho en móvil */
@media (max-width: 480px) {
  .assistente-wrap {
    bottom: 1rem;
    right: 1rem;
  }
  .assistente-btn {
    width: 48px;
    height: 48px;
    font-size: 1.2rem;
  }
  .assistente-panel {
    width: calc(100vw - 2rem);
    max-width: 380px;
    right: 0;
    bottom: 56px;
    max-height: 70vh;
  }
}
</style>
