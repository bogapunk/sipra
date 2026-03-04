<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useModalClose } from '@/composables/useModalClose'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import { estadoVencimiento, claseVencimiento } from '@/utils/vencimiento'
import { extraerMensajeError } from '@/utils/apiError'
import EmptyState from '@/components/EmptyState.vue'

function tareasOrdenadas(tareas: Record<string, unknown>[]): { tarea: Record<string, unknown>; esSubtarea: boolean }[] {
  const resultado: { tarea: Record<string, unknown>; esSubtarea: boolean }[] = []
  const raices = tareas.filter((t) => !t.tarea_padre)
  for (const t of raices) {
    resultado.push({ tarea: t, esSubtarea: false })
    for (const h of (t.subtareas as Record<string, unknown>[]) || []) {
      resultado.push({ tarea: h, esSubtarea: true })
    }
  }
  const idsIncluidos = new Set(resultado.map((r) => r.tarea.id))
  for (const t of tareas) {
    if (t.tarea_padre && !idsIncluidos.has(t.id)) {
      resultado.push({ tarea: t, esSubtarea: true })
    }
  }
  return resultado
}

const { user, isAdmin } = useAuth()
const MINUTOS_EDICION = 15

function puedeEditarEliminarComentario(c: Record<string, unknown>): boolean {
  if (!user.value) return false
  if (isAdmin.value) return true
  if ((c.usuario as number) !== user.value.id) return false
  const fecha = new Date((c.fecha as string) || 0).getTime()
  const ahora = Date.now()
  return (ahora - fecha) / 60000 <= MINUTOS_EDICION
}
const toast = useToast()
const { confirmDelete } = useConfirmDelete()
const tareas = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const showModal = ref(false)

const buscarProyecto = ref('')

const TAREA_PARTICULAR = 'Tarea Particular'

const tareasPorProyecto = computed(() => {
  const grupos: Record<string, { proyecto_id: number | null; proyecto_nombre: string; esParticular: boolean; tareas: Record<string, unknown>[] }> = {}
  for (const t of tareas.value) {
    const proyId = t.proyecto as number | null
    const esParticular = proyId == null
    const proyNombre = (t.proyecto_nombre as string) || (esParticular ? TAREA_PARTICULAR : 'Proyecto')
    const key = proyId != null ? String(proyId) : '__sin_proyecto__'
    if (!grupos[key]) {
      grupos[key] = { proyecto_id: proyId, proyecto_nombre: proyNombre, esParticular, tareas: [] }
    }
    grupos[key].tareas.push(t)
  }
  return Object.values(grupos)
})

// Solo proyectos asignados al usuario: intersección entre tareas del usuario y proyectos asignados
const proyectosVisiblesBase = computed(() => {
  const grupos = tareasPorProyecto.value
  const idsAsignados = new Set(proyectos.value.map((p) => p.id as number))
  if (idsAsignados.size === 0) return grupos
  return grupos.filter((g) => g.proyecto_id == null || idsAsignados.has(g.proyecto_id))
})

// Filtrar por búsqueda: proyecto, "Tarea Particular" o título de tarea
const proyectosVisibles = computed(() => {
  const q = buscarProyecto.value.trim().toLowerCase()
  if (!q) return proyectosVisiblesBase.value

  return proyectosVisiblesBase.value
    .map((g) => {
      const proyectoCoincide =
        (g.proyecto_nombre || '').toLowerCase().includes(q) ||
        (g.esParticular && 'tarea particular'.includes(q))

      const tareasCoinciden = g.tareas.filter((t) =>
        String(t.titulo || '').toLowerCase().includes(q)
      )

      if (proyectoCoincide) {
        return { ...g, tareas: g.tareas }
      }
      if (tareasCoinciden.length > 0) {
        return { ...g, tareas: tareasCoinciden }
      }
      return null
    })
    .filter(Boolean)
})
const tareaEdit = ref<Record<string, unknown> | null>(null)
const historialTarea = ref<Record<string, unknown>[]>([])
const comentariosTarea = ref<Record<string, unknown>[]>([])
const adjuntosTarea = ref<Record<string, unknown>[]>([])
const nuevoComentarioTarea = ref('')
const comentarioEditando = ref<number | null>(null)
const textoEditando = ref('')
const archivoAdjunto = ref<HTMLInputElement | null>(null)
const subiendoAdjunto = ref(false)
const adjuntoEditando = ref<number | null>(null)
const nombreAdjuntoEditando = ref('')

