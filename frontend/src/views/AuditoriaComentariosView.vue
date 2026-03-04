<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import { extraerMensajeError } from '@/utils/apiError'

const { isAdmin } = useAuth()
const toast = useToast()
const { confirmDelete } = useConfirmDelete()

const tabActivo = ref<'comentarios' | 'adjuntos' | 'log'>('comentarios')

// Comentarios
const comentariosProyecto = ref<Record<string, unknown>[]>([])
const comentariosTarea = ref<Record<string, unknown>[]>([])
const proyectos = ref<Record<string, unknown>[]>([])
const tareas = ref<Record<string, unknown>[]>([])
const cargaComentarios = ref(false)
const filtroTipo = ref<'todos' | 'proyecto' | 'tarea'>('todos')
const filtroProyecto = ref<number | null>(null)
const filtroTarea = ref<number | null>(null)
const comentarioEditando = ref<{ tipo: 'proyecto' | 'tarea'; id: number } | null>(null)
const textoEditando = ref('')

// Adjuntos
const adjuntosProyecto = ref<Record<string, unknown>[]>([])
const adjuntosTarea = ref<Record<string, unknown>[]>([])
const cargaAdjuntos = ref(false)
const filtroAdjTipo = ref<'todos' | 'proyecto' | 'tarea'>('todos')
const filtroAdjProyecto = ref<number | null>(null)
const filtroAdjTarea = ref<number | null>(null)
const adjuntoEditando = ref<{ tipo: 'proyecto' | 'tarea'; id: number } | null>(null)
const nombreEditando = ref('')

// Log de auditoría
const logAuditoria = ref<Record<string, unknown>[]>([])
const logAdjuntos = ref<Record<string, unknown>[]>([])
const cargaLog = ref(false)
const filtroLogEntidad = ref<'todos' | 'comentario' | 'adjunto'>('todos')
const filtroLogTipo = ref('')
const filtroLogProyecto = ref<number | null>(null)
const filtroLogTarea = ref<number | null>(null)
const filtroLogUsuario = ref<number | null>(null)
const filtroLogFechaDesde = ref('')
const filtroLogFechaHasta = ref('')
const usuarios = ref<Record<string, unknown>[]>([])

function parseList(res: unknown): unknown[] {
  if (!res || typeof res !== 'object') return []
  const d = 'data' in res ? (res as { data: unknown }).data : res
  if (Array.isArray(d)) return d
  if (d && typeof d === 'object' && 'results' in d) return (d as { results: unknown[] }).results
  return []
}

const comentariosUnificados = computed(() => {
  const lista: { tipo: 'proyecto' | 'tarea'; item: Record<string, unknown> }[] = []
  if (filtroTipo.value === 'todos' || filtroTipo.value === 'proyecto') {
    let proy = comentariosProyecto.value
    if (filtroProyecto.value) proy = proy.filter((c) => (c.proyecto as number) === filtroProyecto.value)
    proy.forEach((c) => lista.push({ tipo: 'proyecto', item: c }))
  }
  if (filtroTipo.value === 'todos' || filtroTipo.value === 'tarea') {
    let tar = comentariosTarea.value
    if (filtroTarea.value) tar = tar.filter((c) => (c.tarea as number) === filtroTarea.value)
    tar.forEach((c) => lista.push({ tipo: 'tarea', item: c }))
  }
  return lista.sort((a, b) => {
    const fa = (a.item.fecha as string) || ''
    const fb = (b.item.fecha as string) || ''
    return fb.localeCompare(fa)
  })
})

const adjuntosUnificados = computed(() => {
  const lista: { tipo: 'proyecto' | 'tarea'; item: Record<string, unknown> }[] = []
  if (filtroAdjTipo.value === 'todos' || filtroAdjTipo.value === 'proyecto') {
    let proy = adjuntosProyecto.value
    if (filtroAdjProyecto.value) proy = proy.filter((a) => (a.proyecto as number) === filtroAdjProyecto.value)
    proy.forEach((a) => lista.push({ tipo: 'proyecto', item: a }))
  }
  if (filtroAdjTipo.value === 'todos' || filtroAdjTipo.value === 'tarea') {
    let tar = adjuntosTarea.value
    if (filtroAdjTarea.value) tar = tar.filter((a) => (a.tarea as number) === filtroAdjTarea.value)
    tar.forEach((a) => lista.push({ tipo: 'tarea', item: a }))
  }
  return lista.sort((a, b) => {
    const fa = (a.item.fecha as string) || ''
    const fb = (b.item.fecha as string) || ''
    return fb.localeCompare(fa)
  })
})

