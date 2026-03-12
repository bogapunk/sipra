<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api'
import GraficoTorta from '@/components/GraficoTorta.vue'
import GraficoBarrasTareas from '@/components/GraficoBarrasTareas.vue'
import LoaderSpinner from '@/components/LoaderSpinner.vue'
import {
  addImageFromDataUrl,
  addKeyValueRows,
  addReportHeader,
  addTable,
  createDonutChartDataUrl,
  createHorizontalBarChartDataUrl,
  createWorkbook,
  saveWorkbook,
} from '@/utils/exportWorkbook'

function avancePromedioGrupo(tareas: Record<string, unknown>[]): number {
  if (!tareas?.length) return 0
  const sum = tareas.reduce((a, t) => a + (Number(t.porcentaje_avance) || 0), 0)
  return sum / tareas.length
}
const carga = ref(true)
const error = ref(false)
const buscarArea = ref('')
const datos = ref<{ areas: { area: string; tareas: Record<string, unknown>[] }[] }>({ areas: [] })
const tareaSeleccionada = ref<Record<string, unknown> | null>(null)
const historialTarea = ref<Record<string, unknown>[]>([])

onMounted(async () => {
  carga.value = true
  error.value = false
  try {
    // Visualizador: acceso ampliado, ve la totalidad de proyectos sin restricción por área
    const params: Record<string, string> = {}
    const res = await api.get('avances/por-area/', { params })
    datos.value = res.data && typeof res.data === 'object' ? res.data : { areas: [] }
    if (!Array.isArray(datos.value.areas)) {
      datos.value.areas = []
    }
  } catch {
    error.value = true
    datos.value = { areas: [] }
  } finally {
    carga.value = false
  }
})

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

function avanceClase(pct: number): string {
  if (pct >= 100) return 'avance-completo'
  if (pct >= 70) return 'avance-alto'
  if (pct >= 40) return 'avance-medio'
  return 'avance-bajo'
}

async function abrirDetalleTarea(t: Record<string, unknown>) {
  tareaSeleccionada.value = t
  historialTarea.value = []
  try {
    const res = await api.get('historial/', { params: { tarea: t.id } })
    const raw = Array.isArray(res.data) ? res.data : (res.data?.results || [])
    historialTarea.value = (raw as Record<string, unknown>[]).sort((a, b) => {
      const fa = (a.fecha as string) || ''
      const fb = (b.fecha as string) || ''
      return fb.localeCompare(fa)
    })
  } catch {
    historialTarea.value = []
  }
}

function cerrarDetalleTarea() {
  tareaSeleccionada.value = null
}

const areasFiltradas = computed(() => {
  const q = buscarArea.value.trim().toLowerCase()
  if (!q) return datos.value.areas || []
  return (datos.value.areas || []).map((g: { area: string; tareas?: Record<string, unknown>[] }) => {
    const tareasMatch = (g.tareas || []).filter((t: Record<string, unknown>) => {
      const tit = String(t.titulo || '').toLowerCase()
      const proy = String(t.proyecto_nombre || '').toLowerCase()
      return tit.includes(q) || proy.includes(q)
    })
    const areaMatch = g.area.toLowerCase().includes(q)
    if (areaMatch) return { ...g, tareas: g.tareas }
    if (tareasMatch.length) return { ...g, tareas: tareasMatch }
    return null
  }).filter(Boolean) as { area: string; tareas: Record<string, unknown>[] }[]
})

const todasLasTareas = computed(() => {
  return (areasFiltradas.value || []).flatMap((g: { tareas?: Record<string, unknown>[] }) => g.tareas || [])
})

const avanceGlobal = computed(() => avancePromedioGrupo(todasLasTareas.value))

