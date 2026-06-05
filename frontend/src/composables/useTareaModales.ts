import { ref, computed, watch, type Ref } from 'vue'
import { api, invalidateApiCache } from '@/services/api'
import { useConfirmDelete } from '@/composables/useConfirmDelete'
import { useToast } from '@/composables/useToast'
import { useAuth } from '@/composables/useAuth'
import { useModalClose } from '@/composables/useModalClose'
import { extraerMensajeError } from '@/utils/apiError'
import { formatFechaHora } from '@/utils/fecha'
import { comentariosPorIdHistorial } from '@/utils/historialComentarios'

export type UseTareaModalesOptions = {
  proyectoId: Ref<number>
  proyectoNombre?: Ref<string | undefined>
  onUpdated?: () => void | Promise<void>
}

function parseListResponse(payload: unknown): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[]
  if (payload && typeof payload === 'object' && 'results' in (payload as object)) {
    const results = (payload as { results?: unknown }).results
    return Array.isArray(results) ? (results as Record<string, unknown>[]) : []
  }
  return []
}

export function useTareaModales(options: UseTareaModalesOptions) {
  const { confirmDelete } = useConfirmDelete()
  const toast = useToast()
  const { user, isAdmin, isVisualizador } = useAuth()
  const MINUTOS_EDICION = 15

  const areas = ref<Record<string, unknown>[]>([])
  const secretarias = ref<Record<string, unknown>[]>([])
  const usuarios = ref<Record<string, unknown>[]>([])
  const usuariosParaResponsable = ref<Record<string, unknown>[]>([])
  const cargaUsuariosResponsable = ref(false)
  const tipoOrganizacion = ref<'area' | 'secretaria' | 'ninguna'>('area')
  const showForm = ref(false)
  const editingId = ref<number | null>(null)
  const showAsignarModal = ref(false)
  const tareaAsignar = ref<Record<string, unknown> | null>(null)
  const showVerModal = ref(false)
  const tareaVer = ref<Record<string, unknown> | null>(null)
  const tipoAsignar = ref<'area' | 'secretaria' | 'ninguna'>('area')
  const areaAsignar = ref<number | null>(null)
  const secretariaAsignar = ref<number | null>(null)
  const guardandoAsignar = ref(false)
  const tareasPadreOptions = ref<Record<string, unknown>[]>([])
  const soporteCargado = ref(false)

  const form = ref({
    proyecto: null as number | null,
    tarea_padre: null as number | null,
    etapa: null as number | null,
    area: null as number | null,
    secretaria: null as number | null,
    titulo: '',
    descripcion: '',
    responsable: null as number | null,
    fecha_inicio: '',
    fecha_vencimiento: '',
    estado: 'Pendiente',
    porcentaje_avance: 0,
    prioridad: 'Media',
  })

  const proyectoBloqueado = computed(() => Number(options.proyectoId.value) > 0)
  const nombreProyectoActual = computed(() => options.proyectoNombre?.value || 'Proyecto actual')

  const tareasParaPadre = computed(() => {
    const raices = tareasPadreOptions.value
    const id = editingId.value
    if (!id) return raices
    return raices.filter((t) => (t.id as number) !== id)
  })

  function puedeEditarEliminarComentario(c: Record<string, unknown>): boolean {
    if (!user.value) return false
    if (isAdmin.value) return true
    if ((c.usuario as number) !== user.value.id) return false
    const fecha = new Date((c.fecha as string) || 0).getTime()
    return (Date.now() - fecha) / 60000 <= MINUTOS_EDICION
  }

  async function cargarDatosSoporte() {
    if (soporteCargado.value) return
    const [a, s, uRes] = await Promise.all([
      api.get('areas/', { params: { estado: 'true' } }).catch(() => ({ data: [] })),
      api.get('secretarias/', { params: { activa: 'true' } }).catch(() => ({ data: [] })),
      api.get('usuarios/selector/').catch(() =>
        api.get('usuarios/').then((r) => ({
          data: Array.isArray(r.data) ? r.data : (r.data?.results ?? []),
        })).catch(() => ({ data: [] })),
      ),
    ])
    areas.value = parseListResponse(a.data)
    secretarias.value = parseListResponse(s.data)
    usuarios.value = parseListResponse(uRes.data)
    soporteCargado.value = true
  }

  async function cargarTareasPadreSelector(proyectoId?: number | null) {
    try {
      const params: Record<string, string | number> = { solo_raices: 1 }
      const pid = proyectoId ?? options.proyectoId.value
      if (pid > 0) params.proyecto = pid
      const res = await api.get('tareas/', { params })
      tareasPadreOptions.value = parseListResponse(res.data)
    } catch {
      tareasPadreOptions.value = []
    }
  }

  async function loadUsuariosParaResponsable() {
    if (!showForm.value) return
    cargaUsuariosResponsable.value = true
    try {
      const params: Record<string, number> = {}
      if (tipoOrganizacion.value === 'area' && form.value.area) params.area = form.value.area
      else if (tipoOrganizacion.value === 'secretaria' && form.value.secretaria) params.secretaria = form.value.secretaria
      const res = await api.get('usuarios/selector/', { params })
      const lista = Array.isArray(res.data) ? res.data : []
      usuariosParaResponsable.value = lista
      const ids = new Set(lista.map((u: Record<string, unknown>) => u.id))
      if (form.value.responsable && !ids.has(form.value.responsable)) {
        form.value.responsable = null
      }
    } catch {
      usuariosParaResponsable.value = []
      form.value.responsable = null
    } finally {
      cargaUsuariosResponsable.value = false
    }
  }

  watch(
    () => [form.value.area, form.value.secretaria, tipoOrganizacion.value],
    () => { if (showForm.value) void loadUsuariosParaResponsable() },
    { deep: true },
  )

  async function notificarActualizacion() {
    invalidateApiCache('tareas')
    await options.onUpdated?.()
  }

  const openCreate = async () => {
    await cargarDatosSoporte()
    editingId.value = null
    await cargarTareasPadreSelector(options.proyectoId.value)
    tipoOrganizacion.value = 'area'
    form.value = {
      proyecto: options.proyectoId.value,
      tarea_padre: null,
      etapa: null,
      area: null,
      secretaria: null,
      titulo: '',
      descripcion: '',
      responsable: null,
      fecha_inicio: '',
      fecha_vencimiento: '',
      estado: 'Pendiente',
      porcentaje_avance: 0,
      prioridad: 'Media',
    }
    showForm.value = true
    void loadUsuariosParaResponsable()
  }

  const openEdit = async (t: Record<string, unknown>) => {
    await cargarDatosSoporte()
    editingId.value = t.id as number
    const areaId = t.area ? (typeof t.area === 'object' ? (t.area as { id?: number }).id : t.area) : null
    const secretariaId = t.secretaria
      ? (typeof t.secretaria === 'object' ? (t.secretaria as { id?: number }).id : t.secretaria)
      : null
    tipoOrganizacion.value = secretariaId ? 'secretaria' : (areaId ? 'area' : 'ninguna')
    await cargarTareasPadreSelector(options.proyectoId.value)
    const padreId = t.tarea_padre
      ? (typeof t.tarea_padre === 'object' ? (t.tarea_padre as { id?: number }).id : t.tarea_padre)
      : null
    form.value = {
      proyecto: options.proyectoId.value,
      tarea_padre: padreId != null ? Number(padreId) : null,
      etapa: t.etapa as number | null,
      area: areaId != null ? Number(areaId) : null,
      secretaria: secretariaId != null ? Number(secretariaId) : null,
      titulo: (t.titulo as string) || '',
      descripcion: (t.descripcion as string) || '',
      responsable: t.responsable as number,
      fecha_inicio: (t.fecha_inicio as string) || '',
      fecha_vencimiento: (t.fecha_vencimiento as string) || '',
      estado: (t.estado as string) || 'Pendiente',
      porcentaje_avance: (t.porcentaje_avance as number) || 0,
      prioridad: (t.prioridad as string) || 'Media',
    }
    showForm.value = true
    void loadUsuariosParaResponsable()
  }

  const save = async () => {
    try {
      const payload = { ...form.value } as Record<string, unknown>
      if (tipoOrganizacion.value === 'area') {
        payload.secretaria = null
      } else if (tipoOrganizacion.value === 'secretaria') {
        payload.area = null
      } else {
        payload.area = null
        payload.secretaria = null
      }
      if (!payload.proyecto) payload.etapa = null
      if (payload.tarea_padre === '' || payload.tarea_padre === undefined) payload.tarea_padre = null
      if (payload.proyecto === '' || payload.proyecto === undefined) payload.proyecto = null
      if (payload.responsable === '' || payload.responsable === undefined) payload.responsable = null
      if (payload.area === '' || payload.area === undefined) payload.area = null
      if (payload.secretaria === '' || payload.secretaria === undefined) payload.secretaria = null
      if (payload.etapa === '' || payload.etapa === undefined) payload.etapa = null
      if (!payload.titulo?.toString().trim()) {
        toast.error('El título es obligatorio.')
        return
      }
      if (!payload.responsable) {
        toast.error('Debe seleccionar un responsable.')
        return
      }
      if (
        (tipoOrganizacion.value === 'area' && form.value.area)
        || (tipoOrganizacion.value === 'secretaria' && form.value.secretaria)
      ) {
        if (!usuariosParaResponsable.value.length) {
          toast.error(
            'No hay usuarios cargados como responsables en esta '
            + (tipoOrganizacion.value === 'area' ? 'área' : 'secretaría')
            + '. Debe registrar o asignar responsables primero.',
          )
          return
        }
      }
      if (!payload.fecha_inicio || !payload.fecha_vencimiento) {
        toast.error('Las fechas de inicio y vencimiento son obligatorias.')
        return
      }
      if (proyectoBloqueado.value) {
        payload.proyecto = options.proyectoId.value
      }
      if (editingId.value) {
        await api.patch(`tareas/${editingId.value}/`, payload)
        toast.success('Tarea actualizada correctamente.')
      } else {
        await api.post('tareas/', payload)
        toast.success('Tarea creada correctamente.')
      }
      showForm.value = false
      await notificarActualizacion()
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al guardar la tarea.'))
    }
  }

  const comentariosTareaVer = ref<Record<string, unknown>[]>([])
  const adjuntosTareaVer = ref<Record<string, unknown>[]>([])
  const historialTareaVer = ref<Record<string, unknown>[]>([])
  const comentariosPorHistorialVerMap = computed(() =>
    comentariosPorIdHistorial(
      historialTareaVer.value.map((h) => ({ id: Number(h.id), fecha: String(h.fecha || '') })),
      comentariosTareaVer.value.map((c) => ({
        ...c,
        id: Number(c.id),
        fecha: String(c.fecha || ''),
      })) as Array<Record<string, unknown> & { id: number; fecha: string }>,
    ),
  )

  function comentariosTareaEnSegmento(hId: unknown): Record<string, unknown>[] {
    const id = Number(hId)
    if (!Number.isFinite(id)) return []
    return comentariosPorHistorialVerMap.value.get(id) ?? []
  }

  const nuevoComentarioVer = ref('')
  const comentarioEditandoVer = ref<number | null>(null)
  const textoEditandoVer = ref('')
  const adjuntoEditandoVer = ref<number | null>(null)
  const nombreAdjuntoEditandoVer = ref('')

  function puedeModificarAdjunto(a: Record<string, unknown>): boolean {
    if (!user.value) return false
    if (isAdmin.value) return true
    return (a.subido_por as number) === user.value.id
  }

  const archivoAdjuntoVer = ref<HTMLInputElement | null>(null)
  const subiendoAdjuntoVer = ref(false)

  const openVer = async (t: Record<string, unknown>) => {
    tareaVer.value = t
    showVerModal.value = true
    nuevoComentarioVer.value = ''
    historialTareaVer.value = []
    invalidateApiCache('historial')
    try {
      const [histRes, comRes, adjRes] = await Promise.all([
        api.get('historial/', { params: { tarea: t.id } }),
        api.get('comentarios-tarea/', { params: { tarea: t.id } }),
        api.get('adjuntos-tarea/', { params: { tarea: t.id } }),
      ])
      const rawHist = Array.isArray(histRes.data) ? histRes.data : (histRes.data?.results || [])
      historialTareaVer.value = (rawHist as Record<string, unknown>[]).sort((a, b) => {
        const fa = (a.fecha as string) || ''
        const fb = (b.fecha as string) || ''
        return fb.localeCompare(fa)
      })
      comentariosTareaVer.value = Array.isArray(comRes.data) ? comRes.data : (comRes.data?.results || [])
      adjuntosTareaVer.value = Array.isArray(adjRes.data) ? adjRes.data : (adjRes.data?.results || [])
    } catch {
      historialTareaVer.value = []
      comentariosTareaVer.value = []
      adjuntosTareaVer.value = []
    }
  }

  const closeVerModal = () => {
    showVerModal.value = false
    tareaVer.value = null
    historialTareaVer.value = []
    comentarioEditandoVer.value = null
    textoEditandoVer.value = ''
    adjuntoEditandoVer.value = null
    nombreAdjuntoEditandoVer.value = ''
  }

  async function guardarComentarioVer() {
    const t = tareaVer.value
    if (!t || !nuevoComentarioVer.value.trim()) return
    try {
      await api.post('comentarios-tarea/', { tarea: t.id, texto: nuevoComentarioVer.value.trim() })
      nuevoComentarioVer.value = ''
      const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
      comentariosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
      toast.success('Comentario guardado.')
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al guardar el comentario.'))
    }
  }

  function iniciarEdicionComentarioVer(c: Record<string, unknown>) {
    comentarioEditandoVer.value = c.id as number
    textoEditandoVer.value = (c.texto as string) || ''
  }

  function cancelarEdicionComentarioVer() {
    comentarioEditandoVer.value = null
    textoEditandoVer.value = ''
  }

  async function guardarEdicionComentarioVer() {
    const t = tareaVer.value
    const id = comentarioEditandoVer.value
    if (!t || !id || !textoEditandoVer.value.trim()) return
    try {
      await api.patch(`comentarios-tarea/${id}/`, { texto: textoEditandoVer.value.trim() })
      const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
      comentariosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
      comentarioEditandoVer.value = null
      textoEditandoVer.value = ''
      toast.success('Comentario actualizado.')
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al actualizar el comentario.'))
    }
  }

  async function eliminarComentarioVer(c: Record<string, unknown>) {
    const t = tareaVer.value
    if (!t || !(await confirmDelete())) return
    try {
      await api.delete(`comentarios-tarea/${c.id}/`)
      const res = await api.get('comentarios-tarea/', { params: { tarea: t.id } })
      comentariosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
      toast.success('Comentario eliminado.')
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al eliminar el comentario.'))
    }
  }

  function iniciarEdicionAdjuntoVer(a: Record<string, unknown>) {
    adjuntoEditandoVer.value = a.id as number
    nombreAdjuntoEditandoVer.value = (a.nombre_original as string) || ''
  }

  function cancelarEdicionAdjuntoVer() {
    adjuntoEditandoVer.value = null
    nombreAdjuntoEditandoVer.value = ''
  }

  async function guardarEdicionAdjuntoVer() {
    const t = tareaVer.value
    const id = adjuntoEditandoVer.value
    if (!t || !id || !nombreAdjuntoEditandoVer.value.trim()) return
    try {
      await api.patch(`adjuntos-tarea/${id}/`, { nombre_original: nombreAdjuntoEditandoVer.value.trim() })
      const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
      adjuntosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
      adjuntoEditandoVer.value = null
      nombreAdjuntoEditandoVer.value = ''
      toast.success('Adjunto actualizado.')
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al actualizar el adjunto.'))
    }
  }

  async function eliminarAdjuntoVer(a: Record<string, unknown>) {
    const t = tareaVer.value
    if (!t || !(await confirmDelete())) return
    try {
      await api.delete(`adjuntos-tarea/${a.id}/`)
      const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
      adjuntosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
      toast.success('Adjunto eliminado.')
    } catch (e) {
      toast.error(extraerMensajeError(e, 'Error al eliminar el adjunto.'))
    }
  }

  async function subirAdjuntoVer() {
    const t = tareaVer.value
    const input = archivoAdjuntoVer.value
    if (!t || !input?.files?.length) return
    const file = input.files[0]
    if (!file) return
    subiendoAdjuntoVer.value = true
    try {
      const formData = new FormData()
      formData.append('tarea', String(t.id))
      formData.append('archivo', file)
      formData.append('nombre_original', file.name)
      await api.post('adjuntos-tarea/', formData)
      const res = await api.get('adjuntos-tarea/', { params: { tarea: t.id } })
      adjuntosTareaVer.value = Array.isArray(res.data) ? res.data : (res.data?.results || [])
      toast.success('Archivo subido correctamente.')
      input.value = ''
    } catch {
      toast.error('Error al subir el archivo.')
    } finally {
      subiendoAdjuntoVer.value = false
    }
  }

  const openAsignar = async (t: Record<string, unknown>) => {
    await cargarDatosSoporte()
    tareaAsignar.value = t
    const areaId = t.area ? (typeof t.area === 'object' ? (t.area as { id?: number }).id : t.area) : null
    const secretariaId = t.secretaria
      ? (typeof t.secretaria === 'object' ? (t.secretaria as { id?: number }).id : t.secretaria)
      : null
    tipoAsignar.value = secretariaId ? 'secretaria' : (areaId ? 'area' : 'ninguna')
    areaAsignar.value = areaId != null ? Number(areaId) : null
    secretariaAsignar.value = secretariaId != null ? Number(secretariaId) : null
    showAsignarModal.value = true
  }

  const closeAsignarModal = () => {
    showAsignarModal.value = false
    tareaAsignar.value = null
    areaAsignar.value = null
    secretariaAsignar.value = null
  }

  const closeForm = () => { showForm.value = false }

  useModalClose(showVerModal, closeVerModal)
  useModalClose(showAsignarModal, closeAsignarModal)
  useModalClose(showForm, closeForm)

  const guardarAsignar = async () => {
    if (!tareaAsignar.value) return
    const id = tareaAsignar.value.id as number
    if (tipoAsignar.value === 'area' && !areaAsignar.value) {
      toast.error('Seleccione un área.')
      return
    }
    if (tipoAsignar.value === 'secretaria' && !secretariaAsignar.value) {
      toast.error('Seleccione una secretaría.')
      return
    }
    guardandoAsignar.value = true
    try {
      const payload = tipoAsignar.value === 'area'
        ? { area: areaAsignar.value, secretaria: null }
        : tipoAsignar.value === 'secretaria'
          ? { area: null, secretaria: secretariaAsignar.value }
          : { area: null, secretaria: null }
      await api.patch(`tareas/${id}/`, payload)
      toast.success('Tarea asignada correctamente.')
      closeAsignarModal()
      await notificarActualizacion()
    } catch {
      toast.error('Error al asignar la tarea.')
    } finally {
      guardandoAsignar.value = false
    }
  }

  return {
    areas,
    secretarias,
    usuariosParaResponsable,
    cargaUsuariosResponsable,
    tipoOrganizacion,
    showForm,
    editingId,
    showAsignarModal,
    tareaAsignar,
    showVerModal,
    tareaVer,
    tipoAsignar,
    areaAsignar,
    secretariaAsignar,
    guardandoAsignar,
    form,
    proyectoBloqueado,
    nombreProyectoActual,
    tareasParaPadre,
    isVisualizador,
    formatFechaHora,
    openCreate,
    openEdit,
    openVer,
    openAsignar,
    save,
    closeForm,
    closeVerModal,
    closeAsignarModal,
    guardarAsignar,
    comentariosTareaVer,
    adjuntosTareaVer,
    historialTareaVer,
    comentariosTareaEnSegmento,
    nuevoComentarioVer,
    comentarioEditandoVer,
    textoEditandoVer,
    adjuntoEditandoVer,
    nombreAdjuntoEditandoVer,
    archivoAdjuntoVer,
    subiendoAdjuntoVer,
    puedeEditarEliminarComentario,
    puedeModificarAdjunto,
    guardarComentarioVer,
    iniciarEdicionComentarioVer,
    cancelarEdicionComentarioVer,
    guardarEdicionComentarioVer,
    eliminarComentarioVer,
    iniciarEdicionAdjuntoVer,
    cancelarEdicionAdjuntoVer,
    guardarEdicionAdjuntoVer,
    eliminarAdjuntoVer,
    subirAdjuntoVer,
  }
}
