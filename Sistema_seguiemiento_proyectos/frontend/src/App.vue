<template>
  <div id="app">
    <AppLayout v-if="$route.path !== '/login'">
      <router-view />
    </AppLayout>
    <router-view v-else />
  </div>
</template>

<script setup lang="ts">
import AppLayout from './layouts/AppLayout.vue'
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
body {
  font-family: system-ui, -apple-system, sans-serif;
  background: #f5f5f5;
}
</style>