async function exportarReporte() {
  const workbook = createWorkbook('Avances por area')
  const resumen = workbook.addWorksheet('Resumen')
  let row = addReportHeader(
    resumen,
    'Avances por area',
    'Reporte completo con resumen, graficos y detalle de tareas.',
  )
  row = addKeyValueRows(resumen, [
    ['Fecha de exportacion', new Date().toLocaleString('es-CL')],
    ['Busqueda aplicada', buscarArea.value || 'Sin filtro'],
    ['Areas visibles', areasFiltradas.value.length],
    ['Tareas visibles', todasLasTareas.value.length],
    ['Avance promedio', `${avanceGlobal.value.toFixed(1)}%`],
  ], row)
  addTable(
    resumen,
    ['Area', 'Tareas', 'Avance promedio %'],
    areasFiltradas.value.map((grupo) => [
      grupo.area,
      grupo.tareas?.length || 0,
      avancePromedioGrupo(grupo.tareas || []).toFixed(1),
    ]),
    row,
  )

  const graficos = workbook.addWorksheet('Graficos')
  let chartRow = addReportHeader(graficos, 'Graficos de avances por area')
  const donutGlobal = createDonutChartDataUrl('Avance general consolidado', avanceGlobal.value)
  if (donutGlobal) {
    await addImageFromDataUrl(graficos, donutGlobal, `A${chartRow}:F${chartRow + 14}`)
    chartRow += 16
  }
  const barrasGlobal = createHorizontalBarChartDataUrl(
    'Avance por tarea (todas las areas)',
    todasLasTareas.value.map((t) => ({
      label: String(t.titulo || t.proyecto_nombre || 'Tarea'),
      value: Number(t.porcentaje_avance) || 0,
    })),
    { maxItems: 15 },
  )
  if (barrasGlobal) {
    await addImageFromDataUrl(graficos, barrasGlobal, `A${chartRow}:I${chartRow + 18}`)
    chartRow += 20
  }
  for (const grupo of areasFiltradas.value) {
    const donut = createDonutChartDataUrl(`Area: ${grupo.area}`, avancePromedioGrupo(grupo.tareas || []))
    const barras = createHorizontalBarChartDataUrl(
      `Avance por tarea - ${grupo.area}`,
      (grupo.tareas || []).map((t) => ({
        label: String(t.titulo || t.proyecto_nombre || 'Tarea'),
        value: Number(t.porcentaje_avance) || 0,
      })),
      { maxItems: 12 },
    )
    if (donut) {
      await addImageFromDataUrl(graficos, donut, `A${chartRow}:F${chartRow + 14}`)
      chartRow += 16
    }
    if (barras) {
      await addImageFromDataUrl(graficos, barras, `A${chartRow}:I${chartRow + 18}`)
      chartRow += 20
    }
  }

  const detalle = workbook.addWorksheet('Detalle de tareas')
  const detalleRow = addReportHeader(detalle, 'Detalle de tareas por area')
  addTable(
    detalle,
    ['Area', 'Tarea', 'Proyecto', 'Estado', 'Avance %', 'Ultimo incremento %', 'Fecha ultima actualizacion'],
    areasFiltradas.value.flatMap((grupo) =>
      (grupo.tareas || []).map((t) => [
        grupo.area,
        String(t.titulo || ''),
        String(t.proyecto_nombre || ''),
        String(t.estado || ''),
        Number(t.porcentaje_avance) || 0,
        t.ultimo_incremento == null ? '-' : Number(t.ultimo_incremento),
        String(t.fecha_ultima_actualizacion || ''),
      ]),
    ),
    detalleRow,
  )

  await saveWorkbook(workbook, `avances_por_area_${new Date().toISOString().slice(0, 10)}.xlsx`)
}
</script>

