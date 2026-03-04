<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { api } from '@/services/api'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useModalClose } from '@/composables/useModalClose'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import EmptyState from '@/components/EmptyState.vue'
import IconTrash from '@/components/icons/IconTrash.vue'

const { user, isAdmin } = useAuth()
const toast = useToast()
const { confirmDelete } = useConfirmDelete()
const backups = ref<Record<string, unknown>[]>([])
const codeBackups = ref<Record<string, unknown>[]>([])
const cargaBackups = ref(false)
const cargaCodeBackups = ref(false)
const ejecutandoBackup = ref(false)
const ejecutandoCodeBackup = ref(false)
const ejecutandoRestore = ref(false)
const ejecutandoDelete = ref(false)
const showModalRestore = ref(false)
const backupSeleccionado = ref<Record<string, unknown> | null>(null)
const filtroFechaDesde = ref('')
const filtroFechaHasta = ref('')
const buscarTexto = ref('')

const puedeEjecutar = computed(() => isAdmin.value && user.value)

function cumpleFiltros(b: Record<string, unknown>): boolean {
  const created = typeof b.created === 'string' ? b.created : String(b.created || '')
  const filename = String(b.filename || '').toLowerCase()
  const texto = buscarTexto.value.trim().toLowerCase()
  if (texto && !filename.includes(texto)) return false
  if (filtroFechaDesde.value) {
    const desde = new Date(filtroFechaDesde.value)
    const d = new Date(created)
    if (d < desde) return false
  }
  if (filtroFechaHasta.value) {
    const hasta = new Date(filtroFechaHasta.value)
    hasta.setHours(23, 59, 59, 999)
    const d = new Date(created)
    if (d > hasta) return false
  }
  return true
}

const backupsFiltrados = computed(() =>
  backups.value.filter((b) => cumpleFiltros(b))
)
const codeBackupsFiltrados = computed(() =>
  codeBackups.value.filter((b) => cumpleFiltros(b))
)
const hayFiltrosActivos = computed(() =>
  !!buscarTexto.value.trim() || !!filtroFechaDesde.value || !!filtroFechaHasta.value
)

onMounted(async () => {
  if (puedeEjecutar.value) {
    await Promise.all([cargarBackups(), cargarCodeBackups()])
  }
})

async function cargarBackups() {
  if (!user.value) return
  cargaBackups.value = true
  try {
    const res = await api.get('backup-restore/backups/')
    backups.value = Array.isArray(res.data?.backups) ? res.data.backups : []
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    toast.error(err.response?.data?.error || 'Error al cargar backups')
    backups.value = []
  } finally {
    cargaBackups.value = false
  }
}

async function cargarCodeBackups() {
  if (!user.value) return
  cargaCodeBackups.value = true
  try {
    const res = await api.get('backup-restore/code-backups/')
    codeBackups.value = Array.isArray(res.data?.backups) ? res.data.backups : []
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    toast.error(err.response?.data?.error || 'Error al cargar backups de código')
    codeBackups.value = []
  } finally {
    cargaCodeBackups.value = false
  }
}

async function ejecutarBackup() {
  if (!user.value || !isAdmin.value) return
  ejecutandoBackup.value = true
  try {
    const res = await api.post('backup-restore/backup/', {})
    if (res.data?.success) {
      toast.success(res.data.message || 'Backup de base de datos creado correctamente.')
      await cargarBackups()
    } else {
      toast.error(res.data?.error || 'Error al crear backup')
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string }; status?: number } }
    toast.error(err.response?.data?.error || 'Error al crear backup')
  } finally {
    ejecutandoBackup.value = false
  }
}

async function ejecutarCodeBackup() {
  if (!user.value || !isAdmin.value) return
  ejecutandoCodeBackup.value = true
  try {
    const res = await api.post('backup-restore/code-backup/', {})
    if (res.data?.success) {
      toast.success(res.data.message || 'Backup de código creado correctamente.')
      await cargarCodeBackups()
    } else {
      toast.error(res.data?.error || 'Error al crear backup de código')
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string }; status?: number } }
    toast.error(err.response?.data?.error || 'Error al crear backup de código')
  } finally {
    ejecutandoCodeBackup.value = false
  }
}

