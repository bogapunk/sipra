<script setup lang="ts">
import { computed, toRef } from 'vue'
import IconSave from '@/components/icons/IconSave.vue'
import IconCancel from '@/components/icons/IconCancel.vue'
import IconEdit from '@/components/icons/IconEdit.vue'
import IconTrash from '@/components/icons/IconTrash.vue'
import { useTareaModales } from '@/composables/useTareaModales'

const props = defineProps<{
  proyectoId: number
  proyectoNombre?: string
}>()

const emit = defineEmits<{
  updated: []
}>()

const {
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
} = useTareaModales({
  proyectoId: toRef(props, 'proyectoId'),
  proyectoNombre: computed(() => props.proyectoNombre),
  onUpdated: () => emit('updated'),
})

defineExpose({
  openVer,
  openEdit,
  openAsignar,
  openCreate,
})
</script>

<template>
  <div class="tarea-modales-host">
    <div v-if="showForm" class="modal-overlay" @click.self="closeForm">
      <div class="modal modal-wide">
        <h2>{{ editingId ? 'Editar' : 'Nueva' }} tarea</h2>
        <form @submit.prevent="save">
          <label>Título</label>
          <input v-model="form.titulo" placeholder="Título" required />
          <label>Descripción</label>
          <textarea v-model="form.descripcion" placeholder="Descripción" rows="2" />
          <label>Proyecto</label>
          <input
            v-if="proyectoBloqueado"
            :value="nombreProyectoActual"
            disabled
            class="input-readonly"
          />
          <select v-else v-model="form.proyecto" @change="!form.proyecto && (form.etapa = null)">
            <option :value="null">Sin proyecto (tarea independiente)</option>
          </select>
          <label>Tarea padre (subtarea de)</label>
          <select v-model="form.tarea_padre">
            <option :value="null">Ninguna (tarea raíz)</option>
            <option v-for="tr in tareasParaPadre" :key="(tr.id as number)" :value="tr.id">
              {{ tr.titulo }} {{ tr.proyecto_nombre ? `(${tr.proyecto_nombre})` : '(sin proyecto)' }}
            </option>
          </select>
          <label>Vinculación organizacional</label>
          <div class="radio-group">
            <label class="radio-label">
              <input v-model="tipoOrganizacion" type="radio" value="area" @change="form.area = null; form.secretaria = null" />
              Área
            </label>
            <label class="radio-label">
              <input v-model="tipoOrganizacion" type="radio" value="secretaria" @change="form.area = null; form.secretaria = null" />
              Secretaría
            </label>
            <label class="radio-label">
              <input v-model="tipoOrganizacion" type="radio" value="ninguna" @change="form.area = null; form.secretaria = null" />
              Ninguna
            </label>
          </div>
          <template v-if="tipoOrganizacion === 'area'">
            <label>Área</label>
            <select v-model="form.area">
              <option :value="null">Seleccionar área</option>
              <option v-for="a in areas" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
            </select>
          </template>
          <template v-else-if="tipoOrganizacion === 'secretaria'">
            <label>Secretaría</label>
            <select v-model="form.secretaria">
              <option :value="null">Seleccionar secretaría</option>
              <option v-for="s in secretarias" :key="(s.id as number)" :value="s.id">{{ s.codigo }} - {{ s.nombre }}</option>
            </select>
          </template>
          <label>Responsable</label>
          <template v-if="cargaUsuariosResponsable">
            <p class="mensaje-carga">Cargando usuarios...</p>
          </template>
          <template v-else-if="(tipoOrganizacion === 'area' && form.area) || (tipoOrganizacion === 'secretaria' && form.secretaria)">
            <template v-if="!usuariosParaResponsable.length">
              <p class="mensaje-sin-usuarios">No hay usuarios cargados como responsables en esta {{ tipoOrganizacion === 'area' ? 'área' : 'secretaría' }}.</p>
              <p class="mensaje-sin-usuarios-hint">Debe registrar o asignar responsables a esa dependencia antes de continuar.</p>
            </template>
            <select v-else v-model="form.responsable" required>
              <option :value="null">Seleccionar</option>
              <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">{{ u.nombre_completo || u.nombre }}</option>
            </select>
          </template>
          <select v-else v-model="form.responsable" required>
            <option :value="null">Seleccionar</option>
            <option v-for="u in usuariosParaResponsable" :key="(u.id as number)" :value="u.id">{{ u.nombre_completo || u.nombre }}</option>
          </select>
          <div class="row-dates">
            <div class="col-dates">
              <label>Fecha de inicio</label>
              <input v-model="form.fecha_inicio" type="date" required />
              <label>Fecha de vencimiento</label>
              <input v-model="form.fecha_vencimiento" type="date" required />
            </div>
            <div class="col-prioridad-form">
              <label>Prioridad</label>
              <select v-model="form.prioridad">
                <option value="Baja">Baja</option>
                <option value="Media">Media</option>
                <option value="Alta">Alta</option>
              </select>
            </div>
          </div>
          <div class="row">
            <div>
              <label>Estado</label>
              <select v-model="form.estado">
                <option value="Pendiente">Pendiente</option>
                <option value="En proceso">En proceso</option>
                <option value="Finalizada">Finalizada</option>
                <option value="Bloqueada">Bloqueada</option>
              </select>
            </div>
            <div>
              <label>Avance %</label>
              <input v-model.number="form.porcentaje_avance" type="number" min="0" max="100" />
            </div>
          </div>
          <div class="modal-actions">
            <button type="submit" class="btn-primary"><IconSave class="btn-icon" /> Guardar</button>
            <button type="button" class="btn-cancel" @click="closeForm"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="showVerModal && tareaVer" class="modal-overlay" @click.self="closeVerModal">
      <div class="modal modal-wide modal-ver">
        <h2>Detalle de la tarea</h2>
        <div class="detalle-content">
          <div class="detalle-row">
            <span class="detalle-label">Título</span>
            <span class="detalle-valor">{{ tareaVer.titulo }}</span>
          </div>
          <div v-if="tareaVer.descripcion" class="detalle-row">
            <span class="detalle-label">Descripción</span>
            <p class="detalle-valor detalle-desc">{{ tareaVer.descripcion }}</p>
          </div>
          <div class="detalle-grid">
            <div v-if="tareaVer.tarea_padre_nombre" class="detalle-row">
              <span class="detalle-label">Tarea padre</span>
              <span class="detalle-valor">{{ tareaVer.tarea_padre_nombre }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Proyecto</span>
              <span class="detalle-valor">{{ tareaVer.proyecto_nombre || 'Sin proyecto' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Área / Secretaría</span>
              <span class="detalle-valor">{{ tareaVer.organizacion_nombre || tareaVer.area_nombre || tareaVer.secretaria_nombre || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Responsable</span>
              <span class="detalle-valor">{{ tareaVer.responsable_nombre || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Estado</span>
              <span class="detalle-valor">{{ tareaVer.estado }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Avance</span>
              <span class="detalle-valor">{{ tareaVer.porcentaje_avance }}%</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Prioridad</span>
              <span class="detalle-valor">{{ tareaVer.prioridad }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Fecha inicio</span>
              <span class="detalle-valor">{{ tareaVer.fecha_inicio || '-' }}</span>
            </div>
            <div class="detalle-row">
              <span class="detalle-label">Fecha vencimiento</span>
              <span class="detalle-valor">{{ tareaVer.fecha_vencimiento || '-' }}</span>
            </div>
          </div>
        </div>
        <div class="detalle-section detalle-historial-avances">
          <h3>Historial de avances</h3>
          <p class="historial-leyenda">
            Cada registro muestra el cambio de %, las <strong>observaciones</strong> (texto al guardar el avance) y los <strong>comentarios de la tarea</strong> del mismo período.
          </p>
          <div v-if="historialTareaVer.length" class="historial-lista historial-lista-scroll">
            <div
              v-for="h in historialTareaVer"
              :key="(h.id as number)"
              class="historial-item"
              :class="{ 'historial-item-cierre': Number(h.porcentaje_avance) === 100 }"
            >
              <span v-if="Number(h.porcentaje_avance) === 100" class="historial-badge-cierre">✓ Tarea finalizada</span>
              <div class="historial-item-meta">
                <span class="historial-fecha">{{ formatFechaHora(h.fecha as string) }}</span>
                <span v-if="h.usuario_nombre" class="historial-usuario">{{ h.usuario_nombre }}</span>
                <span class="historial-valores">
                  {{ h.porcentaje_anterior != null ? `${h.porcentaje_anterior}%` : '—' }} → {{ h.porcentaje_avance }}%
                </span>
              </div>
              <div class="historial-observaciones">
                <span class="historial-obs-label">Observaciones del avance</span>
                <p v-if="String(h.comentario || '').trim()" class="historial-comentario-text">{{ String(h.comentario).trim() }}</p>
                <p v-else class="historial-sin-obs">Sin observaciones en esta actualización.</p>
              </div>
              <div class="historial-comentarios-tarea">
                <span class="historial-com-label">Comentarios de la tarea (período)</span>
                <ul v-if="comentariosTareaEnSegmento(h.id).length" class="historial-com-lista">
                  <li v-for="c in comentariosTareaEnSegmento(h.id)" :key="(c.id as number)" class="historial-com-item">
                    <span class="historial-com-meta">{{ c.usuario_nombre || 'Usuario' }} · {{ formatFechaHora(c.fecha as string) }}</span>
                    <p class="historial-com-texto">{{ c.texto }}</p>
                  </li>
                </ul>
                <p v-else class="historial-sin-com">Sin comentarios de tarea en este período.</p>
              </div>
            </div>
          </div>
          <p v-else class="sin-historial-avances">Aún no hay registros de avance en esta tarea.</p>
        </div>
        <div class="detalle-section">
          <h3>Historial de comentarios</h3>
          <p v-if="comentariosTareaVer.length" class="comentario-leyenda">Orden cronológico (del más antiguo al más reciente)</p>
          <div v-if="comentariosTareaVer.length" class="comentarios-lista">
            <div v-for="c in comentariosTareaVer" :key="(c.id as number)" class="comentario-item comentario-item-editable">
              <div class="comentario-header">
                <span class="comentario-meta">{{ c.usuario_nombre }} · {{ new Date(c.fecha as string).toLocaleString('es-CL') }}</span>
                <span v-if="c.editado_leyenda" class="editado-leyenda">{{ c.editado_leyenda }}</span>
                <div v-if="!isVisualizador && puedeEditarEliminarComentario(c)" class="comentario-acciones">
                  <button v-if="comentarioEditandoVer !== c.id" type="button" class="btn-icon-mini" title="Editar" @click="iniciarEdicionComentarioVer(c)">
                    <IconEdit class="btn-icon-sm" />
                  </button>
                  <button v-if="comentarioEditandoVer !== c.id" type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarComentarioVer(c)">
                    <IconTrash class="btn-icon-sm" />
                  </button>
                </div>
              </div>
              <template v-if="comentarioEditandoVer === c.id">
                <textarea v-model="textoEditandoVer" rows="2" class="edit-textarea" />
                <div class="edit-acciones">
                  <button type="button" class="btn-small" @click="guardarEdicionComentarioVer">Guardar</button>
                  <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionComentarioVer">Cancelar</button>
                </div>
              </template>
              <p v-else class="comentario-texto">{{ c.texto }}</p>
            </div>
          </div>
          <div v-if="!isVisualizador" class="comentario-add">
            <textarea v-model="nuevoComentarioVer" placeholder="Agregar comentario..." rows="2" />
            <button type="button" class="btn-small" @click="guardarComentarioVer" :disabled="!nuevoComentarioVer.trim()">Enviar</button>
          </div>
        </div>
        <div class="detalle-section">
          <h3>Adjuntos</h3>
          <div v-if="adjuntosTareaVer.length" class="adjuntos-lista">
            <div v-for="a in adjuntosTareaVer" :key="(a.id as number)" class="adjunto-item">
              <template v-if="adjuntoEditandoVer === a.id">
                <input v-model="nombreAdjuntoEditandoVer" type="text" class="adjunto-edit-input" />
                <div class="adjunto-edit-btns">
                  <button type="button" class="btn-small" @click="guardarEdicionAdjuntoVer">Guardar</button>
                  <button type="button" class="btn-small btn-cancel-mini" @click="cancelarEdicionAdjuntoVer">Cancelar</button>
                </div>
              </template>
              <template v-else>
                <a v-if="a.url" :href="a.url as string" target="_blank" rel="noopener" class="adjunto-link">📎 {{ a.nombre_original }}</a>
                <span v-else>📎 {{ a.nombre_original }}</span>
                <div v-if="puedeModificarAdjunto(a)" class="adjunto-acciones">
                  <button type="button" class="btn-icon-mini" title="Editar nombre" @click="iniciarEdicionAdjuntoVer(a)"><IconEdit class="btn-icon-sm" /></button>
                  <button type="button" class="btn-icon-mini btn-danger-mini" title="Eliminar" @click="eliminarAdjuntoVer(a)"><IconTrash class="btn-icon-sm" /></button>
                </div>
              </template>
            </div>
          </div>
          <div v-if="!isVisualizador" class="adjunto-upload">
            <input ref="archivoAdjuntoVer" type="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.png,.jpg,.jpeg" @change="subirAdjuntoVer" />
            <span v-if="subiendoAdjuntoVer" class="adjunto-loading">Subiendo...</span>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn-cancel" @click="closeVerModal"><IconCancel class="btn-icon" /> Cerrar</button>
        </div>
      </div>
    </div>

    <div v-if="showAsignarModal" class="modal-overlay" @click.self="closeAsignarModal">
      <div class="modal modal-wide">
        <h2>Asignar tarea</h2>
        <p v-if="tareaAsignar" class="modal-subtitle">{{ tareaAsignar.titulo }}</p>
        <p class="modal-hint">Asigne la tarea a un Área, una Secretaría o ninguna estructura.</p>
        <div class="asignar-form">
          <label>Tipo de destino</label>
          <div class="radio-group">
            <label class="radio-label">
              <input v-model="tipoAsignar" type="radio" value="area" @change="areaAsignar = null; secretariaAsignar = null" />
              Área
            </label>
            <label class="radio-label">
              <input v-model="tipoAsignar" type="radio" value="secretaria" @change="areaAsignar = null; secretariaAsignar = null" />
              Secretaría
            </label>
            <label class="radio-label">
              <input v-model="tipoAsignar" type="radio" value="ninguna" @change="areaAsignar = null; secretariaAsignar = null" />
              Ninguna
            </label>
          </div>
          <template v-if="tipoAsignar === 'area'">
            <label>Área</label>
            <select v-model="areaAsignar">
              <option :value="null">Seleccionar área</option>
              <option v-for="a in areas" :key="(a.id as number)" :value="a.id">{{ a.nombre }}</option>
            </select>
          </template>
          <template v-else-if="tipoAsignar === 'secretaria'">
            <label>Secretaría</label>
            <select v-model="secretariaAsignar">
              <option :value="null">Seleccionar secretaría</option>
              <option v-for="s in secretarias" :key="(s.id as number)" :value="s.id">{{ s.codigo }} - {{ s.nombre }}</option>
            </select>
          </template>
          <div class="modal-actions">
            <button type="button" class="btn-primary" @click="guardarAsignar" :disabled="guardandoAsignar">
              {{ guardandoAsignar ? 'Guardando...' : 'Confirmar asignación' }}
            </button>
            <button type="button" class="btn-cancel" @click="closeAsignarModal"><IconCancel class="btn-icon" /> Cancelar</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
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
  max-height: 90vh;
  overflow-y: auto;
}
.modal-wide { max-width: 500px; }
.modal form { display: flex; flex-direction: column; gap: 0.5rem; }
.modal input, .modal select, .modal textarea {
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}
.input-readonly { background: #f1f5f9; color: #475569; cursor: not-allowed; }
.row-dates { display: flex; gap: 1rem; align-items: flex-start; }
.col-dates { flex: 1; display: flex; flex-direction: column; gap: 0.75rem; }
.col-dates label { font-weight: 500; color: #374151; font-size: 0.9rem; }
.col-prioridad-form { flex: 1; display: flex; flex-direction: column; gap: 0.5rem; }
.row { display: flex; gap: 1rem; }
.row > div { flex: 1; }
.radio-group { display: flex; gap: 1rem; margin: 0.25rem 0; flex-wrap: wrap; }
.radio-label { display: flex; align-items: center; gap: 0.5rem; cursor: pointer; }
.modal-subtitle { font-size: 0.95rem; color: #64748b; margin: -0.25rem 0 0.5rem; }
.mensaje-carga { font-size: 0.9rem; color: #64748b; margin: 0.5rem 0; }
.mensaje-sin-usuarios { color: #b91c1c; font-weight: 600; margin: 0.5rem 0 0.25rem; }
.mensaje-sin-usuarios-hint { font-size: 0.85rem; color: #64748b; margin: 0 0 0.5rem; }
.modal-hint { font-size: 0.9rem; color: #64748b; margin: 0 0 1rem; line-height: 1.4; }
.asignar-form { display: flex; flex-direction: column; gap: 0.75rem; }
.modal-ver .detalle-content { max-height: 70vh; overflow-y: auto; }
.detalle-content { display: flex; flex-direction: column; gap: 1rem; margin-bottom: 1rem; }
.detalle-row { display: flex; flex-direction: column; gap: 0.25rem; }
.detalle-label { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.detalle-valor { font-size: 0.95rem; color: #1e293b; }
.detalle-desc { white-space: pre-wrap; line-height: 1.5; }
.detalle-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
.detalle-section { margin-top: 1rem; padding-top: 1rem; border-top: 1px solid #e2e8f0; }
.detalle-section h3 { font-size: 0.95rem; margin: 0 0 0.5rem; color: #334155; }
.historial-leyenda { font-size: 0.75rem; color: #64748b; margin: 0 0 0.65rem; line-height: 1.4; }
.historial-lista-scroll { max-height: min(320px, 45vh); overflow-y: auto; background: #f8fafc; border-radius: 10px; padding: 0.5rem; border: 1px solid #e2e8f0; }
.historial-item { display: flex; flex-direction: column; gap: 0.5rem; padding: 0.65rem 0.6rem; border-bottom: 1px solid #e2e8f0; font-size: 0.85rem; }
.historial-item:last-child { border-bottom: none; }
.historial-item-meta { display: flex; flex-wrap: wrap; align-items: baseline; gap: 0.35rem 0.5rem; }
.historial-fecha { color: #64748b; }
.historial-usuario { color: #475569; font-weight: 500; }
.historial-valores { font-weight: 700; color: #2563eb; }
.historial-observaciones { background: #fff; border-radius: 6px; padding: 0.5rem; border: 1px solid #e2e8f0; }
.historial-obs-label, .historial-com-label { font-size: 0.72rem; font-weight: 600; color: #64748b; text-transform: uppercase; }
.historial-comentario-text { margin: 0.25rem 0 0; }
.historial-sin-obs, .historial-sin-com, .sin-historial-avances { color: #94a3b8; font-size: 0.85rem; margin: 0; }
.historial-com-lista { list-style: none; padding: 0; margin: 0.35rem 0 0; }
.historial-com-meta { font-size: 0.72rem; color: #64748b; }
.historial-com-texto { margin: 0.15rem 0 0; }
.historial-item-cierre { background: linear-gradient(90deg, rgba(34, 197, 94, 0.08), transparent); border-radius: 6px; }
.historial-badge-cierre { font-size: 0.75rem; font-weight: 700; color: #15803d; }
.comentario-leyenda { font-size: 0.75rem; color: #94a3b8; margin: 0 0 0.5rem; }
.comentarios-lista { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 0.5rem; }
.comentario-item { padding: 0.5rem; background: #f8fafc; border-radius: 6px; }
.comentario-header { display: flex; flex-wrap: wrap; align-items: center; gap: 0.35rem; }
.comentario-meta { font-size: 0.75rem; color: #64748b; }
.comentario-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.comentario-texto { margin: 0.25rem 0 0; font-size: 0.9rem; }
.comentario-add { display: flex; flex-direction: column; gap: 0.5rem; margin-top: 0.5rem; }
.btn-icon-mini { padding: 0.2rem 0.4rem; background: #e2e8f0; border: none; border-radius: 4px; cursor: pointer; }
.btn-danger-mini { background: #fecaca; }
.btn-small { align-self: flex-start; padding: 0.35rem 0.75rem; background: #3b82f6; color: white; border: none; border-radius: 6px; font-size: 0.85rem; cursor: pointer; }
.btn-cancel-mini { background: #94a3b8 !important; }
.edit-textarea { width: 100%; padding: 0.5rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.edit-acciones { display: flex; gap: 0.35rem; }
.adjuntos-lista { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 0.5rem; }
.adjunto-item { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
.adjunto-acciones { margin-left: auto; display: flex; gap: 0.25rem; }
.adjunto-edit-input { flex: 1; min-width: 150px; padding: 0.35rem; font-size: 0.85rem; border: 1px solid #e2e8f0; border-radius: 6px; }
.adjunto-link { color: #2563eb; text-decoration: none; font-size: 0.9rem; }
.adjunto-loading { font-size: 0.85rem; color: #64748b; margin-left: 0.5rem; }
@media (max-width: 640px) {
  .detalle-grid { grid-template-columns: 1fr; }
}
</style>