<template>
  <div class="page avances-ejecutivo">
    <header class="page-header">
      <h1>Avances por área</h1>
      <p class="subtitle">
        Vista ejecutiva: avance actual e incrementos realizados en cada tarea por área
      </p>
    </header>

    <div class="toolbar-avances">
      <div class="search-wrapper">
        <span class="search-icon">🔍</span>
        <input
          v-model="buscarArea"
          type="search"
          placeholder="Buscar por área, tarea o proyecto..."
          class="search-input"
          autocomplete="off"
        />
        <button
          v-if="buscarArea"
          type="button"
          class="search-clear"
          @click="buscarArea = ''"
          title="Limpiar búsqueda"
        >
          ✕
        </button>
        <span v-if="buscarArea && areasFiltradas.length >= 0" class="search-count">
          {{ areasFiltradas.length }} área(s) · {{ todasLasTareas.length }} tarea(s)
        </span>
      </div>
      <button type="button" class="btn-exportar" @click="exportarReporte" :disabled="carga || !areasFiltradas.length">
        Exportar reporte
      </button>
    </div>

    <LoaderSpinner v-if="carga" texto="Cargando avances por área..." />
    <div v-else-if="error" class="error-msg">Error al cargar los datos. Intente nuevamente.</div>

    <template v-else-if="areasFiltradas.length">
      <!-- Avance general consolidado -->
      <div v-if="todasLasTareas.length" class="resumen-consolidado">
        <h2 class="resumen-titulo">Avance general consolidado</h2>
        <p class="resumen-desc">Promedio de avance de todas las tareas. Compare con el detalle por área.</p>
        <div class="resumen-content">
          <GraficoTorta :avance="avanceGlobal" :size="180" />
          <div class="resumen-stats">
            <div class="stat-item">
              <span class="stat-valor">{{ todasLasTareas.length }}</span>
              <span class="stat-label">Tareas totales</span>
            </div>
            <div class="stat-item">
              <span class="stat-valor">{{ avanceGlobal.toFixed(1) }}%</span>
              <span class="stat-label">Avance promedio</span>
            </div>
            <div class="stat-item">
              <span class="stat-valor">{{ (100 - avanceGlobal).toFixed(1) }}%</span>
              <span class="stat-label">Pendiente</span>
            </div>
          </div>
        </div>
        <div class="resumen-barras">
          <GraficoBarrasTareas
            :tareas="todasLasTareas"
            titulo="Avance por tarea (todas las áreas)"
            :max-barras="15"
          />
        </div>
      </div>

      <div class="areas-container">
      <div
        v-for="grupo in areasFiltradas"
        :key="grupo.area"
        class="area-panel"
      >
        <h2 class="area-titulo">
          <span class="area-icono">▸</span>
          {{ grupo.area }}
          <span class="area-badge">{{ grupo.tareas?.length || 0 }} tareas</span>
        </h2>

        <div class="tareas-grid">
          <div
            v-for="t in grupo.tareas"
            :key="(t.id as number)"
            class="tarea-card clickable"
            @click="abrirDetalleTarea(t)"
          >
            <div class="tarea-header">
              <h3 class="tarea-titulo">{{ t.titulo }}</h3>
              <span v-if="t.proyecto_nombre" class="tarea-proyecto">{{ t.proyecto_nombre }}</span>
              <span class="clic-hint">Clic para ver detalle</span>
            </div>
            <div class="tarea-body">
              <div class="avance-principal">
                <div class="avance-bar-wrap">
                  <div
                    class="avance-bar"
                    :class="avanceClase(Number(t.porcentaje_avance) || 0)"
                    :style="{ width: `${Number(t.porcentaje_avance) || 0}%` }"
                  />
                </div>
                <span class="avance-valor">{{ Number(t.porcentaje_avance) || 0 }}%</span>
              </div>
              <div v-if="t.ultimo_incremento != null" class="incremento-wrap">
                <span class="incremento-label">Último incremento:</span>
                <span
                  class="incremento-valor"
                  :class="Number(t.ultimo_incremento) >= 0 ? 'incremento-positivo' : 'incremento-negativo'"
                >
                  {{ Number(t.ultimo_incremento) >= 0 ? '+' : '' }}{{ t.ultimo_incremento }}%
                </span>
                <span class="incremento-fecha">{{ formatearFecha(t.fecha_ultima_actualizacion) }}</span>
              </div>
              <div v-else class="incremento-sin-datos">Sin actualizaciones registradas</div>
            </div>
            <div class="tarea-footer">
              <span class="estado-badge" :class="'estado-' + String(t.estado || 'pendiente').toLowerCase().replace(/\s+/g, '-')">
                {{ t.estado || 'Pendiente' }}
              </span>
            </div>
          </div>
        </div>

        <GraficoTorta :avance="avancePromedioGrupo(grupo.tareas || [])" />
        <GraficoBarrasTareas
          :tareas="grupo.tareas || []"
          :titulo="`Avance por tarea - ${grupo.area}`"
        />
      </div>
    </div>
    </template>

    <div v-else class="empty-state">
      <p>{{ datos.areas?.length ? 'No hay áreas que coincidan con la búsqueda.' : 'No hay tareas cargadas.' }}</p>
    </div>

    <!-- Modal detalle tarea -->
    <div v-if="tareaSeleccionada" class="modal-overlay" @click.self="cerrarDetalleTarea">
      <div class="modal-detalle">
        <h2>{{ tareaSeleccionada.titulo }}</h2>
        <div class="detalle-meta">
          <span v-if="tareaSeleccionada.proyecto_nombre" class="detalle-proyecto">{{ tareaSeleccionada.proyecto_nombre }}</span>
          <span class="detalle-estado estado-badge" :class="'estado-' + String(tareaSeleccionada.estado || 'pendiente').toLowerCase().replace(/\s+/g, '-')">
            {{ tareaSeleccionada.estado || 'Pendiente' }}
          </span>
        </div>
        <div class="detalle-avance">
          <span class="avance-valor-grande">{{ Number(tareaSeleccionada.porcentaje_avance) || 0 }}%</span>
          <div class="avance-bar-wrap">
            <div
              class="avance-bar"
              :class="avanceClase(Number(tareaSeleccionada.porcentaje_avance) || 0)"
              :style="{ width: `${Number(tareaSeleccionada.porcentaje_avance) || 0}%` }"
            />
          </div>
        </div>
        <div v-if="historialTarea.length" class="detalle-historial">
          <h3>Historial de avances</h3>
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
              <span class="historial-avance">{{ h.porcentaje_avance }}%</span>
              <span v-if="h.usuario_nombre" class="historial-usuario">{{ h.usuario_nombre }}</span>
              <p v-if="h.comentario" class="historial-comentario">{{ h.comentario }}</p>
            </div>
          </div>
        </div>
        <p v-else class="sin-historial">Sin actualizaciones registradas.</p>
        <div class="modal-actions">
          <button type="button" class="btn-cerrar" @click="cerrarDetalleTarea">Cerrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.avances-ejecutivo {
  max-width: 1280px;
  margin: 0 auto;
}
.page-header {
  margin-bottom: 2rem;
}
.page-header h1 {
  font-size: 1.75rem;
  color: #1e293b;
  margin: 0 0 0.5rem;
}
.subtitle {
  color: #64748b;
  font-size: 1rem;
  margin: 0;
}
.toolbar-avances {
  margin-bottom: 1.5rem;
  display: flex;
  gap: 1rem;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
}
.btn-exportar {
  border: none;
  border-radius: 10px;
  background: #2563eb;
  color: white;
  padding: 0.7rem 1rem;
  font-weight: 600;
  cursor: pointer;
}
.btn-exportar:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.search-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
  max-width: 480px;
}
.search-wrapper .search-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1.1rem;
  opacity: 0.6;
  pointer-events: none;
}
.search-wrapper .search-input {
  flex: 1;
  min-width: 280px;
  padding: 0.75rem 2.5rem 0.75rem 2.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 1rem;
  background: white;
  transition: border-color 0.2s, box-shadow 0.2s;
}
.search-wrapper .search-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}
.search-wrapper .search-input::placeholder {
  color: #94a3b8;
}
.search-wrapper .search-clear {
  position: absolute;
  right: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  width: 1.5rem;
  height: 1.5rem;
  padding: 0;
  border: none;
  background: #e2e8f0;
  color: #64748b;
  border-radius: 50%;
  cursor: pointer;
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, color 0.2s;
}
.search-wrapper .search-clear:hover {
  background: #cbd5e1;
  color: #334155;
}
.search-wrapper .search-count {
  font-size: 0.85rem;
  color: #64748b;
  margin-left: 0.25rem;
}
.cargando, .error-msg {
  text-align: center;
  padding: 2rem;
  color: #64748b;
}
.error-msg {
  color: #dc2626;
}
.resumen-consolidado {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  padding: 1.5rem 1.5rem;
  margin-bottom: 2rem;
  border: 1px solid #e2e8f0;
}

