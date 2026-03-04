<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import LoaderSpinner from '@/components/LoaderSpinner.vue'

const { user } = useAuth()
const toast = useToast()
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

// Filtrar por búsqueda de proyecto o "Tarea Particular"
const proyectosVisibles = computed(() => {
  const q = buscarProyecto.value.trim().toLowerCase()
  if (!q) return proyectosVisiblesBase.value
  return proyectosVisiblesBase.value.filter((g) =>
    (g.proyecto_nombre || '').toLowerCase().includes(q) ||
    (g.esParticular && 'tarea particular'.includes(q))
  )
})
const tareaEdit = ref<Record<string, unknown> | null>(null)
const historialTarea = ref<Record<string, unknown>[]>([])
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
  try {
    const res = await api.get('historial/', { params: { tarea: tarea.id } })
    const raw = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    historialTarea.value = (raw as Record<string, unknown>[]).sort((a, b) => {
      const fa = (a.fecha as string) || ''
      const fb = (b.fecha as string) || ''
      return fb.localeCompare(fa)
    })
  } catch {
    historialTarea.value = []
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

    <div class="header-actions">
      <input
        v-model="buscarProyecto"
        type="search"
        placeholder="Buscar por proyecto o Tarea Particular..."
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
          <div v-for="t in grupo.tareas" :key="(t.id as number)" class="tarea-card">
            <div class="tarea-info">
              <span class="tipo-badge tipo-tarea">Tarea</span>
              <strong>{{ t.titulo }}</strong>
              <span class="tarea-meta">{{ t.area_nombre || '-' }} · {{ t.estado }} · {{ t.porcentaje_avance }}%</span>
            </div>
            <button class="btn-action" @click="openModal(t)">Actualizar avance</button>
          </div>
        </div>
      </div>
    </div>
    <p v-else-if="buscarProyecto.trim() && proyectosVisiblesBase.length" class="empty-msg">
      No hay proyectos que coincidan con la búsqueda.
    </p>
    <p v-else class="empty-msg">
      No tiene tareas asignadas. Verifique que: 1) tenga un área asignada en su perfil, o que sea responsable de tareas del proyecto; 2) las tareas del proyecto estén en su área o lo tengan como responsable.
    </p>

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
.tareas-list { display: flex; flex-direction: column; gap: 0.75rem; }
.tarea-card {
  background: white;
  padding: 1rem 1.25rem;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
}
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
</style>