function puedeModificarAdjunto(a: Record<string, unknown>): boolean {
  if (!user.value) return false
  if (isAdmin.value) return true
  return (a.subido_por as number) === user.value.id
}
const formAvance = ref({ porcentaje_avance: 0, comentario: '' })
const carga = ref(false)
const error = ref('')

function parseList(res: unknown): unknown[] {
  if (!res || typeof res !== 'object') return []
  const d = 'data' in res ? (res as { data: unknown }).data : res
  if (Array.isArray(d)) return d
  if (d && typeof d === 'object' && 'results' in d) return (d as { results: unknown[] }).results
  return []
}

function mensajeError(e: unknown): string {
  const err = e as { response?: { status?: number; data?: unknown }; message?: string; code?: string }
  if (err.code === 'ERR_NETWORK' || err.message?.includes('Network Error')) {
    return 'No se pudo conectar al servidor. Verifique que el backend esté ejecutándose en el puerto 8001 (ejecute iniciar-sistema.bat o: cd backend && python manage.py runserver 8001).'
  }
  const status = err.response?.status
  const data = err.response?.data
  if (status === 404) return 'Recurso no encontrado. Verifique la configuración del backend.'
  if (status && status >= 500) {
    const det = data && typeof data === 'object' && 'detail' in (data as object) ? String((data as { detail: unknown }).detail) : ''
    return `Error del servidor (${status}). ${det || 'Verifique los logs del backend.'}`
  }
  const det = data && typeof data === 'object' && 'detail' in (data as object) ? String((data as { detail: unknown }).detail) : ''
  return det || err.message || 'Error al cargar. Verifique su conexión.'
}

async function load() {
  if (!user.value) return
  carga.value = true
  error.value = ''
  try {
    // Solo tareas y proyectos asignados al usuario (rol Carga no ve el resto del sistema)
    const params: Record<string, number> = { usuario: user.value.id }
    const [tRes, pRes] = await Promise.all([
      api.get('tareas/', { params }),
      api.get(`dashboard/usuarios/${user.value.id}/proyectos/`),
    ])
    tareas.value = parseList(tRes) as Record<string, unknown>[]
    const pData = (pRes as { data?: { proyectos?: unknown[] } }).data
    proyectos.value = (Array.isArray(pData?.proyectos) ? pData.proyectos : parseList(pRes)) as Record<string, unknown>[]
  } catch (e) {
    tareas.value = []
    proyectos.value = []
    error.value = mensajeError(e)
  } finally {
    carga.value = false
  }
}

onMounted(load)

async function openModal(tarea: Record<string, unknown>) {
  tareaEdit.value = tarea
  formAvance.value = {
    porcentaje_avance: (tarea.porcentaje_avance as number) || 0,
    comentario: '',
  }
  historialTarea.value = []
  comentariosTarea.value = []
  adjuntosTarea.value = []
  nuevoComentarioTarea.value = ''
  try {
    const [histRes, comRes, adjRes] = await Promise.all([
      api.get('historial/', { params: { tarea: tarea.id } }),
      api.get('comentarios-tarea/', { params: { tarea: tarea.id } }),
      api.get('adjuntos-tarea/', { params: { tarea: tarea.id } }),
    ])
    const raw = Array.isArray(histRes.data) ? histRes.data : (histRes.data?.results || [])
    historialTarea.value = (raw as Record<string, unknown>[]).sort((a, b) => {
      const fa = (a.fecha as string) || ''
      const fb = (b.fecha as string) || ''
      return fb.localeCompare(fa)
    })
    comentariosTarea.value = Array.isArray(comRes.data) ? comRes.data : (comRes.data?.results || [])
    adjuntosTarea.value = Array.isArray(adjRes.data) ? adjRes.data : (adjRes.data?.results || [])
  } catch {
    historialTarea.value = []
    comentariosTarea.value = []
    adjuntosTarea.value = []
  }
  showModal.value = true
}

