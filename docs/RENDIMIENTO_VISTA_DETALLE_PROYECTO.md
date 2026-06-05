# Rendimiento — Vista de detalle de proyecto

## Endpoint agregado

| Método | URL | Descripción |
|--------|-----|-------------|
| GET | `/api/proyectos/{id}/vista-detalle/` | Proyecto, tareas, etapas, indicadores, adjuntos y dependencias en **una sola respuesta** |
| GET | `/api/proyectos/{id}/vista-detalle/?solo=tareas` | Solo tareas (auto-refresh ligero) |

## Antes vs después

| Aspecto | Antes | Después |
|---------|-------|---------|
| Requests HTTP al abrir detalle | 7 (`proyecto`, `tareas`, `etapas`, `indicadores`, `adjuntos`, `areas`, `secretarias`) | **1** |
| Auto-refresh de tareas (cada 12 s) | Request completo a `/tareas/` con cache-bust | Request parcial `?solo=tareas` |
| Catálogos globales | Carga completa de áreas/secretarías | Solo dependencias del proyecto |

## Metadatos de tiempo (`_rendimiento`)

La API incluye tiempos en milisegundos (medidos en servidor):

```json
{
  "_rendimiento": {
    "proyecto_ms": 12.5,
    "tareas_ms": 45.2,
    "auxiliares_ms": 8.1,
    "total_ms": 68.4
  }
}
```

| Campo | Significado |
|-------|-------------|
| `proyecto_ms` | Consulta y serialización del proyecto |
| `tareas_ms` | Consulta y serialización de tareas del proyecto |
| `auxiliares_ms` | Etapas, indicadores y adjuntos |
| `total_ms` | Tiempo total del endpoint |

## Visualización en la UI

Al cargar el detalle, la pantalla muestra un indicador **“Carga del servidor: X ms”** con el desglose.  
El tiempo **cliente** (red + render) se registra en consola del navegador como `[ProyectoDetalle] carga cliente: N ms`.

## Objetivos de referencia (entorno local / LAN)

| Métrica | Objetivo |
|---------|----------|
| `total_ms` (servidor) | < 200 ms con proyectos de hasta ~100 tareas |
| Carga cliente percibida | < 500 ms en red local |
| Auto-refresh `solo=tareas` | < 100 ms servidor |

> Los tiempos reales dependen del motor de base de datos (SQLite vs SQL Server), volumen de tareas y latencia de red.

## Cómo medir manualmente

1. Abrir detalle de un proyecto.
2. Revisar el badge de rendimiento bajo el título.
3. En DevTools → Network, inspeccionar `vista-detalle/` (timing y tamaño de respuesta).
4. Para refresh: observar llamadas a `vista-detalle/?solo=tareas`.
