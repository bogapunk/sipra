import { describe, it, expect } from 'vitest'
import { estadoVencimiento, claseVencimiento } from './vencimiento'

describe('vencimiento', () => {
  describe('estadoVencimiento', () => {
    it('retorna "dentro-plazo" cuando estado es Finalizada', () => {
      expect(estadoVencimiento('2020-01-01', 'Finalizada')).toBe('dentro-plazo')
    })

    it('retorna "sin-fecha" cuando no hay fecha', () => {
      expect(estadoVencimiento(null)).toBe('sin-fecha')
      expect(estadoVencimiento(undefined)).toBe('sin-fecha')
    })

    it('retorna "vencida" cuando la fecha ya paso', () => {
      const ayer = new Date()
      ayer.setDate(ayer.getDate() - 1)
      expect(estadoVencimiento(ayer.toISOString().slice(0, 10))).toBe('vencida')
    })

    it('retorna "proxima" cuando vence en los proximos 7 dias', () => {
      const en3Dias = new Date()
      en3Dias.setDate(en3Dias.getDate() + 3)
      expect(estadoVencimiento(en3Dias.toISOString().slice(0, 10))).toBe('proxima')
    })
  })

  describe('claseVencimiento', () => {
    it('retorna "" para sin-fecha', () => {
      expect(claseVencimiento('sin-fecha')).toBe('')
    })

    it('retorna clase correcta para vencida', () => {
      expect(claseVencimiento('vencida')).toBe('vencimiento-vencida')
    })
  })
})