function formatearFecha(f: unknown): string {
  if (!f) return '-'
  const s = typeof f === 'string' ? f : String(f)
  try {
    const d = new Date(s)
    if (isNaN(d.getTime())) return s
    return d.toLocaleDateString('es-CL', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
  } catch {
    return s
  }
}

function closeModal() {
  showModal.value = false
  tareaEdit.value = null
  comentarioEditando.value = null
  textoEditando.value = ''
  adjuntoEditando.value = null
  nombreAdjuntoEditando.value = ''
}
useModalClose(showModal, closeModal)

async function guardarComentarioTarea() {
  const t = tareaEdit.value
  if (!t || !user.value || !nuevoComentarioTarea.value.trim()) return
  try {
    await api.post('comentarios-tarea/', {
      tarea: t.id,
      texto: nuevoComentarioTarea.value.trim(),
    })
    nuevoComentarioTarea.value = ''
    const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
    comentariosTarea.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Comentario guardado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al guardar el comentario.'))
  }
}

function iniciarEdicionComentario(c: Record<string, unknown>) {
  comentarioEditando.value = c.id as number
  textoEditando.value = (c.texto as string) || ''
}

function cancelarEdicionComentario() {
  comentarioEditando.value = null
  textoEditando.value = ''
}

async function guardarEdicionComentarioTarea() {
  const t = tareaEdit.value
  const id = comentarioEditando.value
  if (!t || !id || !textoEditando.value.trim()) return
  try {
    await api.patch(`comentarios-tarea/${id}/`, { texto: textoEditando.value.trim() })
    const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
    comentariosTarea.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    comentarioEditando.value = null
    textoEditando.value = ''
    toast.success('Comentario actualizado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al actualizar el comentario.'))
  }
}

async function eliminarComentarioTarea(c: Record<string, unknown>) {
  const t = tareaEdit.value
  if (!t || !(await confirmDelete())) return
  try {
    await api.delete(`comentarios-tarea/${c.id}/`)
    const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
    comentariosTarea.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Comentario eliminado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al eliminar el comentario.'))
  }
}

function iniciarEdicionAdjunto(a: Record<string, unknown>) {
  adjuntoEditando.value = a.id as number
  nombreAdjuntoEditando.value = (a.nombre_original as string) || ''
}

function cancelarEdicionAdjunto() {
  adjuntoEditando.value = null
  nombreAdjuntoEditando.value = ''
}

async function guardarEdicionAdjunto() {
  const t = tareaEdit.value
  const id = adjuntoEditando.value
  if (!t || !id || !nombreAdjuntoEditando.value.trim()) return
  try {
    await api.patch(`adjuntos-tarea/${id}/`, { nombre_original: nombreAdjuntoEditando.value.trim() })
    const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
    adjuntosTarea.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    adjuntoEditando.value = null
    nombreAdjuntoEditando.value = ''
    toast.success('Adjunto actualizado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al actualizar el adjunto.'))
  }
}

async function eliminarAdjunto(a: Record<string, unknown>) {
  const t = tareaEdit.value
  if (!t || !(await confirmDelete())) return
  try {
    await api.delete(`adjuntos-tarea/${a.id}/`)
    const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
    adjuntosTarea.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Adjunto eliminado.')
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al eliminar el adjunto.'))
  }
}

