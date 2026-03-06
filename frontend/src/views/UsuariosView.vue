<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api'
import { exportToCsv } from '@/utils/exportCsv'
import IconDownload from '@/components/icons/IconDownload.vue'
import IconPlus from '@/components/icons/IconPlus.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconEye from '@/components/icons/IconEye.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import { validarPassword } from '@/utils/validarPassword'
import { extraerMensajeError } from '@/utils/apiError'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { useModalClose } from '@/composables/useModalClose'
import EmptyState from '@/components/EmptyState.vue'

const { confirmDelete } = useConfirmDelete()
const toast = useToast()
const usuarios = ref<Record<string, unknown>[]>([])
const buscarUsuario = ref('')
const roles = ref<Record<string, unknown>[]>([])
const areas = ref<Record<string, unknown>[]>([])
const secretarias = ref<Record<string, unknown>[]>([])
const showForm = ref(false)
const showVerModal = ref(false)
const usuarioVer = ref<Record<string, unknown> | null>(null)
const tipoOrganizacionUsuario = ref<'area' | 'secretaria'>('area')
const editingId = ref<number | null>(null)
const form = ref({
  nombre: '',
  apellido: '',
  email: '',
  password: '',
  passwordConfirm: '',
  rol: null as number | null,
  area: null as number | null,
  secretaria: null as number | null,
  estado: true,
})

function parseAreas(res: unknown): Record<string, unknown>[] {
  if (!res || typeof res !== 'object') return []
  const d = 'data' in (res as object) ? (res as { data: unknown }).data : res
  if (Array.isArray(d)) return d as Record<string, unknown>[]
  if (d && typeof d === 'object' && 'results' in (d as object)) return ((d as { results: unknown[] }).results || []) as Record<string, unknown>[]
  return []
}

