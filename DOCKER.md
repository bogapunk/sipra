# Despliegue con Docker - SIP-AIF

Guía para ejecutar SIP-AIF con Docker. La base de datos es **Microsoft SQL Server** (externa); no se usa PostgreSQL.

## Requisitos

- Docker y Docker Compose
- Archivo `.env` en la raíz con `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_TYPE=mssql`, etc.

## Pasos para poner en marcha

### 1. Construir y levantar los contenedores

```bash
docker compose --env-file .env up -d --build
```

Esto levanta:

- **Backend** (Django + Gunicorn, conexión a SQL Server según `.env`)
- **Frontend** (Nginx sirviendo la app Vue y proxy `/api` al backend)

### 2. Acceder al sistema

**http://localhost** (puerto 80 del frontend)

### 3. Datos iniciales (primera vez)

```bash
docker compose exec backend python manage.py crear_datos_iniciales
```

## Comandos útiles

| Comando | Descripción |
|---------|-------------|
| `docker compose up -d --build` | Construir y levantar |
| `docker compose down` | Detener contenedores |
| `docker compose logs -f backend` | Logs del backend |
| `docker compose exec backend python manage.py migrate` | Migraciones |

## Variables de entorno

Ver `.env.example`. Clave: `SECRET_KEY`, y todas las `DB_*` para SQL Server.

## Estructura

```
SQL Server (externo)  ←  backend (Django :8001 dentro de la red Docker)
                              ↑
                        frontend (Nginx :80) → proxy /api → backend
```

## Producción

Usar `docker-compose.produccion.yml` y, si aplica, proxy HTTPS (ver `deploy/nginx-sipra.example.conf`).

Los backups de BD en volumen Docker: `sipra_backups` → `/app/backups` en el backend.