async function subirAdjunto() {
  const t = tareaEdit.value
  const input = archivoAdjunto.value
  if (!t || !user.value || !input?.files?.length) return
  const file = input.files[0]
  if (!file) return
  subiendoAdjunto.value = true
  try {
    const formData = new FormData()
    formData.append('tarea', String(t.id))
    formData.append('archivo', file)
    formData.append('nombre_original', file.name)
    await api.post('adjuntos-tarea/', formData)
    const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
    adjuntosTarea.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    toast.success('Archivo subido correctamente.')
    input.value = ''
  } catch {
    toast.error('Error al subir el archivo.')
  } finally {
    subiendoAdjunto.value = false
  }
}

async function saveAvance() {
  if (!tareaEdit.value || !user.value) return
  const num = formAvance.value.porcentaje_avance
  if (num < 0 || num > 100) {
    toast.error('Ingrese un número entre 0 y 100')
    return
  }
  const valorAnterior = (tareaEdit.value.porcentaje_avance as number) ?? 0
  const esCierre = num === 100
  try {
    const payload: Record<string, unknown> = { porcentaje_avance: num }
    if (esCierre) payload.estado = 'Finalizada'
    await api.patch(`tareas/${tareaEdit.value.id}/`, payload)
    tareaEdit.value.porcentaje_avance = num
    if (esCierre) tareaEdit.value.estado = 'Finalizada'
    await api.post('historial/', {
      tarea: tareaEdit.value.id,
      usuario: user.value.id,
      comentario: formAvance.value.comentario.trim() || '',
      porcentaje_avance: num,
      porcentaje_anterior: valorAnterior,
    })
    let proyectoFinalizado = false
    if (esCierre) {
      const proyId = tareaEdit.value.proyecto as number | null
      const tareasProy = proyId != null
        ? tareas.value.filter((t: Record<string, unknown>) => t.proyecto === proyId)
        : []
      const todas100 = tareasProy.length > 0 && tareasProy.every((t: Record<string, unknown>) =>
        ((t.id as number) === (tareaEdit.value!.id as number) ? 100 : (t.porcentaje_avance as number)) === 100
      )
      if (todas100) {
        await api.patch(`proyectos/${proyId}/`, { estado: 'Finalizado' })
        proyectoFinalizado = true
      }
    }
    const msg = esCierre
      ? (proyectoFinalizado ? 'Avance guardado. Tarea y proyecto marcados como Finalizados.' : 'Avance guardado. Tarea marcada como Finalizada.')
      : 'Avance actualizado correctamente.'
    toast.success(msg)
    closeModal()
    load()
  } catch (e) {
    toast.error(mensajeError(e))
  }
}
</script>