function parseListResponse(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

const load = async () => {
  const [u, r, a, s] = await Promise.allSettled([
    api.get('usuarios/'),
    api.get('roles/'),
    api.get('areas/', { params: { estado: 'true' } }),
    api.get('secretarias/', { params: { activa: 'true' } }),
  ])

  usuarios.value = u.status === 'fulfilled' ? parseListResponse(u.value.data) : []
  roles.value = r.status === 'fulfilled' ? parseListResponse(r.value.data) : []
  areas.value = a.status === 'fulfilled' ? parseAreas(a.value) : []
  secretarias.value = s.status === 'fulfilled' ? parseListResponse(s.value.data) : []

  if ([u, r, a, s].some((res) => res.status === 'rejected')) {
    toast.error('No se pudieron cargar todos los catálogos de usuarios. Revise la conexión con el backend.')
  }
}

const usuariosFiltrados = computed(() => {
  const q = buscarUsuario.value.trim().toLowerCase()
  if (!q) return usuarios.value
  return usuarios.value.filter((u: Record<string, unknown>) => {
    const nombreCompleto = String(u.nombre_completo || `${u.nombre || ''} ${u.apellido || ''}`.trim() || '').toLowerCase()
    return nombreCompleto.includes(q)
  })
})

async function descargarExcel() {
  const lista = usuariosFiltrados.value
  const headers = ['Nombre completo', 'Email', 'Rol', 'Área/Secretaría', 'Estado']
  const rows = lista.map((u: Record<string, unknown>) => [
    String(u.nombre_completo || `${u.nombre || ''} ${u.apellido || ''}`.trim() || ''),
    String(u.email || ''),
    String(u.rol_nombre || ''),
    String(u.area_nombre || u.secretaria_nombre || ''),
    (u.estado !== false ? 'Activo' : 'Inactivo'),
  ])
  await exportToCsv(headers, rows, `usuarios_${new Date().toISOString().slice(0, 10)}.csv`)
}

const openVer = (u: Record<string, unknown>) => {
  usuarioVer.value = u
  showVerModal.value = true
}

const closeVerModal = () => {
  showVerModal.value = false
  usuarioVer.value = null
}
const closeForm = () => { showForm.value = false }
useModalClose(showVerModal, closeVerModal)
useModalClose(showForm, closeForm)

const openCreate = () => {
  editingId.value = null
  tipoOrganizacionUsuario.value = 'area'
  form.value = {
    nombre: '',
    apellido: '',
    email: '',
    password: '',
    passwordConfirm: '',
    rol: null,
    area: null,
    secretaria: null,
    estado: true,
  }
  showForm.value = true
}

const openEdit = async (u: Record<string, unknown>) => {
  editingId.value = u.id as number
  const rolNombre = (roles.value.find((r: Record<string, unknown>) => r.id === u.rol) as Record<string, unknown>)?.nombre as string
  let areaVal = (u.area ? (typeof u.area === 'object' ? (u.area as { id?: number }).id : u.area) : null) as number | null
  let secretariaVal = (u.secretaria ? (typeof u.secretaria === 'object' ? (u.secretaria as { id?: number }).id : u.secretaria) : null) as number | null
  tipoOrganizacionUsuario.value = secretariaVal ? 'secretaria' : 'area'
  form.value = {
    nombre: (u.nombre as string) || '',
    apellido: (u.apellido as string) || '',
    email: (u.email as string) || '',
    password: '',
    passwordConfirm: '',
    rol: u.rol as number,
    area: areaVal,
    secretaria: secretariaVal,
    estado: u.estado !== false,
  }
  showForm.value = true
}

const requierePassword = computed(() => !editingId.value || form.value.password.length > 0)

const passwordValida = computed(() => {
  if (!form.value.password) return { valida: !requierePassword.value, errores: [] as string[] }
  return validarPassword(form.value.password)
})

const passwordsCoinciden = computed(() => {
  if (!form.value.password) return true
  return form.value.password === form.value.passwordConfirm
})

const puedeGuardar = computed(() => {
  if (requierePassword.value) {
    if (!form.value.password) return false
    if (!form.value.passwordConfirm) return false
    if (!passwordValida.value.valida) return false
    if (!passwordsCoinciden.value) return false
  }
  return true
})

const save = async () => {
  if (!puedeGuardar.value) {
    if (requierePassword.value && !passwordValida.value.valida) {
      toast.error(passwordValida.value.errores.join('. '))
    } else if (requierePassword.value && !passwordsCoinciden.value) {
      toast.error('Las contraseñas no coinciden.')
    }
    return
  }
  const payload = { ...form.value } as Record<string, unknown>
  delete payload.passwordConfirm
  if (!payload.password) delete payload.password
  const rolNombre = (roles.value.find((r: Record<string, unknown>) => r.id === payload.rol) as Record<string, unknown> | undefined)?.nombre as string
  if (rolNombre === 'Administrador') {
    payload.area = null
    payload.secretaria = null
  } else if (rolNombre === 'Carga') {
    if (tipoOrganizacionUsuario.value === 'area') {
      payload.secretaria = null
    } else {
      payload.area = null
    }
  } else if (rolNombre === 'Visualización') {
    payload.secretaria = null
  }

  try {
    if (editingId.value) {
      await api.patch(`usuarios/${editingId.value}/`, payload)
      toast.success('Usuario actualizado correctamente.')
    } else {
      await api.post('usuarios/', payload)
      toast.success('Usuario creado correctamente.')
    }
    showForm.value = false
    load()
  } catch (e) {
    toast.error(extraerMensajeError(e, 'Error al guardar el usuario.'))
  }
}

const remove = async (id: number) => {
  if (await confirmDelete()) {
    try {
      await api.delete(`usuarios/${id}/`)
      toast.success('Registro eliminado correctamente.')
      load()
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al eliminar el usuario.'))
    }
  }
}

const rolNombreActual = computed(() => (roles.value.find((r: Record<string, unknown>) => r.id === form.value.rol) as Record<string, unknown>)?.nombre as string || '')

const areasParaSeleccionar = computed(() => areas.value)

function onRolChange() {
  if (!form.value.rol) return
  const nombre = rolNombreActual.value
  if (nombre === 'Administrador') {
    form.value.area = null
    form.value.secretaria = null
  } else if (nombre === 'Carga') {
    tipoOrganizacionUsuario.value = 'area'
    form.value.area = null
    form.value.secretaria = null
  } else if (nombre === 'Visualización') {
    form.value.secretaria = null
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <h1>Usuarios</h1>
    <div class="toolbar">
      <input
        v-model="buscarUsuario"
        type="search"
        placeholder="Buscar por nombre completo..."
        class="search-input"
      />
      <div class="toolbar-buttons">
        <button type="button" class="btn-secondary" @click="descargarExcel" :disabled="!usuariosFiltrados.length">
          <IconDownload class="btn-icon" />
          Descargar Excel
        </button>
        <button class="btn-primary" @click="openCreate">
          <IconPlus class="btn-icon" />
          Nuevo usuario
        </button>
      </div>
    </div>

    <EmptyState
      v-if="!usuariosFiltrados.length"
      :titulo="buscarUsuario.trim() ? 'Sin resultados' : 'No hay usuarios'"
      :mensaje="buscarUsuario.trim() ? 'No se encontraron usuarios que coincidan con la búsqueda.' : 'Aún no hay usuarios cargados. Use el botón «Nuevo usuario» para crear el primero.'"
      icono="lista"
    />
    <div v-else class="table-wrapper">
      <table class="table">
      <thead>
        <tr>
          <th>Nombre completo</th>
          <th>Email</th>
          <th>Rol</th>
          <th>Área / Secretaría</th>
          <th>Estado</th>
          <th class="actions-header">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="u in usuariosFiltrados" :key="(u.id as number)">
          <td>{{ u.nombre_completo || u.nombre }}</td>
          <td>{{ u.email }}</td>
          <td>{{ u.rol_nombre || '-' }}</td>
          <td>{{ u.area_nombre || u.secretaria_nombre || '-' }}</td>
          <td>{{ u.estado ? 'Activo' : 'Inactivo' }}</td>
          <td class="actions-cell">
            <button class="btn-action" title="Ver" @click="openVer(u)"><IconEye class="btn-icon-sm" /> Ver</button>
            <button class="btn-action" title="Editar" @click="openEdit(u)"><IconEdit class="btn-icon-sm" /> Editar</button>
            <button class="btn-action-danger" title="Eliminar" @click="remove(u.id as number)"><IconTrash class="btn-icon-sm" /> Eliminar</button>
          </td>
        </tr>
      </tbody>
    </table>
    </div>

    <!-- Modal Ver detalle usuario -->
    <div v-if="showVerModal && usuarioVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-ver">
        <h2>Detalle del usuario</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Nombre completo</span>
            <span class="detalle-valor">{{ usuarioVer.nombre_completo || `${usuarioVer.nombre || ''} ${usuarioVer.apellido || ''}`.trim() || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Email</span>
            <span class="detalle-valor">{{ usuarioVer.email || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Rol</span>
            <span class="detalle-valor">{{ usuarioVer.rol_nombre || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Área / Secretaría</span>
            <span class="detalle-valor">{{ usuarioVer.area_nombre || usuarioVer.secretaria_nombre || '-' }}</span>
          </div>
          <div class="detalle-row">
            <span class="detalle-label">Estado</span>
            <span class="detalle-valor">{{ usuarioVer.estado !== false ? 'Activo' : 'Inactivo' }}</span>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal">Cerrar</button>
        </div>
      </div>
    </div>

    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal">
        <h2>{{ editingId ? 'Editar' : 'Nuevo' }} usuario</h2>
        <form @submit.prevent="save">
          <label>Nombre</label>
          <input v-model="form.nombre" placeholder="Nombre" required />
          <label>Apellido</label>
          <input v-model="form.apellido" placeholder="Apellido" />
          <label>Email</label>
          <input v-model="form.email" type="email" placeholder="Email" required />
          <label>Contraseña</label>
          <input
            v-model="form.password"
            type="password"
            placeholder="Contraseña"
            :required="!editingId"
            :class="{ 'input-error': requierePassword && form.password && !passwordValida.valida }"
          />
          <p v-if="form.password && !passwordValida.valida" class="msg-error">
            {{ passwordValida.errores.join('. ') }}
          </p>
          <p v-else-if="form.password && passwordValida.valida" class="msg-ok">Contraseña válida</p>
          <label>Repetir contraseña</label>
          <input
            v-model="form.passwordConfirm"
            type="password"
            placeholder="Repetir contraseña"
            :required="requierePassword && !!form.password"
            :class="{ 'input-error': form.passwordConfirm && !passwordsCoinciden }"
          />
          <p v-if="form.passwordConfirm && !passwordsCoinciden" class="msg-error">Las contraseñas no coinciden</p>
          <p v-else-if="form.passwordConfirm && passwordsCoinciden && form.password" class="msg-ok">Las contraseñas coinciden</p>
          <label>Rol</label>
          <select v-model="form.rol" required @change="onRolChange">
            <option :value="null">Seleccionar</option>
            <option v-for="r in roles" :key="(r.id as number)" :value="r.id">{{ r.nombre }}</option>
          </select>
          <template v-if="form.rol && rolNombreActual === 'Carga'">
            <label class="area-label">Pertenece a:</label>
            <div class="radio-group">
              <label class="radio-label">
                <input v-model="tipoOrganizacionUsuario" type="radio" value="area" @change="form.area = null; form.secretaria = null" />
                Área
              </label>
              <label class="radio-label">
                <input v-model="tipoOrganizacionUsuario" type="radio" value="secretaria" @change="form.area = null; form.secretaria = null" />
                Secretaría
              </label>
            </div>
            <template v-if="tipoOrganizacionUsuario === 'area'">
              <label>Área</label>
              <select v-model="form.area" required>
                <option :value="null">Seleccionar área</option>
                <option v-for="a in areas" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
              </select>
            </template>
            <template v-else-if="tipoOrganizacionUsuario === 'secretaria'">
              <label>Secretaría</label>
              <select v-model="form.secretaria" required>
                <option :value="null">Seleccionar secretaría</option>
                <option v-for="s in secretarias" :key="(s.id as number)" :value="s.id">{{ s.codigo }} - {{ s.nombre }}</option>
              </select>
            </template>
          </template>
          <template v-else-if="form.rol && rolNombreActual === 'Visualización'">
            <label class="area-label">Área (opcional)</label>
            <select v-model="form.area">
              <option :value="null">Sin área</option>
              <option v-for="a in areasParaSeleccionar" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
            </select>
          </template>
          <label class="checkbox">
            <input v-model="form.estado" type="checkbox" />
            Activo
          </label>
          <div class="modal-actions">
            <button type="submit" class="btn-primary" :disabled="!puedeGuardar">
              <IconSave class="btn-icon" /> Guardar
            </button>
            <button type="button" class="btn-cancel" @click="closeForm">
              <IconCancel class="btn-icon" /> Cancelar
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page h1 { margin-bottom: 1rem; }
.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
  margin-bottom: 1rem;
}
.search-input {
  flex: 1;
  min-width: 200px;
  padding: 0.5rem 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 0.9rem;
}
.toolbar-buttons { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.btn-secondary {
  background: #16a34a;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
}
.btn-secondary:disabled { background: #94a3b8; cursor: not-allowed; }
.toolbar .btn-primary {
  background: #3b82f6;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
}
.table { width: 100%; background: white; border-radius: 8px; overflow: hidden; }
.table th, .table td { padding: 0.75rem 1rem; text-align: left; }
.table th { background: #f8fafc; }
.page .btn-action,
.page .btn-action-danger { margin-right: 0.5rem; }
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
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.checkbox { display: flex; align-items: center; gap: 0.5rem; }
.radio-group { display: flex; gap: 1rem; margin: 0.25rem 0; }
.radio-label { display: flex; align-items: center; gap: 0.5rem; cursor: pointer; }
.msg-error { font-size: 0.8rem; color: #dc2626; margin: 0.25rem 0 0; }
.msg-ok { font-size: 0.8rem; color: #16a34a; margin: 0.25rem 0 0; }
.input-error { border-color: #dc2626 !important; }
.modal-ver { max-width: 480px; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
</style>
