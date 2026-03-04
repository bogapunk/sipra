import { api } from './api'

export const getTareas = (params?: Record<string, string | number>) =>
  api.get('tareas/', { params })
export const getTarea = (id: number) => api.get(`tareas/${id}/`)
export const createTarea = (data: unknown) => api.post('tareas/', data)
export const updateTarea = (id: number, data: unknown) => api.patch(`tareas/${id}/`, data)
export const deleteTarea = (id: number) => api.delete(`tareas/${id}/`)
