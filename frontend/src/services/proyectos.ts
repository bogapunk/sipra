import { api } from './api'

export const getProyectos = () => api.get('proyectos/')
export const getProyecto = (id: number) => api.get(`proyectos/${id}/`)
export const getProyectoVistaDetalle = (id: number, soloTareas = false) =>
  api.get(`proyectos/${id}/vista-detalle/`, { params: soloTareas ? { solo: 'tareas' } : {} })
export const createProyecto = (data: unknown) => api.post('proyectos/', data)
export const updateProyecto = (id: number, data: unknown) => api.patch(`proyectos/${id}/`, data)
export const deleteProyecto = (id: number) => api.delete(`proyectos/${id}/`)
