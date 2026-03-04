/** Validación de contraseña con requisitos de seguridad */
export interface ResultadoValidacion {
  valida: boolean
  errores: string[]
}

const MIN_LONGITUD = 8
const REQUIERE_MAYUSCULA = true
const REQUIERE_MINUSCULA = true
const REQUIERE_NUMERO = true
const REQUIERE_ESPECIAL = true
const CARACTERES_ESPECIALES = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/

export function validarPassword(password: string): ResultadoValidacion {
  const errores: string[] = []
  if (password.length < MIN_LONGITUD) {
    errores.push(`Mínimo ${MIN_LONGITUD} caracteres`)
  }
  if (REQUIERE_MAYUSCULA && !/[A-Z]/.test(password)) {
    errores.push('Al menos una mayúscula')
  }
  if (REQUIERE_MINUSCULA && !/[a-z]/.test(password)) {
    errores.push('Al menos una minúscula')
  }
  if (REQUIERE_NUMERO && !/\d/.test(password)) {
    errores.push('Al menos un número')
  }
  if (REQUIERE_ESPECIAL && !CARACTERES_ESPECIALES.test(password)) {
    errores.push('Al menos un carácter especial (!@#$%^&*...)')
  }
  return {
    valida: errores.length === 0,
    errores,
  }
}
