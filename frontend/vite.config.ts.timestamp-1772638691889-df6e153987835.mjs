// vite.config.ts
import { defineConfig } from "file:///C:/Users/hboga/OneDrive/Desktop/Agencia%20Inovacion-Economia%20del%20conocimientos/Proyectos%202026/Proyecto%20Sistema%20de%20Planificaci%C3%B3n%20de%20Proyectos/Sipra/frontend/node_modules/vite/dist/node/index.js";
import vue from "file:///C:/Users/hboga/OneDrive/Desktop/Agencia%20Inovacion-Economia%20del%20conocimientos/Proyectos%202026/Proyecto%20Sistema%20de%20Planificaci%C3%B3n%20de%20Proyectos/Sipra/frontend/node_modules/@vitejs/plugin-vue/dist/index.mjs";
import { fileURLToPath, URL } from "node:url";
var __vite_injected_original_import_meta_url = "file:///C:/Users/hboga/OneDrive/Desktop/Agencia%20Inovacion-Economia%20del%20conocimientos/Proyectos%202026/Proyecto%20Sistema%20de%20Planificaci%C3%B3n%20de%20Proyectos/Sipra/frontend/vite.config.ts";
var vite_config_default = defineConfig({
  test: {
    globals: true,
    environment: "jsdom",
    include: ["src/**/*.{test,spec}.{ts,tsx}"]
  },
  plugins: [vue()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("node_modules/vue") || id.includes("node_modules/@vue")) return "vendor-vue";
          if (id.includes("node_modules/axios")) return "vendor-axios";
        }
      }
    },
    chunkSizeWarningLimit: 600
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", __vite_injected_original_import_meta_url))
    }
  },
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:8001",
        changeOrigin: true
      },
      "/media": {
        target: "http://localhost:8001",
        changeOrigin: true
      }
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCJDOlxcXFxVc2Vyc1xcXFxoYm9nYVxcXFxPbmVEcml2ZVxcXFxEZXNrdG9wXFxcXEFnZW5jaWEgSW5vdmFjaW9uLUVjb25vbWlhIGRlbCBjb25vY2ltaWVudG9zXFxcXFByb3llY3RvcyAyMDI2XFxcXFByb3llY3RvIFNpc3RlbWEgZGUgUGxhbmlmaWNhY2lcdTAwRjNuIGRlIFByb3llY3Rvc1xcXFxTaXByYVxcXFxmcm9udGVuZFwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiQzpcXFxcVXNlcnNcXFxcaGJvZ2FcXFxcT25lRHJpdmVcXFxcRGVza3RvcFxcXFxBZ2VuY2lhIElub3ZhY2lvbi1FY29ub21pYSBkZWwgY29ub2NpbWllbnRvc1xcXFxQcm95ZWN0b3MgMjAyNlxcXFxQcm95ZWN0byBTaXN0ZW1hIGRlIFBsYW5pZmljYWNpXHUwMEYzbiBkZSBQcm95ZWN0b3NcXFxcU2lwcmFcXFxcZnJvbnRlbmRcXFxcdml0ZS5jb25maWcudHNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL0M6L1VzZXJzL2hib2dhL09uZURyaXZlL0Rlc2t0b3AvQWdlbmNpYSUyMElub3ZhY2lvbi1FY29ub21pYSUyMGRlbCUyMGNvbm9jaW1pZW50b3MvUHJveWVjdG9zJTIwMjAyNi9Qcm95ZWN0byUyMFNpc3RlbWElMjBkZSUyMFBsYW5pZmljYWNpJUMzJUIzbiUyMGRlJTIwUHJveWVjdG9zL1NpcHJhL2Zyb250ZW5kL3ZpdGUuY29uZmlnLnRzXCI7Ly8vIDxyZWZlcmVuY2UgdHlwZXM9XCJ2aXRlc3RcIiAvPlxuaW1wb3J0IHsgZGVmaW5lQ29uZmlnIH0gZnJvbSAndml0ZSdcbmltcG9ydCB2dWUgZnJvbSAnQHZpdGVqcy9wbHVnaW4tdnVlJ1xuaW1wb3J0IHsgZmlsZVVSTFRvUGF0aCwgVVJMIH0gZnJvbSAnbm9kZTp1cmwnXG5cbmV4cG9ydCBkZWZhdWx0IGRlZmluZUNvbmZpZyh7XG4gIHRlc3Q6IHtcbiAgICBnbG9iYWxzOiB0cnVlLFxuICAgIGVudmlyb25tZW50OiAnanNkb20nLFxuICAgIGluY2x1ZGU6IFsnc3JjLyoqLyoue3Rlc3Qsc3BlY30ue3RzLHRzeH0nXSxcbiAgfSxcbiAgcGx1Z2luczogW3Z1ZSgpXSxcbiAgYnVpbGQ6IHtcbiAgICByb2xsdXBPcHRpb25zOiB7XG4gICAgICBvdXRwdXQ6IHtcbiAgICAgICAgbWFudWFsQ2h1bmtzKGlkKSB7XG4gICAgICAgICAgaWYgKGlkLmluY2x1ZGVzKCdub2RlX21vZHVsZXMvdnVlJykgfHwgaWQuaW5jbHVkZXMoJ25vZGVfbW9kdWxlcy9AdnVlJykpIHJldHVybiAndmVuZG9yLXZ1ZSdcbiAgICAgICAgICBpZiAoaWQuaW5jbHVkZXMoJ25vZGVfbW9kdWxlcy9heGlvcycpKSByZXR1cm4gJ3ZlbmRvci1heGlvcydcbiAgICAgICAgfSxcbiAgICAgIH0sXG4gICAgfSxcbiAgICBjaHVua1NpemVXYXJuaW5nTGltaXQ6IDYwMCxcbiAgfSxcbiAgcmVzb2x2ZToge1xuICAgIGFsaWFzOiB7XG4gICAgICAnQCc6IGZpbGVVUkxUb1BhdGgobmV3IFVSTCgnLi9zcmMnLCBpbXBvcnQubWV0YS51cmwpKVxuICAgIH1cbiAgfSxcbiAgc2VydmVyOiB7XG4gICAgcG9ydDogNTE3MyxcbiAgICBwcm94eToge1xuICAgICAgJy9hcGknOiB7XG4gICAgICAgIHRhcmdldDogJ2h0dHA6Ly9sb2NhbGhvc3Q6ODAwMScsXG4gICAgICAgIGNoYW5nZU9yaWdpbjogdHJ1ZVxuICAgICAgfSxcbiAgICAgICcvbWVkaWEnOiB7XG4gICAgICAgIHRhcmdldDogJ2h0dHA6Ly9sb2NhbGhvc3Q6ODAwMScsXG4gICAgICAgIGNoYW5nZU9yaWdpbjogdHJ1ZVxuICAgICAgfVxuICAgIH1cbiAgfVxufSlcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFDQSxTQUFTLG9CQUFvQjtBQUM3QixPQUFPLFNBQVM7QUFDaEIsU0FBUyxlQUFlLFdBQVc7QUFIMFksSUFBTSwyQ0FBMkM7QUFLOWQsSUFBTyxzQkFBUSxhQUFhO0FBQUEsRUFDMUIsTUFBTTtBQUFBLElBQ0osU0FBUztBQUFBLElBQ1QsYUFBYTtBQUFBLElBQ2IsU0FBUyxDQUFDLCtCQUErQjtBQUFBLEVBQzNDO0FBQUEsRUFDQSxTQUFTLENBQUMsSUFBSSxDQUFDO0FBQUEsRUFDZixPQUFPO0FBQUEsSUFDTCxlQUFlO0FBQUEsTUFDYixRQUFRO0FBQUEsUUFDTixhQUFhLElBQUk7QUFDZixjQUFJLEdBQUcsU0FBUyxrQkFBa0IsS0FBSyxHQUFHLFNBQVMsbUJBQW1CLEVBQUcsUUFBTztBQUNoRixjQUFJLEdBQUcsU0FBUyxvQkFBb0IsRUFBRyxRQUFPO0FBQUEsUUFDaEQ7QUFBQSxNQUNGO0FBQUEsSUFDRjtBQUFBLElBQ0EsdUJBQXVCO0FBQUEsRUFDekI7QUFBQSxFQUNBLFNBQVM7QUFBQSxJQUNQLE9BQU87QUFBQSxNQUNMLEtBQUssY0FBYyxJQUFJLElBQUksU0FBUyx3Q0FBZSxDQUFDO0FBQUEsSUFDdEQ7QUFBQSxFQUNGO0FBQUEsRUFDQSxRQUFRO0FBQUEsSUFDTixNQUFNO0FBQUEsSUFDTixPQUFPO0FBQUEsTUFDTCxRQUFRO0FBQUEsUUFDTixRQUFRO0FBQUEsUUFDUixjQUFjO0FBQUEsTUFDaEI7QUFBQSxNQUNBLFVBQVU7QUFBQSxRQUNSLFFBQVE7QUFBQSxRQUNSLGNBQWM7QUFBQSxNQUNoQjtBQUFBLElBQ0Y7QUFBQSxFQUNGO0FBQ0YsQ0FBQzsiLAogICJuYW1lcyI6IFtdCn0K
