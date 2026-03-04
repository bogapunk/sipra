<template>
  <div class="login-page">
    <div class="login-card">
      <h1>Sistema de Seguimiento de Proyectos</h1>
      <p class="subtitle">Acceso al sistema</p>
      <p class="note">Por ahora el sistema no requiere login. Usa el menú para navegar.</p>
      <router-link to="/dashboard" class="btn">Ir al Dashboard</router-link>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #1e293b 0%, #3b82f6 100%);
}
.login-card {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
  text-align: center;
  max-width: 400px;
}
.login-card h1 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #1e293b;
}
.subtitle {
  color: #64748b;
  margin-bottom: 1rem;
}
.note {
  font-size: 0.875rem;
  color: #94a3b8;
  margin-bottom: 1.5rem;
}
.btn {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background: #3b82f6;
  color: white;
  text-decoration: none;
  border-radius: 8px;
  font-weight: 500;
}
.btn:hover {
  background: #2563eb;
}
</style>
