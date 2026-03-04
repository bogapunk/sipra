import ExcelJS from 'exceljs'

interface ProyectoData {
  nombre: string
  descripcion?: string
  estado?: string
  porcentaje_avance?: number
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

export async function exportarProyectoDetalle(
  proyecto: ProyectoData,
  etapas: Etapa[],
  indicadores: Indicador[],
  tareas: TareaItem[],
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
  row += 2

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
  ws.addRow(['Tareas (Orden | Título | Tarea padre | Estado | Avance | Fecha vencimiento)'])
  ws.getRow(row).font = { bold: true, size: 12 }
  row++
  if (tareas.length) {
    ws.addRow(['Orden', 'Título', 'Tarea padre', 'Estado', 'Avance %', 'Fecha de vencimiento'])
    ws.getRow(row).eachCell((c) => { c.font = { bold: true }; c.fill = headerStyle.fill })
    row++
    tareas.forEach((item) => {
      const t = item.tarea as Record<string, unknown>
      ws.addRow([
        item.orden,
        t.titulo || '',
        item.esSubtarea ? (t.tarea_padre_nombre || '—') : '—',
        t.estado || '',
        String(t.porcentaje_avance ?? 0),
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
