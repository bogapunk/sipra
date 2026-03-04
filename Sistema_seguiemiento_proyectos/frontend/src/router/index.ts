import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/login', component: () => import('@/views/LoginView.vue') },
  { path: '/dashboard', component: () => import('@/views/DashboardView.vue') },
  { path: '/proyectos', component: () => import('@/views/ProyectosView.vue') },
  { path: '/proyectos/:id', component: () => import('@/views/ProyectoDetalleView.vue') },
  { path: '/tareas', component: () => import('@/views/TareasView.vue') },
  { path: '/areas', component: () => import('@/views/AreasView.vue') },
  { path: '/usuarios', component: () => import('@/views/UsuariosView.vue') },
  { path: '/roles', component: () => import('@/views/RolesView.vue') },
]

export default createRouter({
  history: createWebHistory(),
  routes,
})
