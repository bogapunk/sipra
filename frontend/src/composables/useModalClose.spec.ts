import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { defineComponent, ref } from 'vue'
import { useModalClose } from './useModalClose'

describe('useModalClose', () => {
  let addEventListenerSpy: ReturnType<typeof vi.spyOn>
  let removeEventListenerSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    addEventListenerSpy = vi.spyOn(document, 'addEventListener')
    removeEventListenerSpy = vi.spyOn(document, 'removeEventListener')
  })

  afterEach(() => {
    addEventListenerSpy.mockRestore()
    removeEventListenerSpy.mockRestore()
  })

  it('registra listener de keydown al montar', () => {
    const isOpen = ref(false)
    const onClose = vi.fn()

    const TestComp = defineComponent({
      setup() {
        useModalClose(isOpen, onClose)
        return () => null
      },
    })

    mount(TestComp)
    expect(addEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function))
  })

  it('llama onClose cuando se presiona Escape y el modal esta abierto', () => {
    const isOpen = ref(true)
    const onClose = vi.fn()

    const TestComp = defineComponent({
      setup() {
        useModalClose(isOpen, onClose)
        return () => null
      },
    })

    mount(TestComp)
    const handler = addEventListenerSpy.mock.calls.find((c) => c[0] === 'keydown')?.[1] as (e: KeyboardEvent) => void

    handler(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('NO llama onClose cuando el modal esta cerrado', () => {
    const isOpen = ref(false)
    const onClose = vi.fn()

    const TestComp = defineComponent({
      setup() {
        useModalClose(isOpen, onClose)
        return () => null
      },
    })

    mount(TestComp)
    const handler = addEventListenerSpy.mock.calls.find((c) => c[0] === 'keydown')?.[1] as (e: KeyboardEvent) => void

    handler(new KeyboardEvent('keydown', { key: 'Escape' }))
    expect(onClose).not.toHaveBeenCalled()
  })
})
