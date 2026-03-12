let excelJsPromise: Promise<typeof import('exceljs')> | null = null

async function loadExcelJs() {
  excelJsPromise ??= import('exceljs')
  return excelJsPromise
}

/**
 * Exporta datos a Excel (.xlsx) con formato estructurado:
 * - Encabezados claros y en negrita
 * - Columnas con ancho adecuado
 * - Filas alineadas
 * - Distribución ordenada y profesional
 */
export async function exportToCsv(
  headers: string[],
  rows: string[][],
  filename: string
): Promise<void> {
  const { default: ExcelJS } = await loadExcelJs()
  const wb = new ExcelJS.Workbook()
  const ws = wb.addWorksheet('Datos', {
    views: [{ state: 'frozen', ySplit: 1 }],
  })

  // Fila de encabezados
  const headerRow = ws.addRow(headers)
  headerRow.font = { bold: true, size: 11 }
  headerRow.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFE2E8F0' },
  }
  headerRow.alignment = { vertical: 'middle', horizontal: 'left', wrapText: true }
  headerRow.height = 24

  // Filas de datos
  rows.forEach((rowData) => {
    const row = ws.addRow(rowData)
    row.alignment = { vertical: 'top', horizontal: 'left', wrapText: true }
  })

  // Ancho de columnas según contenido
  for (let i = 0; i < headers.length; i++) {
    const maxLen = Math.max(
      (headers[i]?.length ?? 0),
      ...rows.map((r) => String(r[i] ?? '').length),
      12
    )
    ws.getColumn(i + 1).width = Math.min(maxLen + 2, 45)
  }

  // Bordes para toda la tabla
  const lastRow = rows.length + 1
  const lastCol = headers.length
  for (let r = 1; r <= lastRow; r++) {
    for (let c = 1; c <= lastCol; c++) {
      const cell = ws.getCell(r, c)
      cell.border = {
        top: { style: 'thin' },
        left: { style: 'thin' },
        bottom: { style: 'thin' },
        right: { style: 'thin' },
      }
    }
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