<template>
  <div class="page">
    <h1>Cargar avances</h1>
    <p class="subtitle">Solo los proyectos asignados a su área o como responsable. Actualice el avance de cada tarea para avanzar en el proyecto.</p>
    <p v-if="user?.areaNombre" class="area-info">Áreas que puede gestionar: <strong>{{ user.areaNombre }}</strong></p>

    <div class="vencimiento-leyenda">
      <span class="leyenda-item vencida">Vencida</span>
      <span class="leyenda-item proxima">Próxima a vencer (7 días)</span>
      <span class="leyenda-item dentro">Dentro del plazo</span>
      <span class="leyenda-sep">|</span>
      <span class="leyenda-item jerarquia">
        <span class="leyenda-icono principal">▸</span> Tarea principal
      </span>
      <span class="leyenda-item jerarquia">
        <span class="leyenda-icono subtarea">↳</span> Subtarea
      </span>
    </div>
    <div class="header-actions">
      <input
        v-model="buscarProyecto"
        type="search"
        placeholder="Buscar por proyecto o título de tarea..."
        class="search-input"
      />
      <button type="button" class="btn-refresh" @click="load" :disabled="carga">
        {{ carga ? 'Cargando...' : 'Actualizar' }}
      </button>
    </div>

    <LoaderSpinner v-if="carga" texto="Cargando tareas y proyectos..." />

    <p v-else-if="error" class="error-msg">{{ error }}</p>

    <div v-else-if="proyectosVisibles.length" class="proyectos-container">
      <div v-for="grupo in proyectosVisibles" :key="grupo.proyecto_id ?? '__particular__'" class="proyecto-grupo" :class="{ 'grupo-tarea-particular': grupo.esParticular }">
        <h2 class="proyecto-titulo">
          <span class="tipo-badge" :class="grupo.esParticular ? 'tipo-tarea-particular' : 'tipo-proyecto'">
            {{ grupo.esParticular ? 'Tarea Particular' : 'Proyecto' }}
          </span>
          <span class="proyecto-icono">{{ grupo.esParticular ? '◉' : '▸' }}</span>
          {{ grupo.proyecto_nombre }}
          <span class="proyecto-badge">{{ grupo.tareas.length }} tarea(s)</span>
        </h2>
        <div class="tareas-list">
          <template v-for="item in tareasOrdenadas(grupo.tareas)" :key="(item.tarea.id as number)">
            <div
              class="tarea-card"
              :class="[
                claseVencimiento(estadoVencimiento(item.tarea.fecha_vencimiento, item.tarea.estado)),
                item.esSubtarea ? 'tarea-card-subtarea' : 'tarea-card-principal'
              ]"
            >
              <div class="tarea-info">
                <span class="tipo-badge" :class="item.esSubtarea ? 'tipo-subtarea' : 'tipo-tarea'">
                  {{ item.esSubtarea ? '↳ Subtarea' : '▸ Tarea' }}
                </span>
                <strong>{{ item.tarea.titulo }}</strong>
                <span class="tarea-meta">{{ item.tarea.area_nombre || '-' }} · {{ item.tarea.estado }} · {{ item.tarea.porcentaje_avance }}%</span>
              </div>
              <button class="btn-action" @click="openModal(item.tarea)">Actualizar avance</button>
            </div>
          </template>
        </div>
      </div>
    </div>
    <EmptyState
      v-else-if="buscarProyecto.trim() && proyectosVisiblesBase.length"
      titulo="Sin resultados"
      mensaje="No hay proyectos ni tareas que coincidan con la búsqueda. Intente con otros términos."
      icono="busqueda"
    />
    <EmptyState
      v-else
      titulo="No tiene tareas asignadas"
      mensaje="Verifique que: 1) tenga un área asignada en su perfil, o que sea responsable de tareas del proyecto; 2) las tareas del proyecto estén en su área o lo tengan como responsable."
      icono="tareas"
    />

    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal modal-avance">
        <h2>Actualizar avance</h2>
        <p v-if="tareaEdit" class="modal-subtitle">{{ tareaEdit.titulo }}</p>

        <div v-if="historialTarea.length" class="historial-section">
          <h3>Historial de cambios</h3>
          <p class="historial-leyenda">Fecha · Usuario · Valor anterior → Nuevo valor · Observaciones</p>
          <div class="historial-lista">
            <div
              v-for="h in historialTarea"
              :key="(h.id as number)"
              class="historial-item"
              :class="{ 'historial-item-cierre': Number(h.porcentaje_avance) === 100 }"
            >
              <span v-if="Number(h.porcentaje_avance) === 100" class="historial-badge-cierre">
                ✓ Tarea Finalizada
              </span>
              <span class="historial-fecha">{{ formatearFecha(h.fecha) }}</span>
              <span v-if="h.usuario_nombre" class="historial-usuario">{{ h.usuario_nombre }}</span>
              <span class="historial-valores">
                {{ h.porcentaje_anterior != null ? `${h.porcentaje_anterior}%` : '-' }} → {{ h.porcentaje_avance }}%
              </span>
              <p v-if="h.comentario" class="historial-comentario">{{ h.comentario }}</p>
            </div>
          </div>
        </div>

        <div class="historial-section">
          <h3>Historial de comentarios</h3>
          <p v-if="comentariosTarea.length" class="historial-leyenda">Orden cronológico (del más antiguo al más reciente)</p>
          <div v-if="comentariosTarea.length" class="historial-lista">
            <div v-for="c in comentariosTarea" :key="(c.id as number)" class="historial-item historial-item-comentario">
              <div class="comentario-header">
                <span class="historial-fecha">{{ formatearFecha(c.fecha) }}</span>
                <span v-if="c.usuario_nombre" class="historial-usuario">{{ c.usuario_nombre }}</span>
                <span v-if="c.editado_leyenda" class="editado-leyenda">{{ c.editado_leyenda }}</span>
                <div v-if="puedeEditarEliminarComentario(c)" class="comentario-acciones">
                  <button v-if="comentarioEditando !== c.id" type="button" class="btn-icon-mini" title="Editar" @click="iniciarEdicionComentario(c)">
                    <IconEdit class="btn-icon-sm" />
                  </button>
                  <button v-if="comentarioEditando !== c.id" type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarComentarioTarea(c)">
                    <IconTrash class="btn-icon-sm" />
                  </button>
                </div>
              </div>
              <template v-if="comentarioEditando === c.id">
                <textarea v-model="textoEditando" rows="2" class="edit-textarea" />
                <div class="edit-acciones">
                  <button type="button" class="btn-small" @click="guardarEdicionComentarioTarea">Guardar</button>
                  <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionComentario">Cancelar</button>
                </div>
              </template>
              <p v-else class="historial-comentario">{{ c.texto }}</p>
            </div>
          </div>
          <div class="comentario-add">
            <textarea v-model="nuevoComentarioTarea" placeholder="Agregar comentario..." rows="2" />
            <button type="button" class="btn-small" @click="guardarComentarioTarea" :disabled="!nuevoComentarioTarea.trim()">Enviar</button>
          </div>
        </div>

        <div class="historial-section">
          <h3>Adjuntos</h3>
          <div v-if="adjuntosTarea.length" class="adjuntos-lista">
            <div v-for="a in adjuntosTarea" :key="(a.id as number)" class="adjunto-item">
              <template v-if="adjuntoEditando === a.id">
                <input v-model="nombreAdjuntoEditando" type="text" class="adjunto-edit-input" />
                <div class="adjunto-edit-btns">
                  <button type="button" class="btn-small" @click="guardarEdicionAdjunto">Guardar</button>
                  <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionAdjunto">Cancelar</button>
                </div>
              </template>
              <template v-else>
                <a v-if="a.url" :href="a.url" target="_blank" rel="noopener" class="adjunto-link">📎 {{ a.nombre_original }}</a>
                <span v-else>📎 {{ a.nombre_original }}</span>
                <div v-if="puedeModificarAdjunto(a)" class="adjunto-acciones">
                  <button type="button" class="btn-icon-mini" title="Editar nombre" @click="iniciarEdicionAdjunto(a)"><IconEdit class="btn-icon-sm" /></button>
                  <button type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarAdjunto(a)"><IconTrash class="btn-icon-sm" /></button>
                </div>
              </template>
            </div>
          </div>
          <div class="adjunto-upload">
            <input ref="archivoAdjunto" type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.png,.jpg,.jpeg" @change="subirAdjunto" />
            <span v-if="subiendoAdjunto" class="adjunto-loading">Subiendo...</span>
          </div>
        </div>

        <form @submit.prevent="saveAvance">
          <label>Porcentaje de avance (0-100)</label>
          <input v-model.number="formAvance.porcentaje_avance" type="number" min="0" max="100" required />
          <label>Comentario (opcional)</label>
          <textarea v-model="formAvance.comentario" placeholder="Agregar comentario si lo desea" rows="3" />
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="closeModal"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 0.5rem; }
.subtitle { color: #64748b; margin-bottom: 0.5rem; }
.area-info { color: #3b82f6; font-size: 0.9rem; margin-bottom: 1rem; }
.vencimiento-leyenda {
  display: flex;
  gap: 1rem;
  margin-bottom: 0.75rem;
  font-size: 0.8rem;
  color: #64748b;
}
.leyenda-item {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
}
.leyenda-item::before {
  content: '';
  width: 12px;
  height: 12px;
  border-radius: 3px;
}
.leyenda-item.vencida::before { background: #dc2626; }
.leyenda-item.proxima::before { background: #eab308; }
.leyenda-item.dentro::before { background: #22c55e; }
.leyenda-sep { color: #cbd5e1; margin: 0 0.25rem; }
.leyenda-item.jerarquia { color: #64748b; }
.leyenda-item.jerarquia::before { display: none; }
.leyenda-icono.principal { color: #0d9488; font-weight: 700; margin-right: 0.2rem; }
.leyenda-icono.subtarea { color: #64748b; margin-right: 0.2rem; }
.tareas-list { display: flex; flex-direction: column; gap: 0.75rem; }
.tarea-card {
  padding: 1rem 1.25rem;
  border-radius: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
}
.tarea-card-principal {
  background: white;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  border-left: 4px solid #0d9488;
}
.tarea-card-subtarea {
  background: #f8fafc;
  border-left: 4px solid #94a3b8;
  margin-left: 2rem;
  border-radius: 6px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.04);
}
.tipo-subtarea {
  background: linear-gradient(135deg, #64748b 0%, #475569 100%);
  color: white;
  font-size: 0.65rem;
  padding: 0.15rem 0.4rem;
  align-self: flex-start;
}
.vencimiento-vencida { background-color: #fef2f2 !important; border-left: 4px solid #dc2626 !important; }
.vencimiento-proxima { background-color: #fffbeb !important; border-left: 4px solid #eab308 !important; }
.vencimiento-dentro-plazo { background-color: #f0fdf4 !important; border-left: 4px solid #22c55e !important; }
.tarea-card-subtarea.vencimiento-vencida { margin-left: 2rem; }
.tarea-card-subtarea.vencimiento-proxima { margin-left: 2rem; }
.tarea-card-subtarea.vencimiento-dentro-plazo { margin-left: 2rem; }
.header-actions {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}
.search-input {
  flex: 1;
  min-width: 200px;
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
}
.btn-refresh {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-refresh:disabled { opacity: 0.7; cursor: not-allowed; }
.proyectos-container { display: flex; flex-direction: column; gap: 1.5rem; }
.proyecto-grupo {
  background: #f8fafc;
  border-radius: 10px;
  padding: 1rem 1.25rem;
  border: 1px solid #e2e8f0;
}
.proyecto-grupo.grupo-tarea-particular {
  border-left: 4px solid #7c3aed;
  background: linear-gradient(135deg, #faf5ff 0%, #f5f3ff 100%);
}
.grupo-tarea-particular .proyecto-icono { color: #7c3aed; }
.proyecto-titulo {
  font-size: 1.1rem;
  margin: 0 0 0.75rem;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.tipo-badge {
  display: inline-block;
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  padding: 0.25rem 0.5rem;
  border-radius: 6px;
  margin-right: 0.5rem;
}
.tipo-proyecto {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  box-shadow: 0 1px 2px rgba(59, 130, 246, 0.3);
}
.tipo-tarea-particular {
  background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
  color: white;
  box-shadow: 0 1px 2px rgba(124, 58, 237, 0.3);
}
.tipo-tarea {
  background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
  color: white;
  font-size: 0.65rem;
  padding: 0.15rem 0.4rem;
  align-self: flex-start;
  margin-bottom: 0.2rem;
}
.proyecto-icono { color: #3b82f6; font-size: 0.9rem; }
.proyecto-badge {
  font-size: 0.8rem;
  background: #e2e8f0;
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
  margin-left: auto;
}
.tareas-list { display: flex; flex-direction: column; gap: 0.75rem; }
.tarea-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.tarea-info .tipo-tarea {
  width: fit-content;
}
.tarea-meta { font-size: 0.875rem; color: #64748b; }
.error-msg { color: #dc2626; background: #fef2f2; padding: 0.75rem; border-radius: 8px; margin-bottom: 1rem; }
.empty-msg { color: #64748b; }
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}
.modal {
  background: white;
  padding: 1.5rem;
  border-radius: 10px;
  max-width: 400px;
  width: 90%;
}
.modal h2 { margin-bottom: 0.5rem; }
.modal-subtitle { font-size: 0.9rem; color: #64748b; margin-bottom: 1rem; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.modal-avance { max-width: 480px; }
.historial-section {
  margin-bottom: 1.25rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e2e8f0;
}
.historial-section h3 {
  font-size: 0.95rem;
  margin: 0 0 0.5rem;
  color: #334155;
}
.historial-lista {
  max-height: 140px;
  overflow-y: auto;
  background: #f8fafc;
  border-radius: 8px;
  padding: 0.5rem;
}
.historial-item {
  padding: 0.5rem 0.6rem;
  border-bottom: 1px solid #e2e8f0;
  font-size: 0.85rem;
}
.historial-item:last-child { border-bottom: none; }
.historial-leyenda { font-size: 0.75rem; color: #94a3b8; margin: 0 0 0.5rem; }
.historial-item { display: flex; flex-wrap: wrap; align-items: baseline; gap: 0.35rem; }
.historial-fecha { color: #64748b; }
.historial-usuario { color: #475569; font-weight: 500; }
.historial-valores { font-weight: 700; color: #3b82f6; }
.historial-comentario { margin: 0.25rem 0 0; font-size: 0.8rem; color: #64748b; font-style: italic; }
.historial-item-comentario { flex-direction: column; align-items: stretch; }
.comentario-header { display: flex; flex-wrap: wrap; align-items: center; gap: 0.35rem; }
.editado-leyenda { font-size: 0.7rem; color: #94a3b8; font-style: italic; }
.comentario-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.btn-icon-mini { padding: 0.2rem 0.4rem; background: #e2e8f0; border: none; border-radius: 4px; cursor: pointer; }
.btn-icon-mini:hover { background: #cbd5e1; }
.btn-danger-mini:hover { background: #fecaca !important; }
.edit-textarea { width: 100%; padding: 0.4rem; font-size: 0.85rem; margin-top: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.edit-acciones { display: flex; gap: 0.5rem; margin-top: 0.5rem; }
.btn-cancel-mini { background: #94a3b8 !important; }
.historial-item-cierre {
  background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
  border-left: 4px solid #16a34a;
  border-radius: 6px;
  margin-bottom: 0.35rem;
  padding: 0.6rem 0.75rem;
}
.historial-badge-cierre {
  display: inline-block;
  background: #16a34a;
  color: white;
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
  margin-right: 0.5rem;
  margin-bottom: 0.25rem;
}
.comentario-add {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 0.5rem;
}
.comentario-add textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.9rem;
}
.btn-small {
  align-self: flex-start;
  padding: 0.35rem 0.75rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 0.85rem;
  cursor: pointer;
}
.btn-small:disabled { opacity: 0.6; cursor: not-allowed; }
.adjuntos-lista {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}
.adjunto-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.adjunto-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.adjunto-edit-input { flex: 1; min-width: 150px; padding: 0.35rem; font-size: 0.85rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.adjunto-edit-btns { display: flex; gap: 0.35rem; }
.adjunto-link {
  color: #2563eb;
  text-decoration: none;
  font-size: 0.9rem;
}
.adjunto-link:hover { text-decoration: underline; }
.adjunto-upload input[type="file"] { font-size: 0.85rem; }
.adjunto-loading { font-size: 0.85rem; color: #64748b; }
</style>
