import { onMounted, onUnmounted } from 'vue'

/**
 * Cierra el modal con Escape. El clic fuera ya se maneja con @click.self en el overlay.
 */
export function useModalClose(
  isOpen: { value: boolean },
  onClose: () => void
) {
  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape' && isOpen.value) {
      onClose()
    }
  }

  onMounted(() => {
    document.addEventListener('keydown', handleKeydown)
  })

  onUnmounted(() => {
    document.removeEventListener('keydown', handleKeydown)
  })
}