async function cargarComentarios() {
  cargaComentarios.value = true
  try {
    const [cpRes, ctRes] = await Promise.all([
      api.get('comentarios-proyecto/'),
      api.get('comentarios-tarea/'),
    ])
    comentariosProyecto.value = parseList(cpRes)
    comentariosTarea.value = parseList(ctRes)
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al cargar comentarios.'))
    comentariosProyecto.value = []
    comentariosTarea.value = []
  } finally {
    cargaComentarios.value = false
  }
}

async function cargarAdjuntos() {
  cargaAdjuntos.value = true
  try {
    const [apRes, atRes] = await Promise.all([
      api.get('adjuntos-proyecto/'),
      api.get('adjuntos-tarea/'),
    ])
    adjuntosProyecto.value = parseList(apRes)
    adjuntosTarea.value = parseList(atRes)
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al cargar adjuntos.'))
    adjuntosProyecto.value = []
    adjuntosTarea.value = []
  } finally {
    cargaAdjuntos.value = false
  }
}

async function cargarProyectosYTareas() {
  try {
    const [pRes, tRes] = await Promise.all([
      api.get('proyectos/'),
      api.get('tareas/'),
    ])
    proyectos.value = parseList(pRes)
    tareas.value = parseList(tRes)
  } catch {
    proyectos.value = []
    tareas.value = []
  }
}

async function cargarUsuarios() {
  try {
    const res = await api.get('usuarios/selector/').catch(() => api.get('usuarios/'))
    usuarios.value = parseList(res)
  } catch {
    usuarios.value = []
  }
}

async function cargarLog() {
  cargaLog.value = true
  try {
    const params: Record<string, string | number> = {}
    if (filtroLogTipo.value) params.tipo = filtroLogTipo.value
    if (filtroLogProyecto.value) params.proyecto = filtroLogProyecto.value
    if (filtroLogTarea.value) params.tarea = filtroLogTarea.value
    if (filtroLogUsuario.value) params.usuario = filtroLogUsuario.value
    if (filtroLogFechaDesde.value) params.fecha_desde = filtroLogFechaDesde.value
    if (filtroLogFechaHasta.value) params.fecha_hasta = filtroLogFechaHasta.value
    const [comRes, adjRes] = await Promise.all([
      filtroLogEntidad.value !== 'adjunto' ? api.get('auditoria-comentarios/', { params }) : Promise.resolve({ data: [] }),
      filtroLogEntidad.value !== 'comentario' ? api.get('auditoria-adjuntos/', { params }) : Promise.resolve({ data: [] }),
    ])
    const comentarios = parseList(comRes)
    const adjuntos = parseList(adjRes)
    logAuditoria.value = comentarios.map((c) => ({ ...c, _entidad: 'comentario' }))
    logAdjuntos.value = adjuntos.map((a) => ({ ...a, _entidad: 'adjunto' }))
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al cargar el log de auditoría.'))
    logAuditoria.value = []
    logAdjuntos.value = []
  } finally {
    cargaLog.value = false
  }
}

const logUnificado = computed(() => {
  const items: Record<string, unknown>[] = []
  if (filtroLogEntidad.value !== 'adjunto') {
    items.push(...logAuditoria.value)
  }
  if (filtroLogEntidad.value !== 'comentario') {
    items.push(...logAdjuntos.value)
  }
  return items.sort((a, b) => {
    const fa = (a.fecha as string) || ''
    const fb = (b.fecha as string) || ''
    return fb.localeCompare(fa)
  })
})

