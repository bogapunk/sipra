# Sistema de Seguimiento de Proyectos

Sistema web para seguimiento de proyectos con múltiples áreas, etapas y tareas.

## Arquitectura

- **Backend:** Django + Django REST Framework
- **Base de datos:** SQLite (desarrollo) / PostgreSQL (producción)
- **Frontend:** Vue 3 + TypeScript + Vite

## Requisitos

- Python 3.10+
- Node.js 18+

## Instalación

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r ../requirements.txt
python manage.py migrate
python manage.py crear_datos_iniciales
python manage.py runserver
```

El backend estará en `http://localhost:8000`.

### Frontend

```bash
cd frontend
npm install
npm run dev
```

El frontend estará en `http://localhost:5173` (proxy a API en 8000).

## Uso

1. Abre `http://localhost:5173` en el navegador.
2. Crea primero un **Rol** y un **Usuario** (o usa `admin@admin.com` tras `crear_datos_iniciales`).
3. Crea **Áreas**.
4. Crea **Proyectos** (selecciona el usuario creado como "creado por").
5. Agrega **Etapas** y **Tareas** a los proyectos.
6. Revisa el **Dashboard ejecutivo** para ver los KPIs.

## API

- `GET /api/dashboard/ejecutivo/` - Dashboard con KPIs
- `GET/POST /api/proyectos/` - CRUD proyectos
- `GET/POST /api/tareas/` - CRUD tareas (filtros: proyecto, area, estado)
- `GET/POST /api/areas/` - CRUD áreas
- `GET/POST /api/usuarios/` - CRUD usuarios
- `GET/POST /api/roles/` - CRUD roles
- `GET/POST /api/etapas/` - CRUD etapas (filtro: proyecto)
