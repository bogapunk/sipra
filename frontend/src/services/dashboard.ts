import { api } from './api'

export const getDashboard = () => api.get('dashboard/ejecutivo/')
export const getDashboardAnalitico = (params?: Record<string, string>) =>
  api.get('dashboard/analitico/', { params })
export const getDashboardUsuario = (usuarioId: number) =>
  api.get(`dashboard/usuarios/${usuarioId}/proyectos/`)
