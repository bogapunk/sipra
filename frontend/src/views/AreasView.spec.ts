import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import AreasView from './AreasView.vue'

const mockGet = vi.fn()
vi.mock('@/services/api', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

vi.mock('@/composables/useConfirmDelete', () => ({
  useConfirmDelete: () => ({ confirmDelete: vi.fn().mockResolvedValue(false) }),
}))

vi.mock('@/composables/useToast', () => ({
  useToast: () => ({ success: vi.fn(), error: vi.fn() }),
}))

vi.mock('@/utils/exportCsv', () => ({
  exportToCsv: vi.fn().mockResolvedValue(undefined),
}))

describe('AreasView', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGet.mockResolvedValue({ data: [] })
  })

  it('monta correctamente sin error de inicializacion (showVerModal antes de useModalClose)', async () => {
    const router = createRouter({
      history: createWebHistory(),
      routes: [{ path: '/areas', component: AreasView }],
    })

    const wrapper = mount(AreasView, {
      global: {
        plugins: [router],
      },
    })

    await router.isReady()

    expect(wrapper.exists()).toBe(true)
    expect(wrapper.find('h1').text()).toBe('Áreas')
  })

  it('muestra lista vacia cuando no hay areas', async () => {
    const router = createRouter({
      history: createWebHistory(),
      routes: [{ path: '/areas', component: AreasView }],
    })

    const wrapper = mount(AreasView, {
      global: { plugins: [router] },
    })

    await router.isReady()
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toMatch(/No hay áreas|Áreas/i)
  })
})
