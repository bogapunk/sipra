import { describe, it, expect } from 'vitest'
import { invalidateApiCache } from './api'

describe('api', () => {
  describe('invalidateApiCache', () => {
    it('existe y es una funcion', () => {
      expect(typeof invalidateApiCache).toBe('function')
    })

    it('no lanza error al llamar sin argumentos', () => {
      expect(() => invalidateApiCache()).not.toThrow()
    })

    it('no lanza error al llamar con un patron', () => {
      expect(() => invalidateApiCache('dashboard')).not.toThrow()
    })
  })
})
