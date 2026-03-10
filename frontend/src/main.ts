import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './assets/styles.css'
import { useAuth } from './composables/useAuth'

async function bootstrap() {
  const { syncUserFromServer } = useAuth()
  await syncUserFromServer()
  createApp(App).use(router).mount('#app')
}

bootstrap()
