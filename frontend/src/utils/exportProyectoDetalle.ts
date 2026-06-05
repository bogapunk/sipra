import ExcelJS from 'exceljs'
import {
  addImageFromDataUrl,
  createDonutChartDataUrl,
  createHorizontalBarChartDataUrl,
} from './exportWorkbook'

interface ProyectoData {
  nombre: string
  descripcion?: string
  estado?: string
  porcentaje_avance?: number
  avance_objetivos?: number
  presupuesto_total?: number
  fuente_financiamiento?: string
  presupuesto_cargado?: number
  presupuesto_disponible?: number
}

interface ObjetivoItem {
  descripcion?: string
  programa_nombre?: string
  estado_avance?: string
  avance_porcentaje?: number
}

interface Etapa {
  id: number
  nombre: string
  orden?: number
}

interface Indicador {
  id: number
  descripcion?: string
  unidad_medida?: string
  frecuencia?: string
}

interface TareaItem {
  tarea: {
    id: number
    titulo?: string
    estado?: string
    porcentaje_avance?: number
    fecha_vencimiento?: string
    tarea_padre_nombre?: string
  }
  esSubtarea: boolean
  orden: string
}

interface PresupuestoItem {
  id?: number
  categoria_gasto?: string
  monto?: number
  detalle?: string
  orden?: number
}

function estadoVencimientoExport(fecha?: string, estado?: string): 'vencida' | 'proxima' | 'dentro-plazo' | 'sin-fecha' {
  if (estado === 'Finalizada' || estado === 'Finalizado') return 'dentro-plazo'
  if (!fecha) return 'sin-fecha'
  const fechaDate = new Date(fecha)
  if (Number.isNaN(fechaDate.getTime())) return 'sin-fecha'
  const hoy = new Date()
  hoy.setHours(0, 0, 0, 0)
  fechaDate.setHours(0, 0, 0, 0)
  const limite = new Date(hoy)
  limite.setDate(limite.getDate() + 7)
  if (fechaDate < hoy) return 'vencida'
  if (fechaDate <= limite) return 'proxima'
  return 'dentro-plazo'
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency: 'ARS',
    maximumFractionDigits: 2,
  }).format(Number.isFinite(value) ? value : 0)
}

