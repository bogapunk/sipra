type CellValue = string | number | boolean | null | undefined

type BarChartItem = {
  label: string
  value: number
  color?: string
}

let excelJsPromise: Promise<typeof import('exceljs')> | null = null

async function loadExcelJs() {
  excelJsPromise ??= import('exceljs')
  return excelJsPromise
}

async function baseWorkbook(title: string) {
  const { default: ExcelJS } = await loadExcelJs()
  const workbook = new ExcelJS.Workbook()
  workbook.creator = 'SIPRA'
  workbook.created = new Date()
  workbook.modified = new Date()
  workbook.subject = title
  workbook.title = title
  return workbook
}

function styleHeader(row: any) {
  row.font = { bold: true, size: 11 }
  row.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FFE2E8F0' },
  }
  row.alignment = { vertical: 'middle', horizontal: 'left', wrapText: true }
  row.height = 24
}

function styleBorders(ws: any, fromRow: number, toRow: number, totalCols: number) {
  for (let r = fromRow; r <= toRow; r++) {
    for (let c = 1; c <= totalCols; c++) {
      const cell = ws.getCell(r, c)
      cell.border = {
        top: { style: 'thin' },
        left: { style: 'thin' },
        bottom: { style: 'thin' },
        right: { style: 'thin' },
      }
    }
  }
}

export async function createWorkbook(title: string) {
  return baseWorkbook(title)
}

export function addReportHeader(
  ws: any,
  title: string,
  subtitle?: string,
  startRow = 1,
): number {
  ws.getCell(startRow, 1).value = title
  ws.getCell(startRow, 1).font = { bold: true, size: 16, color: { argb: 'FF0F172A' } }
  if (subtitle) {
    ws.getCell(startRow + 1, 1).value = subtitle
    ws.getCell(startRow + 1, 1).font = { size: 10, color: { argb: 'FF475569' } }
  }
  return startRow + (subtitle ? 3 : 2)
}

export function addKeyValueRows(
  ws: any,
  rows: Array<[string, CellValue]>,
  startRow: number,
): number {
  let rowIndex = startRow
  rows.forEach(([key, value]) => {
    ws.getCell(rowIndex, 1).value = key
    ws.getCell(rowIndex, 1).font = { bold: true, color: { argb: 'FF334155' } }
    ws.getCell(rowIndex, 2).value = value == null ? '-' : String(value)
    rowIndex += 1
  })
  ws.getColumn(1).width = Math.max(ws.getColumn(1).width || 0, 24)
  ws.getColumn(2).width = Math.max(ws.getColumn(2).width || 0, 40)
  return rowIndex + 1
}

export function addTable(
  ws: any,
  headers: string[],
  rows: Array<Array<CellValue>>,
  startRow: number,
): number {
  const headerRow = ws.getRow(startRow)
  headers.forEach((header, index) => {
    headerRow.getCell(index + 1).value = header
  })
  styleHeader(headerRow)

  rows.forEach((rowData, rowOffset) => {
    const row = ws.getRow(startRow + 1 + rowOffset)
    row.values = [null, ...rowData.map((value) => value == null ? '-' : value)]
    row.alignment = { vertical: 'top', horizontal: 'left', wrapText: true }
  })

  headers.forEach((header, index) => {
    const col = ws.getColumn(index + 1)
    const maxLen = Math.max(
      header.length,
      ...rows.map((row) => String(row[index] ?? '').length),
      12,
    )
    col.width = Math.min(Math.max(col.width || 0, maxLen + 2), 45)
  })

  const lastRow = startRow + rows.length
  styleBorders(ws, startRow, lastRow, headers.length)
  return lastRow + 2
}

export async function saveWorkbook(workbook: any, filename: string): Promise<void> {
  const baseName = filename.replace(/\.(csv|xlsx)$/i, '')
  const xlsxFilename = `${baseName}.xlsx`
  const buffer = await workbook.xlsx.writeBuffer()
  const blob = new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = xlsxFilename
  a.click()
  URL.revokeObjectURL(a.href)
}

