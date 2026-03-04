<template>
  <div id="app">
    <LoadingOverlay />
    <ConfirmDeleteModal />
    <ToastContainer />
    <AppLayout v-if="$route.path !== '/login'">
      <router-view />
    </AppLayout>
    <router-view v-else />
  </div>
</template>

<script setup lang="ts">
import AppLayout from './layouts/AppLayout.vue'
import LoadingOverlay from './components/LoadingOverlay.vue'
import ConfirmDeleteModal from './components/ConfirmDeleteModal.vue'
import ToastContainer from './components/ToastContainer.vue'
</script>

<style>
:root {
  --aif-primary: #0d47a1;
  --aif-secondary: #1565c0;
  --aif-accent: #1976d2;
}
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
body {
  font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
  background: #f1f5f9;
  color: #334155;
}
a {
  color: var(--aif-secondary);
}
a:hover {
  color: var(--aif-primary);
}
</style>