function abrirModalRestore(b: Record<string, unknown>) {
  backupSeleccionado.value = b
  showModalRestore.value = true
}

function cerrarModalRestore() {
  showModalRestore.value = false
  backupSeleccionado.value = null
}
useModalClose(showModalRestore, cerrarModalRestore)

async function eliminarBackup(b: Record<string, unknown>) {
  const filename = b.filename as string
  if (!filename || !user.value || !isAdmin.value) return
  if (!(await confirmDelete())) return
  ejecutandoDelete.value = true
  try {
    const res = await api.post('backup-restore/backups/delete/', { filename })
    if (res.data?.success) {
      toast.success(res.data.message || 'Backup eliminado correctamente.')
      await cargarBackups()
    } else {
      toast.error(res.data?.error || 'Error al eliminar backup')
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    toast.error(err.response?.data?.error || 'Error al eliminar backup')
  } finally {
    ejecutandoDelete.value = false
  }
}

async function eliminarCodeBackup(b: Record<string, unknown>) {
  const filename = b.filename as string
  if (!filename || !user.value || !isAdmin.value) return
  if (!(await confirmDelete())) return
  ejecutandoDelete.value = true
  try {
    const res = await api.post('backup-restore/code-backups/delete/', { filename })
    if (res.data?.success) {
      toast.success(res.data.message || 'Backup de código eliminado correctamente.')
      await cargarCodeBackups()
    } else {
      toast.error(res.data?.error || 'Error al eliminar backup de código')
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    toast.error(err.response?.data?.error || 'Error al eliminar backup de código')
  } finally {
    ejecutandoDelete.value = false
  }
}

async function confirmarRestore() {
  if (!user.value || !isAdmin.value || !backupSeleccionado.value) return
  const filename = backupSeleccionado.value.filename as string
  if (!filename) {
    toast.error('Archivo de backup no válido')
    return
  }
  ejecutandoRestore.value = true
  try {
    const res = await api.post('backup-restore/restore/', { backup_file: filename })
    if (res.data?.success) {
      toast.success(res.data.message || 'Restore ejecutado correctamente.')
      cerrarModalRestore()
      await cargarBackups()
      setTimeout(() => window.location.reload(), 1500)
    } else {
      toast.error(res.data?.error || 'Error al restaurar')
    }
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    toast.error(err.response?.data?.error || 'Error al restaurar')
  } finally {
    ejecutandoRestore.value = false
  }
}

function formatearFecha(f: unknown): string {
  if (!f) return '-'
  const s = typeof f === 'string' ? f : String(f)
  try {
    const d = new Date(s)
    if (isNaN(d.getTime())) return s
    return d.toLocaleString('es-CL', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  } catch {
    return s
  }
}

function formatearTamano(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
</script>

<template>
  <div class="backup-restore">
    <h1>Backup &amp; Restore</h1>
    <p class="desc">
      Cree copias de seguridad de la base de datos, del código del sistema, o restaure desde un backup anterior.
      Solo disponible para el rol Administrador.
    </p>

    <template v-if="!puedeEjecutar">
      <div class="alert alert-warning">
        No tiene permisos para acceder a esta funcionalidad. Solo el rol Administrador puede ejecutar backup y restore.
      </div>
    </template>

    <template v-else>
      <div class="filtros-backup">
        <label class="filtro-item">
          <span class="filtro-label">Buscar</span>
          <input
            v-model="buscarTexto"
            type="search"
            placeholder="Por nombre..."
            class="search-input"
          />
        </label>
        <label class="filtro-item">
          <span class="filtro-label">Desde</span>
          <input v-model="filtroFechaDesde" type="date" class="search-date" />
        </label>
        <label class="filtro-item">
          <span class="filtro-label">Hasta</span>
          <input v-model="filtroFechaHasta" type="date" class="search-date" />
        </label>
      </div>
      <section class="section-backup">
        <h2>Backup de base de datos</h2>
        <p class="section-desc">
          Genera una copia de seguridad de la base de datos actual.
        </p>
        <button
          type="button"
          class="btn-backup"
          :disabled="ejecutandoBackup"
          @click="ejecutarBackup"
        >
          <span v-if="ejecutandoBackup">Creando backup...</span>
          <span v-else>Crear backup BD</span>
        </button>
      </section>

      <section class="section-code-backup">
        <h2>Backup de código</h2>
        <p class="section-desc">
          Genera una copia de seguridad del código del sistema en formato ZIP.
          Se almacena en la carpeta interna de backups y excluye node_modules, venv, etc.
        </p>
        <button
          type="button"
          class="btn-code-backup"
          :disabled="ejecutandoCodeBackup"
          @click="ejecutarCodeBackup"
        >
          <span v-if="ejecutandoCodeBackup">Creando backup...</span>
          <span v-else>Crear backup de código</span>
        </button>
        <LoaderSpinner v-if="cargaCodeBackups" texto="Cargando backups de código..." />
        <div v-else-if="codeBackupsFiltrados.length" class="backups-list code-backups-list">
          <div
            v-for="b in codeBackupsFiltrados"
            :key="String(b.filename)"
            class="backup-item"
          >
            <div class="backup-info">
              <strong>{{ b.filename }}</strong>
              <span class="backup-meta">
                {{ formatearTamano(Number(b.size) || 0) }} · {{ formatearFecha(b.created) }}
              </span>
            </div>
            <div class="backup-actions">
              <button
                type="button"
                class="btn-delete"
                :disabled="ejecutandoDelete"
                :title="'Eliminar backup'"
                @click="eliminarCodeBackup(b)"
              >
                <IconTrash class="btn-icon" />
                Eliminar
              </button>
            </div>
          </div>
        </div>
        <p v-else-if="!cargaCodeBackups" class="empty-msg">No hay backups de código aún.</p>
      </section>

      <section class="section-restore">
        <h2>Restaurar desde backup</h2>
        <p class="section-desc">
          Seleccione un backup de la lista y presione Restaurar. Se creará un backup automático antes de restaurar.
        </p>

        <LoaderSpinner v-if="cargaBackups" texto="Cargando backups..." />
        <div v-else-if="backupsFiltrados.length" class="backups-list">
          <div
            v-for="b in backupsFiltrados"
            :key="String(b.filename)"
            class="backup-item"
          >
            <div class="backup-info">
              <strong>{{ b.filename }}</strong>
              <span class="backup-meta">
                {{ formatearTamano(Number(b.size) || 0) }} · {{ formatearFecha(b.created) }}
              </span>
            </div>
            <div class="backup-actions">
              <button
                type="button"
                class="btn-restore"
                :disabled="ejecutandoRestore"
                @click="abrirModalRestore(b)"
              >
                Restaurar
              </button>
              <button
                type="button"
                class="btn-delete"
                :disabled="ejecutandoDelete"
                :title="'Eliminar backup'"
                @click="eliminarBackup(b)"
              >
                <IconTrash class="btn-icon" />
                Eliminar
              </button>
            </div>
          </div>
        </div>
        <p v-else class="empty-msg">
          {{ hayFiltrosActivos && backups.length ? 'No hay backups que coincidan con los filtros.' : 'No hay backups disponibles.' }}
        </p>
      </section>

      <!-- Modal de confirmación -->
      <div v-if="showModalRestore && backupSeleccionado" class="modal-overlay" @click.self="cerrarModalRestore">
        <div class="modal-restore">
          <h3>Confirmar restauración</h3>
          <p class="modal-message">
            Esta acción restaurará la base de datos y puede sobrescribir información actual.
            ¿Desea continuar?
          </p>
          <p v-if="backupSeleccionado.filename" class="modal-file">
            Archivo: <strong>{{ backupSeleccionado.filename }}</strong>
          </p>
          <div class="modal-actions">
            <button type="button" class="btn-cancel" @click="cerrarModalRestore">
              Cancelar
            </button>
            <button
              type="button"
              class="btn-confirm"
              :disabled="ejecutandoRestore"
              @click="confirmarRestore"
            >
              {{ ejecutandoRestore ? 'Restaurando...' : 'Confirmar' }}
            </button>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.backup-restore h1 { margin-bottom: 0.5rem; color: #1e293b; }
.desc { color: #64748b; margin-bottom: 1.5rem; font-size: 0.95rem; }
.alert { padding: 1rem 1.25rem; border-radius: 8px; margin-bottom: 1rem; }
.alert-warning { background: #fef3c7; color: #92400e; border: 1px solid #fcd34d; }
.filtros-backup {
  display: flex;
  gap: 1rem;
  align-items: flex-end;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}
.filtro-item {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  min-width: 0;
}
.filtro-item:first-child { flex: 1; min-width: 180px; }
.filtro-label {
  font-size: 0.75rem;
  font-weight: 500;
  color: #64748b;
}
.filtros-backup .search-input,
.filtros-backup .search-date {
  height: 38px;
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.9rem;
  box-sizing: border-box;
}
.filtros-backup .search-input {
  width: 100%;
  min-width: 0;
}
.section-backup, .section-code-backup, .section-restore { margin-bottom: 2rem; }
.btn-code-backup {
  padding: 0.6rem 1.25rem;
  background: #15803d;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  font-size: 0.95rem;
}
.btn-code-backup:hover:not(:disabled) { background: #166534; }
.btn-code-backup:disabled { opacity: 0.7; cursor: not-allowed; }
.code-backups-list { margin-top: 1rem; max-height: 200px; overflow-y: auto; }
.section-backup h2, .section-restore h2 { font-size: 1.1rem; margin: 0 0 0.5rem; color: #334155; }
.section-desc { font-size: 0.9rem; color: #64748b; margin: 0 0 1rem; }
.btn-backup {
  padding: 0.6rem 1.25rem;
  background: #0d47a1;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  font-size: 0.95rem;
}
.btn-backup:hover:not(:disabled) { background: #1565c0; }
.btn-backup:disabled { opacity: 0.7; cursor: not-allowed; }
.backups-list { display: flex; flex-direction: column; gap: 0.75rem; }
.backup-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.25rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.backup-info { display: flex; flex-direction: column; gap: 0.25rem; }
.backup-meta { font-size: 0.85rem; color: #64748b; }
.backup-actions { display: flex; gap: 0.5rem; align-items: center; }
.btn-delete {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.5rem 1rem;
  background: #64748b;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  font-size: 0.85rem;
}
.btn-delete:hover:not(:disabled) { background: #475569; }
.btn-delete:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-delete .btn-icon { width: 14px; height: 14px; }
.btn-restore {
  padding: 0.6rem 1.25rem;
  background: #dc2626;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-restore:hover:not(:disabled) { background: #b91c1c; }
.btn-restore:disabled { opacity: 0.7; cursor: not-allowed; }
.empty-msg { color: #64748b; font-style: italic; }
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-restore {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  max-width: 440px;
  width: 90%;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
}
.modal-restore h3 { margin: 0 0 1rem; color: #dc2626; font-size: 1.1rem; }
.modal-message { margin-bottom: 0.75rem; color: #475569; line-height: 1.5; }
.modal-file { font-size: 0.9rem; color: #64748b; margin-bottom: 1.25rem; }
.modal-file strong { color: #1e293b; }
.modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; }
.btn-cancel {
  padding: 0.5rem 1.25rem;
  background: white;
  color: #475569;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
}
.btn-cancel:hover { background: #f8fafc; }
.btn-confirm {
  padding: 0.5rem 1.25rem;
  background: #dc2626;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
}
.btn-confirm:hover:not(:disabled) { background: #b91c1c; }
.btn-confirm:disabled { opacity: 0.7; cursor: not-allowed; }
</style>
