import { ref } from 'vue'

const isOpen = ref(false)
let resolveFn: ((value: boolean) => void) | null = null

export function useConfirmDelete() {
  function confirmDelete(): Promise<boolean> {
    isOpen.value = true
    return new Promise<boolean>((resolve) => {
      resolveFn = resolve
    })
  }

  function resolve(value: boolean) {
    if (resolveFn) {
      const fn = resolveFn
      resolveFn = null
      isOpen.value = false
      fn(value)
    } else {
      isOpen.value = false
    }
  }

  return {
    isOpen,
    confirmDelete,
    resolve,
  }
}
