/// <reference types="vitest" />
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
  },
  plugins: [vue()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules/vue') || id.includes('node_modules/@vue')) return 'vendor-vue'
          if (id.includes('node_modules/axios')) return 'vendor-axios'
          if (id.includes('node_modules/echarts') || id.includes('node_modules/vue-echarts')) return 'vendor-charts'
          if (
            id.includes('node_modules/exceljs') ||
            id.includes('node_modules/jszip') ||
            id.includes('node_modules/pako') ||
            id.includes('node_modules/readable-stream') ||
            id.includes('node_modules/saxes') ||
            id.includes('node_modules/fast-csv')
          ) return 'vendor-export'
        },
      },
    },
    chunkSizeWarningLimit: 600,
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8001',
        changeOrigin: true
      },
      '/media': {
        target: 'http://localhost:8001',
        changeOrigin: true
      }
    }
  }
})
