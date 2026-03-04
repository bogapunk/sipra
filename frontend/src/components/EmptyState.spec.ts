import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import EmptyState from './EmptyState.vue'

describe('EmptyState', () => {
  it('renderiza titulo y mensaje', () => {
    const wrapper = mount(EmptyState, {
      props: {
        titulo: 'Sin resultados',
        mensaje: 'No se encontraron resultados.',
      },
    })
    expect(wrapper.text()).toContain('Sin resultados')
    expect(wrapper.text()).toContain('No se encontraron resultados.')
  })

  it('acepta prop icono', () => {
    const wrapper = mount(EmptyState, {
      props: {
        titulo: 'Lista vacia',
        mensaje: 'No hay datos.',
        icono: 'lista',
      },
    })
    expect(wrapper.props('icono')).toBe('lista')
  })
})