function formatearFecha(f: unknown): string {
  if (!f) return '-'
  const s = typeof f === 'string' ? f : String(f)
  try {
    const d = new Date(s)
    if (isNaN(d.getTime())) return s
    return d.toLocaleString('es-CL', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
  } catch {
    return s
  }
}

function iniciarEdicion(tipo: 'proyecto' | 'tarea', item: Record<string, unknown>) {
  comentarioEditando.value = { tipo, id: item.id as number }
  textoEditando.value = (item.texto as string) || ''
}

function cancelarEdicion() {
  comentarioEditando.value = null
  textoEditando.value = ''
}

async function guardarEdicion() {
  const ed = comentarioEditando.value
  if (!ed || !textoEditando.value.trim()) return
  try {
    const endpoint = ed.tipo === 'proyecto' ? `comentarios-proyecto/${ed.id}/` : `comentarios-tarea/${ed.id}/`
    await api.patch(endpoint, { texto: textoEditando.value.trim() })
    toast.success('Comentario actualizado.')
    cancelarEdicion()
    await cargarComentarios()
    await cargarLog()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al actualizar.'))
  }
}

async function eliminarComentario(tipo: 'proyecto' | 'tarea', item: Record<string, unknown>) {
  if (!(await confirmDelete())) return
  try {
    const endpoint = tipo === 'proyecto' ? `comentarios-proyecto/${item.id}/` : `comentarios-tarea/${item.id}/`
    await api.delete(endpoint)
    toast.success('Comentario eliminado.')
    await cargarComentarios()
    await cargarLog()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al eliminar.'))
  }
}

function iniciarEdicionAdjunto(tipo: 'proyecto' | 'tarea', item: Record<string, unknown>) {
  adjuntoEditando.value = { tipo, id: item.id as number }
  nombreEditando.value = (item.nombre_original as string) || ''
}

function cancelarEdicionAdjunto() {
  adjuntoEditando.value = null
  nombreEditando.value = ''
}

async function guardarEdicionAdjunto() {
  const ed = adjuntoEditando.value
  if (!ed || !nombreEditando.value.trim()) return
  try {
    const endpoint = ed.tipo === 'proyecto' ? `adjuntos-proyecto/${ed.id}/` : `adjuntos-tarea/${ed.id}/`
    await api.patch(endpoint, { nombre_original: nombreEditando.value.trim() })
    toast.success('Adjunto actualizado.')
    cancelarEdicionAdjunto()
    await cargarAdjuntos()
    await cargarLog()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al actualizar.'))
  }
}

async function eliminarAdjunto(tipo: 'proyecto' | 'tarea', item: Record<string, unknown>) {
  if (!(await confirmDelete())) return
  try {
    const endpoint = tipo === 'proyecto' ? `adjuntos-proyecto/${item.id}/` : `adjuntos-tarea/${item.id}/`
    await api.delete(endpoint)
    toast.success('Adjunto eliminado.')
    await cargarAdjuntos()
    await cargarLog()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al eliminar.'))
  }
}

watch(tabActivo, (t) => {
  if (t === 'comentarios') cargarComentarios()
  else if (t === 'adjuntos') cargarAdjuntos()
  else cargarLog()
})

onMounted(async () => {
  await cargarProyectosYTareas()
  await cargarUsuarios()
  if (tabActivo.value === 'comentarios') await cargarComentarios()
  else if (tabActivo.value === 'adjuntos') await cargarAdjuntos()
  else await cargarLog()
})
</script>

<template>
  <div class="page">
    <h1>Auditoría de comentarios</h1>
    <p class="subtitle">Como administrador puede ver todos los comentarios, editarlos o eliminarlos, y consultar el historial de cambios.</p>

    <div class="tabs">
      <button
        type="button"
        class="tab"
        :class="{ active: tabActivo === 'comentarios' }"
        @click="tabActivo = 'comentarios'"
      >
        Comentarios
      </button>
      <button
        type="button"
        class="tab"
        :class="{ active: tabActivo === 'log' }"
        @click="tabActivo = 'log'"
      >
        Log de auditoría
      </button>
    </div>

    <!-- Tab Comentarios -->
    <div v-if="tabActivo === 'comentarios'" class="tab-content">
      <div class="filtros">
        <div class="filtro-grupo">
          <label>Tipo</label>
          <select v-model="filtroTipo">
            <option value="todos">Todos</option>
            <option value="proyecto">Proyectos</option>
            <option value="tarea">Tareas</option>
          </select>
        </div>
        <div v-if="filtroTipo !== 'tarea'" class="filtro-grupo">
          <label>Proyecto</label>
          <select v-model="filtroProyecto">
            <option :value="null">Todos</option>
            <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
          </select>
        </div>
        <div v-if="filtroTipo !== 'proyecto'" class="filtro-grupo">
          <label>Tarea</label>
          <select v-model="filtroTarea">
            <option :value="null">Todas</option>
            <option v-for="t in tareas" :key="(t.id as number)" :value="t.id">{{ (t.titulo as string) || 'Sin título' }}</option>
          </select>
        </div>
        <button type="button" class="btn-refresh" @click="cargarComentarios" :disabled="cargaComentarios">
          {{ cargaComentarios ? 'Cargando...' : 'Actualizar' }}
        </button>
      </div>

      <LoaderSpinner v-if="cargaComentarios" texto="Cargando comentarios..." />
      <div v-else-if="!comentariosUnificados.length" class="empty-msg">
        No hay comentarios que coincidan con los filtros.
      </div>
      <div v-else class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>Tipo</th>
              <th>Proyecto / Tarea</th>
              <th>Autor</th>
              <th>Fecha</th>
              <th>Texto</th>
              <th>Editado</th>
              <th class="acciones">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="{ tipo, item } in comentariosUnificados" :key="`${tipo}-${item.id}`">
              <td>
                <span class="badge" :class="tipo === 'proyecto' ? 'badge-proyecto' : 'badge-tarea'">
                  {{ tipo === 'proyecto' ? 'Proyecto' : 'Tarea' }}
                </span>
              </td>
              <td>
                {{ tipo === 'proyecto' ? (item.proyecto_nombre || '-') : (item.tarea_nombre || '-') }}
              </td>
              <td>{{ item.usuario_nombre || '-' }}</td>
              <td>{{ formatearFecha(item.fecha) }}</td>
              <td class="celda-texto">
                <template v-if="comentarioEditando?.tipo === tipo && comentarioEditando?.id === item.id">
                  <textarea v-model="textoEditando" rows="2" class="edit-textarea" />
                  <div class="edit-btns">
                    <button type="button" class="btn-small btn-ok" @click="guardarEdicion">Guardar</button>
                    <button type="button" class="btn-small btn-cancel" @click="cancelarEdicion">Cancelar</button>
                  </div>
                </template>
                <span v-else>{{ item.texto }}</span>
              </td>
              <td>
                <span v-if="item.editado_leyenda" class="editado">{{ item.editado_leyenda }}</span>
                <span v-else class="sin-editar">—</span>
              </td>
              <td class="acciones">
                <template v-if="!(comentarioEditando?.tipo === tipo && comentarioEditando?.id === item.id)">
                  <button type="button" class="btn-icon" title="Editar" @click="iniciarEdicion(tipo, item)">
                    <IconEdit class="btn-icon-sm" />
                  </button>
                  <button type="button" class="btn-icon btn-danger" title="Eliminar" @click="eliminarComentario(tipo, item)">
                    <IconTrash class="btn-icon-sm" />
                  </button>
                </template>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Tab Adjuntos -->
    <div v-if="tabActivo === 'adjuntos'" class="tab-content">
      <div class="filtros">
        <div class="filtro-grupo">
          <label>Tipo</label>
          <select v-model="filtroAdjTipo">
            <option value="todos">Todos</option>
            <option value="proyecto">Proyectos</option>
            <option value="tarea">Tareas</option>
          </select>
        </div>
        <div v-if="filtroAdjTipo !== 'tarea'" class="filtro-grupo">
          <label>Proyecto</label>
          <select v-model="filtroAdjProyecto">
            <option :value="null">Todos</option>
            <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
          </select>
        </div>
        <div v-if="filtroAdjTipo !== 'proyecto'" class="filtro-grupo">
          <label>Tarea</label>
          <select v-model="filtroAdjTarea">
            <option :value="null">Todas</option>
            <option v-for="t in tareas" :key="(t.id as number)" :value="t.id">{{ (t.titulo as string) || 'Sin título' }}</option>
          </select>
        </div>
        <button type="button" class="btn-refresh" @click="cargarAdjuntos" :disabled="cargaAdjuntos">
          {{ cargaAdjuntos ? 'Cargando...' : 'Actualizar' }}
        </button>
      </div>

      <LoaderSpinner v-if="cargaAdjuntos" texto="Cargando adjuntos..." />
      <div v-else-if="!adjuntosUnificados.length" class="empty-msg">
        No hay adjuntos que coincidan con los filtros.
      </div>
      <div v-else class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>Tipo</th>
              <th>Proyecto / Tarea</th>
              <th>Subido por</th>
              <th>Fecha</th>
              <th>Archivo</th>
              <th class="acciones">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="{ tipo, item } in adjuntosUnificados" :key="`adj-${tipo}-${item.id}`">
              <td>
                <span class="badge" :class="tipo === 'proyecto' ? 'badge-proyecto' : 'badge-tarea'">
                  {{ tipo === 'proyecto' ? 'Proyecto' : 'Tarea' }}
                </span>
              </td>
              <td>{{ tipo === 'proyecto' ? (item.proyecto_nombre || '-') : (item.tarea_nombre || '-') }}</td>
              <td>{{ item.subido_por_nombre || '-' }}</td>
              <td>{{ formatearFecha(item.fecha) }}</td>
              <td class="celda-texto">
                <template v-if="adjuntoEditando?.tipo === tipo && adjuntoEditando?.id === item.id">
                  <input v-model="nombreEditando" type="text" class="edit-input" />
                  <div class="edit-btns">
                    <button type="button" class="btn-small btn-ok" @click="guardarEdicionAdjunto">Guardar</button>
                    <button type="button" class="btn-small btn-cancel" @click="cancelarEdicionAdjunto">Cancelar</button>
                  </div>
                </template>
                <template v-else>
                  <a v-if="item.url" :href="item.url" target="_blank" rel="noopener" class="adjunto-link">📎 {{ item.nombre_original }}</a>
                  <span v-else>📎 {{ item.nombre_original }}</span>
                </template>
              </td>
              <td class="acciones">
                <template v-if="!(adjuntoEditando?.tipo === tipo && adjuntoEditando?.id === item.id)">
                  <button type="button" class="btn-icon" title="Editar nombre" @click="iniciarEdicionAdjunto(tipo, item)">
                    <IconEdit class="btn-icon-sm" />
                  </button>
                  <button type="button" class="btn-icon btn-danger" title="Eliminar" @click="eliminarAdjunto(tipo, item)">
                    <IconTrash class="btn-icon-sm" />
                  </button>
                </template>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Tab Log de auditoría -->
    <div v-if="tabActivo === 'log'" class="tab-content">
      <div class="filtros">
        <div class="filtro-grupo">
          <label>Entidad</label>
          <select v-model="filtroLogEntidad">
            <option value="todos">Comentarios y adjuntos</option>
            <option value="comentario">Solo comentarios</option>
            <option value="adjunto">Solo adjuntos</option>
          </select>
        </div>
        <div class="filtro-grupo">
          <label>Tipo</label>
          <select v-model="filtroLogTipo">
            <option value="">Todos</option>
            <option value="proyecto">Proyecto</option>
            <option value="tarea">Tarea</option>
          </select>
        </div>
        <div class="filtro-grupo">
          <label>Proyecto</label>
          <select v-model="filtroLogProyecto">
            <option :value="null">Todos</option>
            <option v-for="p in proyectos" :key="(p.id as number)" :value="p.id">{{ p.nombre }}</option>
          </select>
        </div>
        <div class="filtro-grupo">
          <label>Tarea</label>
          <select v-model="filtroLogTarea">
            <option :value="null">Todas</option>
            <option v-for="t in tareas" :key="(t.id as number)" :value="t.id">{{ (t.titulo as string) || 'Sin título' }}</option>
          </select>
        </div>
        <div class="filtro-grupo">
          <label>Usuario</label>
          <select v-model="filtroLogUsuario">
            <option :value="null">Todos</option>
            <option v-for="u in usuarios" :key="(u.id as number)" :value="u.id">{{ u.nombre_completo || u.nombre }}</option>
          </select>
        </div>
        <div class="filtro-grupo">
          <label>Desde</label>
          <input v-model="filtroLogFechaDesde" type="date" />
        </div>
        <div class="filtro-grupo">
          <label>Hasta</label>
          <input v-model="filtroLogFechaHasta" type="date" />
        </div>
        <button type="button" class="btn-refresh" @click="cargarLog" :disabled="cargaLog">
          {{ cargaLog ? 'Cargando...' : 'Buscar' }}
        </button>
      </div>

      <LoaderSpinner v-if="cargaLog" texto="Cargando log..." />
      <div v-else-if="!logUnificado.length" class="empty-msg">
        No hay registros en el log de auditoría.
      </div>
      <div v-else class="table-wrapper">
        <table class="table table-log">
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Entidad</th>
              <th>Tipo</th>
              <th>Acción</th>
              <th>Usuario</th>
              <th>ID</th>
              <th>Detalle anterior</th>
              <th>Detalle nuevo</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(l, idx) in logUnificado" :key="(l.id as number) + '-' + (l._entidad as string) + '-' + idx">
              <td>{{ formatearFecha(l.fecha) }}</td>
              <td>
                <span class="badge" :class="l._entidad === 'comentario' ? 'badge-comentario' : 'badge-adjunto'">
                  {{ l._entidad === 'comentario' ? 'Comentario' : 'Adjunto' }}
                </span>
              </td>
              <td>
                <span class="badge" :class="l.tipo === 'proyecto' ? 'badge-proyecto' : 'badge-tarea'">
                  {{ l.tipo }}
                </span>
              </td>
              <td>
                <span class="badge" :class="l.accion === 'editar' ? 'badge-editar' : 'badge-eliminar'">
                  {{ l.accion }}
                </span>
              </td>
              <td>{{ l.usuario_nombre || '-' }}</td>
              <td>{{ l.comentario_id ?? l.adjunto_id }}</td>
              <td class="celda-texto">{{ l.texto_anterior ?? l.nombre_anterior ?? '—' }}</td>
              <td class="celda-texto">{{ l.texto_nuevo ?? l.nombre_nuevo ?? (l.nombre_archivo && l.accion === 'eliminar' ? l.nombre_archivo : '—') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 0.5rem; }
.subtitle { color: #64748b; margin-bottom: 1.5rem; font-size: 0.95rem; }

.tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}
.tab {
  padding: 0.5rem 1.25rem;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: 500;
  cursor: pointer;
  color: #64748b;
  transition: all 0.2s;
}
.tab:hover { border-color: #cbd5e1; color: #334155; }
.tab.active {
  background: linear-gradient(135deg, #0d47a1 0%, #1565c0 100%);
  border-color: #1565c0;
  color: white;
}

.tab-content { background: white; border-radius: 10px; padding: 1.25rem; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }

.filtros {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-end;
  margin-bottom: 1.25rem;
}
.filtro-grupo {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.filtro-grupo label { font-size: 0.8rem; font-weight: 600; color: #64748b; }
.filtro-grupo select, .filtro-grupo input {
  padding: 0.4rem 0.6rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.9rem;
  min-width: 140px;
}
.btn-refresh {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  align-self: flex-end;
}
.btn-refresh:disabled { opacity: 0.7; cursor: not-allowed; }

.table-wrapper { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; }
.table th, .table td { padding: 0.6rem 0.75rem; text-align: left; border-bottom: 1px solid #e2e8f0; }
.table th { background: #f8fafc; font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; }
.table td { font-size: 0.9rem; }
.table .acciones { white-space: nowrap; }
.celda-texto { max-width: 280px; word-break: break-word; }
.editado { font-size: 0.75rem; color: #64748b; font-style: italic; }
.sin-editar { color: #94a3b8; }

.badge {
  display: inline-block;
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 600;
}
.badge-proyecto { background: #dbeafe; color: #1d4ed8; }
.badge-tarea { background: #dcfce7; color: #15803d; }
.badge-comentario { background: #e0e7ff; color: #4338ca; }
.badge-adjunto { background: #fce7f3; color: #be185d; }
.badge-editar { background: #fef3c7; color: #a16207; }
.badge-eliminar { background: #fee2e2; color: #b91c1c; }

.edit-input {
  width: 100%;
  padding: 0.4rem;
  font-size: 0.85rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  margin-bottom: 0.5rem;
}
.adjunto-link { color: #2563eb; text-decoration: none; }
.adjunto-link:hover { text-decoration: underline; }
.edit-textarea {
  width: 100%;
  padding: 0.4rem;
  font-size: 0.85rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  margin-bottom: 0.5rem;
}
.edit-btns { display: flex; gap: 0.5rem; }
.btn-small { padding: 0.3rem 0.6rem; font-size: 0.85rem; border-radius: 6px; cursor: pointer; border: none; }
.btn-ok { background: #16a34a; color: white; }
.btn-cancel { background: #94a3b8; color: white; }
.btn-icon {
  padding: 0.25rem 0.4rem;
  background: #e2e8f0;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-right: 0.25rem;
}
.btn-icon:hover { background: #cbd5e1; }
.btn-icon.btn-danger:hover { background: #fecaca !important; }
.btn-icon-sm { width: 14px; height: 14px; }

.empty-msg {
  padding: 2rem;
  text-align: center;
  color: #64748b;
  font-size: 0.95rem;
}

.table-log .celda-texto { max-width: 200px; }
</style>
