import { ref } from 'vue'

export interface ToastMessage {
  id: number
  text: string
  type: 'success' | 'error' | 'info'
}

const messages = ref<ToastMessage[]>([])
let idCounter = 0

export function useToast() {
  function show(text: string, type: ToastMessage['type'] = 'success') {
    const id = ++idCounter
    messages.value = [...messages.value, { id, text, type }]
    setTimeout(() => {
      messages.value = messages.value.filter((m) => m.id !== id)
    }, 3500)
  }

  function success(text: string) {
    show(text, 'success')
  }

  function error(text: string) {
    show(text, 'error')
  }

  function remove(id: number) {
    messages.value = messages.value.filter((m) => m.id !== id)
  }

  return {
    messages,
    success,
    error,
    show,
    remove,
  }
}