export async function addImageFromDataUrl(
  ws: any,
  dataUrl: string,
  range: string,
): Promise<void> {
  const workbook = ws.workbook
  const imageId = workbook.addImage({
    base64: dataUrl,
    extension: 'png',
  })
  ws.addImage(imageId, range)
}

export function createDonutChartDataUrl(
  title: string,
  value: number,
  options?: { width?: number; height?: number },
): string {
  const width = options?.width ?? 720
  const height = options?.height ?? 360
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')
  if (!ctx) return ''

  const pct = Math.min(100, Math.max(0, Number(value) || 0))
  const pending = 100 - pct
  const centerX = 180
  const centerY = height / 2
  const radius = 84
  const lineWidth = 26
  const startAngle = -Math.PI / 2
  const endAngle = startAngle + (Math.PI * 2 * pct) / 100

  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, width, height)

  ctx.fillStyle = '#0f172a'
  ctx.font = 'bold 24px Segoe UI, Arial, sans-serif'
  ctx.fillText(title, 28, 40)

  ctx.beginPath()
  ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
  ctx.strokeStyle = '#e2e8f0'
  ctx.lineWidth = lineWidth
  ctx.stroke()

  const gradient = ctx.createLinearGradient(centerX - radius, centerY - radius, centerX + radius, centerY + radius)
  gradient.addColorStop(0, '#22c55e')
  gradient.addColorStop(1, '#16a34a')
  ctx.beginPath()
  ctx.arc(centerX, centerY, radius, startAngle, endAngle)
  ctx.strokeStyle = gradient
  ctx.lineWidth = lineWidth
  ctx.lineCap = 'round'
  ctx.stroke()

  ctx.fillStyle = '#0f172a'
  ctx.font = 'bold 34px Segoe UI, Arial, sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(`${pct.toFixed(1)}%`, centerX, centerY + 10)
  ctx.textAlign = 'left'

  ctx.fillStyle = '#334155'
  ctx.font = '16px Segoe UI, Arial, sans-serif'
  ctx.fillText(`Avance: ${pct.toFixed(1)}%`, 340, 150)
  ctx.fillText(`Pendiente: ${pending.toFixed(1)}%`, 340, 185)

  ctx.fillStyle = '#22c55e'
  ctx.fillRect(310, 137, 16, 16)
  ctx.fillStyle = '#cbd5e1'
  ctx.fillRect(310, 172, 16, 16)

  return canvas.toDataURL('image/png')
}

export function createHorizontalBarChartDataUrl(
  title: string,
  items: BarChartItem[],
  options?: { width?: number; itemHeight?: number; maxItems?: number; unit?: string },
): string {
  const width = options?.width ?? 980
  const itemHeight = options?.itemHeight ?? 34
  const maxItems = options?.maxItems ?? 12
  const unit = options?.unit ?? '%'
  const visibleItems = items.slice(0, maxItems)
  const height = Math.max(220, 110 + visibleItems.length * itemHeight)
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext('2d')
  if (!ctx) return ''

  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, width, height)

  ctx.fillStyle = '#0f172a'
  ctx.font = 'bold 24px Segoe UI, Arial, sans-serif'
  ctx.fillText(title, 24, 38)

  const left = 220
  const top = 78
  const chartWidth = width - left - 80
  const maxValue = Math.max(...visibleItems.map((item) => item.value), 1)

  visibleItems.forEach((item, index) => {
    const y = top + index * itemHeight
    const barWidth = Math.max(4, (Math.max(0, item.value) / maxValue) * chartWidth)

    ctx.fillStyle = '#475569'
    ctx.font = '14px Segoe UI, Arial, sans-serif'
    const label = item.label.length > 28 ? `${item.label.slice(0, 25)}...` : item.label
    ctx.fillText(label, 24, y + 16)

    ctx.fillStyle = '#e2e8f0'
    ctx.fillRect(left, y, chartWidth, 18)

    ctx.fillStyle = item.color || '#2563eb'
    ctx.fillRect(left, y, barWidth, 18)

    ctx.fillStyle = '#0f172a'
    ctx.font = 'bold 13px Segoe UI, Arial, sans-serif'
    ctx.fillText(`${item.value}${unit}`, left + chartWidth + 12, y + 14)
  })

  return canvas.toDataURL('image/png')
}