export async function exportarProyectoDetalle(
  proyecto: ProyectoData,
  etapas: Etapa[],
  indicadores: Indicador[],
  tareas: TareaItem[],
  presupuestoItems: PresupuestoItem[],
  objetivos: ObjetivoItem[],
  filename: string
): Promise<void> {
  const wb = new ExcelJS.Workbook()
  const ws = wb.addWorksheet('Detalle del proyecto', {
    views: [{ state: 'frozen', ySplit: 1 }],
  })

  // Estilo de encabezado
  const headerStyle = {
    font: { bold: true, size: 11 },
    fill: { type: 'pattern' as const, pattern: 'solid' as const, fgColor: { argb: 'FFE2E8F0' } },
    alignment: { vertical: 'middle' as const, horizontal: 'left' as const, wrapText: true },
  }

  let row = 1

  // Datos generales
  ws.addRow(['Datos generales del proyecto'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  ws.addRow(['Nombre', proyecto.nombre || ''])
  row++
  ws.addRow(['Descripción', (proyecto.descripcion || '').toString()])
  row++
  ws.addRow(['Estado', proyecto.estado || ''])
  row++
  ws.addRow(['Avance general (%)', String(proyecto.porcentaje_avance ?? 0)])
  row++
  ws.addRow(['Presupuesto total', formatCurrency(Number(proyecto.presupuesto_total ?? 0))])
  row++
  ws.addRow(['Fuente de financiamiento', proyecto.fuente_financiamiento || ''])
  row++
  ws.addRow(['Total cargado', formatCurrency(Number(proyecto.presupuesto_cargado ?? 0))])
  row++
  ws.addRow(['Disponible', formatCurrency(Number(proyecto.presupuesto_disponible ?? 0))])
  row += 2

  // Presupuesto
  ws.addRow(['Detalle presupuestario'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  if (presupuestoItems.length) {
    ws.addRow(['Orden', 'Categoría', 'Monto', 'Detalle / Observación'])
    ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
    row++
    presupuestoItems.forEach((item, index) => {
      ws.addRow([
        item.orden ?? index + 1,
        item.categoria_gasto || '',
        formatCurrency(Number(item.monto ?? 0)),
        item.detalle || '',
      ])
      row++
    })
  } else {
    ws.addRow(['Sin detalle presupuestario'])
    row++
  }
  row++

  // Objetivos del proyecto y sus estados
  const objetivosResumen = objetivos.reduce(
    (acc, o) => {
      const estado = String(o.estado_avance || 'No iniciado')
      if (estado === 'Finalizado') acc.finalizados += 1
      else if (estado === 'En progreso') acc.enProgreso += 1
      else acc.noIniciados += 1
      return acc
    },
    { noIniciados: 0, enProgreso: 0, finalizados: 0 },
  )
  const totalObjetivos = objetivos.length
  const avanceObjetivos = totalObjetivos
    ? Math.round(((objetivosResumen.enProgreso * 50 + objetivosResumen.finalizados * 100) / totalObjetivos) * 100) / 100
    : Number(proyecto.avance_objetivos ?? 0)

  ws.addRow(['Objetivos del proyecto'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  ws.addRow(['Avance general de objetivos (%)', String(avanceObjetivos)])
  row++
  ws.addRow(['Total de objetivos', String(totalObjetivos)])
  row++
  ws.addRow(['No iniciados', String(objetivosResumen.noIniciados)])
  row++
  ws.addRow(['En progreso', String(objetivosResumen.enProgreso)])
  row++
  ws.addRow(['Finalizados', String(objetivosResumen.finalizados)])
  row += 2

  ws.addRow(['Detalle de objetivos'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  if (totalObjetivos) {
    ws.addRow(['#', 'Objetivo', 'Programa', 'Estado', 'Avance %'])
    ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
    row++
    objetivos.forEach((o, index) => {
      ws.addRow([
        index + 1,
        o.descripcion || '',
        o.programa_nombre || '—',
        o.estado_avance || 'No iniciado',
        String(o.avance_porcentaje ?? 0),
      ])
      row++
    })
  } else {
    ws.addRow(['Sin objetivos asociados'])
    row++
  }
  row++

  // Resumen visual
  const resumenVencimiento = tareas.reduce(
    (acc, item) => {
      const t = item.tarea || {}
      const estado = estadoVencimientoExport(
        typeof t.fecha_vencimiento === 'string' ? t.fecha_vencimiento : undefined,
        typeof t.estado === 'string' ? t.estado : undefined,
      )
      if (estado === 'vencida') acc.vencidas += 1
      else if (estado === 'proxima') acc.proximas += 1
      else if (estado === 'dentro-plazo') acc.dentro += 1
      else acc.sinFecha += 1
      return acc
    },
    { vencidas: 0, proximas: 0, dentro: 0, sinFecha: 0 },
  )

  ws.addRow(['Resumen visual'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  ws.addRow(['Indicador', 'Valor'])
  ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
  row++
  ws.addRow(['Avance general (%)', String(proyecto.porcentaje_avance ?? 0)])
  row++
  ws.addRow(['Tareas vencidas', String(resumenVencimiento.vencidas)])
  row++
  ws.addRow(['Tareas próximas a vencer', String(resumenVencimiento.proximas)])
  row++
  ws.addRow(['Tareas dentro del plazo', String(resumenVencimiento.dentro)])
  row++
  ws.addRow(['Tareas sin fecha', String(resumenVencimiento.sinFecha)])
  row += 2

  ws.addRow(['Avance por tarea (datos del gráfico)'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  ws.addRow(['Orden', 'Título', 'Avance %'])
  ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
  row++
  if (tareas.length) {
    tareas.forEach((item) => {
      const t = item.tarea as Record<string, unknown>
      ws.addRow([
        item.orden,
        t.titulo || '',
        String(t.porcentaje_avance ?? 0),
      ])
      row++
    })
  } else {
    ws.addRow(['—', 'Sin tareas', '0'])
    row++
  }
  row++

  // Etapas
  ws.addRow(['Etapas'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  if (etapas.length) {
    ws.addRow(['Orden', 'Nombre'])
    ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
    row++
    etapas.forEach((e) => {
      ws.addRow([e.orden ?? '', e.nombre || ''])
      row++
    })
  } else {
    ws.addRow(['Sin etapas'])
    row++
  }
  row++

  // Indicadores
  ws.addRow(['Indicadores'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  if (indicadores.length) {
    ws.addRow(['Descripción', 'Unidad de medida', 'Frecuencia'])
    ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
    row++
    indicadores.forEach((i) => {
      ws.addRow([i.descripcion || '', i.unidad_medida || '', i.frecuencia || ''])
      row++
    })
  } else {
    ws.addRow(['Sin indicadores'])
    row++
  }
  row++

  // Tareas
  ws.addRow(['Tareas (Orden | Título | Tarea padre | Estado | Avance | Inicio | Área/Secretaría | Vencimiento)'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  if (tareas.length) {
    ws.addRow([
      'Orden',
      'Título',
      'Tarea padre',
      'Estado',
      'Avance %',
      'Fecha de inicio',
      'Área / Secretaría',
      'Fecha de vencimiento',
    ])
    ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
    row++
    tareas.forEach((item) => {
      const t = item.tarea as Record<string, unknown>
      const dep =
        (typeof t.organizacion_nombre === 'string' && t.organizacion_nombre.trim()) ||
        (t.area_nombre ? `Área: ${t.area_nombre}` : '') ||
        (t.secretaria_nombre ? `Secretaría: ${t.secretaria_nombre}` : '') ||
        '—'
      ws.addRow([
        item.orden,
        t.titulo || '',
        item.esSubtarea ? (t.tarea_padre_nombre || '—') : '—',
        t.estado || '',
        String(t.porcentaje_avance ?? 0),
        t.fecha_inicio || '—',
        dep,
        t.fecha_vencimiento || '—',
      ])
      row++
    })
  } else {
    ws.addRow(['Sin tareas'])
    row++
  }

  // Anchos de columna
  ws.columns.forEach((col, i) => {
    let maxLen = 12
    col?.eachCell?.({ includeEmpty: true }, (cell, r) => {
      const val = cell.value?.toString() || ''
      maxLen = Math.max(maxLen, val.length)
    })
    col.width = Math.min(maxLen + 2, 50)
  })

  // Hoja de gráficos y resúmenes visuales
  try {
    const wsGraficos = wb.addWorksheet('Gráficos')
    wsGraficos.getCell('A1').value = `Resumen visual - ${proyecto.nombre || 'Proyecto'}`
    wsGraficos.getCell('A1').font = { bold: true, size: 16, color: { argb: 'FF0F172A' } }
    let chartRow = 3

    const avanceGeneral = Number(proyecto.porcentaje_avance ?? 0)
    const donutGeneral = createDonutChartDataUrl('Avance general del proyecto', avanceGeneral)
    if (donutGeneral) {
      await addImageFromDataUrl(wsGraficos, donutGeneral, `A${chartRow}:H${chartRow + 16}`)
      chartRow += 18
    }

    const donutObjetivos = createDonutChartDataUrl('Avance general de objetivos', avanceObjetivos)
    if (donutObjetivos) {
      await addImageFromDataUrl(wsGraficos, donutObjetivos, `A${chartRow}:H${chartRow + 16}`)
      chartRow += 18
    }

    if (totalObjetivos) {
      const barrasObjetivos = createHorizontalBarChartDataUrl(
        'Objetivos por estado',
        [
          { label: 'No iniciados', value: objetivosResumen.noIniciados, color: '#94a3b8' },
          { label: 'En progreso', value: objetivosResumen.enProgreso, color: '#f59e0b' },
          { label: 'Finalizados', value: objetivosResumen.finalizados, color: '#16a34a' },
        ],
        { unit: '', maxItems: 3 },
      )
      if (barrasObjetivos) {
        await addImageFromDataUrl(wsGraficos, barrasObjetivos, `A${chartRow}:H${chartRow + 12}`)
        chartRow += 14
      }
    }

    const semaforo = createHorizontalBarChartDataUrl(
      'Tareas por estado de vencimiento',
      [
        { label: 'Vencidas', value: resumenVencimiento.vencidas, color: '#dc2626' },
        { label: 'Próximas a vencer', value: resumenVencimiento.proximas, color: '#f59e0b' },
        { label: 'Dentro del plazo', value: resumenVencimiento.dentro, color: '#16a34a' },
        { label: 'Sin fecha', value: resumenVencimiento.sinFecha, color: '#94a3b8' },
      ],
      { unit: '', maxItems: 4 },
    )
    if (semaforo) {
      await addImageFromDataUrl(wsGraficos, semaforo, `A${chartRow}:H${chartRow + 13}`)
      chartRow += 15
    }

    if (tareas.length) {
      const barrasTareas = createHorizontalBarChartDataUrl(
        'Avance por tarea',
        tareas.map((item) => ({
          label: (item.tarea?.titulo as string) || 'Sin título',
          value: Number(item.tarea?.porcentaje_avance) || 0,
        })),
        { unit: '%', maxItems: 15 },
      )
      if (barrasTareas) {
        await addImageFromDataUrl(wsGraficos, barrasTareas, `A${chartRow}:H${chartRow + 18}`)
      }
    }
  } catch {
    // Si la generación de imágenes falla, se conserva la exportación de datos.
  }

  const baseName = filename.replace(/\.(csv|xlsx)$/i, '')
  const xlsxFilename = `${baseName}.xlsx`
  const buffer = await wb.xlsx.writeBuffer()
  const blob = new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = xlsxFilename
  a.click()
  URL.revokeObjectURL(a.href)
}
