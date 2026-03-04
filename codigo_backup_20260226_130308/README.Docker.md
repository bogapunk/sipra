# Despliegue con Docker

## Producción (PostgreSQL + Backend + Frontend)

```bash
docker compose up -d
```

- **Frontend**: http://localhost (puerto 80)
- **Backend API**: http://localhost/api/
- **Base de datos**: PostgreSQL en puerto 5432

## Desarrollo (solo Backend con SQLite)

```bash
docker compose -f docker-compose.dev.yml up
```

- **Backend**: http://localhost:8000
- Ejecute el frontend localmente: `cd frontend && npm run dev`

## Variables de entorno (producción)

| Variable | Descripción |
|----------|-------------|
| `DATABASE_URL` | URL de PostgreSQL (ej: `postgres://user:pass@db:5432/dbname`) |
| `SECRET_KEY` | Clave secreta de Django |
| `DEBUG` | 0 para producción |
| `ALLOWED_HOSTS` | Hosts permitidos separados por coma |
