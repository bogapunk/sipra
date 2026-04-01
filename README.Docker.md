# Despliegue con Docker

## Producción / desarrollo (Microsoft SQL Server)

El proyecto **solo** usa **SQL Server** (no PostgreSQL). Configure `DB_*` en `.env`.

```bash
docker compose -f docker-compose.yml --env-file .env up -d --build
```

- **Frontend**: http://localhost (puerto 80)
- **Backend API** (vía nginx del frontend): http://localhost/api/
- **Base de datos**: SQL Server externo (host/puerto en `.env`)

## Variables de entorno (referencia)

| Variable | Descripción |
|----------|-------------|
| `DB_TYPE` | `mssql` |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Conexión SQL Server |
| `DB_ODBC_DRIVER` | `ODBC Driver 17` o `18 for SQL Server` |
| `SECRET_KEY` | Clave secreta de Django |
| `DEBUG` | `0` en producción |
| `ALLOWED_HOSTS` | Hosts permitidos separados por coma |

Para producción con dominio HTTPS, ver `deploy/nginx-sipra.example.conf` y `docker-compose.produccion.yml`.