.resumen-titulo {
  font-size: 1.15rem;
  margin: 0 0 0.35rem;
  color: #1e293b;
  font-weight: 600;
}

.resumen-desc {
  font-size: 0.9rem;
  color: #64748b;
  margin: 0 0 1.25rem;
}

.resumen-content {
  display: flex;
  align-items: center;
  gap: 2rem;
  flex-wrap: wrap;
}

.resumen-barras {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.resumen-stats {
  display: flex;
  gap: 2rem;
  flex-wrap: wrap;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}

.stat-valor {
  font-size: 1.5rem;
  font-weight: 700;
  color: #0d47a1;
}

.stat-label {
  font-size: 0.85rem;
  color: #64748b;
}

.areas-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}
.area-panel {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  overflow: hidden;
}
.area-titulo {
  font-size: 1.1rem;
  margin: 0;
  padding: 1rem 1.25rem;
  background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
  color: white;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.area-icono {
  font-size: 0.9rem;
  opacity: 0.9;
}
.area-badge {
  margin-left: auto;
  font-size: 0.8rem;
  background: rgba(255,255,255,0.2);
  padding: 0.2rem 0.5rem;
  border-radius: 6px;
}
.tareas-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  padding: 1.25rem;
}
.tarea-card {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  background: #fafbfc;
  transition: box-shadow 0.2s;
}
.tarea-card.clickable {
  cursor: pointer;
}
.tarea-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}
.tarea-header {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.tarea-titulo {
  font-size: 1rem;
  margin: 0;
  color: #1e293b;
  font-weight: 600;
}
.tarea-proyecto {
  font-size: 0.8rem;
  color: #64748b;
}
.clic-hint {
  font-size: 0.7rem;
  color: #94a3b8;
  margin-top: 0.25rem;
}
.tarea-body {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.avance-principal {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}
.avance-bar-wrap {
  flex: 1;
  height: 10px;
  background: #e2e8f0;
  border-radius: 5px;
  overflow: hidden;
}
.avance-bar {
  height: 100%;
  border-radius: 5px;
  transition: width 0.3s ease;
}
.avance-bar.avance-completo { background: #16a34a; }
.avance-bar.avance-alto { background: #22c55e; }
.avance-bar.avance-medio { background: #3b82f6; }
.avance-bar.avance-bajo { background: #f59e0b; }
.avance-valor {
  font-weight: 700;
  font-size: 1rem;
  color: #1e293b;
  min-width: 3rem;
}
.incremento-wrap {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.85rem;
}
.incremento-label {
  color: #64748b;
}
.incremento-valor {
  font-weight: 700;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
}
.incremento-positivo {
  background: #dcfce7;
  color: #16a34a;
}
.incremento-negativo {
  background: #fee2e2;
  color: #dc2626;
}
.incremento-fecha {
  color: #94a3b8;
  font-size: 0.8rem;
}
.incremento-sin-datos {
  font-size: 0.85rem;
  color: #94a3b8;
  font-style: italic;
}
.tarea-footer {
  padding-top: 0.5rem;
  border-top: 1px solid #e2e8f0;
}
.estado-badge {
  font-size: 0.75rem;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-weight: 500;
}
.estado-finalizada { background: #dcfce7; color: #16a34a; }
.estado-en-proceso { background: #dbeafe; color: #2563eb; }
.estado-pendiente { background: #fef3c7; color: #d97706; }
.estado-bloqueada { background: #fee2e2; color: #dc2626; }
.empty-state {
  text-align: center;
  padding: 3rem;
  color: #64748b;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
}
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-detalle {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
  max-width: 480px;
  width: 90%;
  max-height: 85vh;
  overflow-y: auto;
}
.modal-detalle h2 { font-size: 1.2rem; margin: 0 0 0.5rem; color: #1e293b; }
.detalle-meta { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; margin-bottom: 1rem; }
.detalle-proyecto { font-size: 0.9rem; color: #64748b; }
.detalle-avance { margin-bottom: 1rem; }
.avance-valor-grande { font-size: 1.5rem; font-weight: 700; color: #3b82f6; display: block; margin-bottom: 0.5rem; }
.detalle-historial h3 { font-size: 0.95rem; margin: 0 0 0.5rem; color: #334155; }
.historial-lista { max-height: 180px; overflow-y: auto; background: #f8fafc; border-radius: 8px; padding: 0.5rem; }
.historial-item { padding: 0.5rem 0.6rem; border-bottom: 1px solid #e2e8f0; font-size: 0.85rem; }
.historial-item:last-child { border-bottom: none; }
.historial-fecha { color: #64748b; margin-right: 0.5rem; }
.historial-avance { font-weight: 700; color: #3b82f6; margin-right: 0.5rem; }
.historial-usuario { color: #475569; }
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
.sin-historial { font-size: 0.9rem; color: #94a3b8; font-style: italic; margin-bottom: 1rem; }
.modal-actions { margin-top: 1rem; }
.btn-cerrar {
  background: #e2e8f0;
  color: #475569;
  border: none;
  padding: 0.5rem 1.25rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.95rem;
}
.btn-cerrar:hover { background: #cbd5e1; }
</style>
