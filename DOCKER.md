# Despliegue con Docker - SIP-AIF

Guía para ejecutar SIP-AIF (Sistema Integral de Proyectos) en producción con Docker.

## Requisitos

- Docker
- Docker Compose

## Pasos para poner en marcha

### 1. Construir y levantar los contenedores

Desde la raíz del proyecto:

```bash
docker compose up -d --build
```

Esto construye las imágenes y levanta:
- **PostgreSQL** (base de datos)
- **Backend** (Django + Gunicorn)
- **Frontend** (Nginx sirviendo la app Vue)

### 2. Acceder al sistema

Abre el navegador en: **http://localhost**

(Puerto 80 por defecto. Si 80 está ocupado, cambia en `docker-compose.yml` la línea `"80:80"` por `"8080:80"` y accede a http://localhost:8080)

### 3. Crear datos iniciales (primera vez)

Si es la primera vez y necesitas usuarios de prueba:

```bash
docker compose exec backend python manage.py crear_datos_iniciales
```

Para crear un superusuario manualmente:

```bash
docker compose exec backend python manage.py createsuperuser
```

## Comandos útiles

| Comando | Descripción |
|---------|-------------|
| `docker compose up -d --build` | Construir y levantar en segundo plano |
| `docker compose down` | Detener y eliminar contenedores |
| `docker compose logs -f` | Ver logs en tiempo real |
| `docker compose ps` | Ver estado de los contenedores |
| `docker compose exec backend python manage.py migrate` | Ejecutar migraciones |
| `docker compose exec backend python manage.py crear_datos_iniciales` | Cargar datos iniciales |

## Variables de entorno (producción)

Crea un archivo `.env` en la raíz del proyecto para producción:

```env
SECRET_KEY=tu-clave-secreta-muy-larga-y-aleatoria
```

Para cambiar la contraseña de PostgreSQL, edita `docker-compose.yml` en el servicio `db` y `backend` (variable `DATABASE_URL`).

## Estructura

```
db (PostgreSQL)  →  backend (Django:8001)  ←  frontend (Nginx:80)
                         ↑
                    Base de datos
```

- El usuario accede a **puerto 80** (frontend)
- Nginx sirve la app Vue y redirige `/api` al backend
- El backend usa PostgreSQL como base de datos

## Reinicio automático

Los servicios tienen `restart: unless-stopped`, por lo que:
- Se reinician si fallan
- Se inician al arrancar el servidor (si Docker está configurado para iniciarse al boot)

## Persistencia de datos

Los datos de PostgreSQL se guardan en el volumen `postgres_data`. Aunque elimines los contenedores con `docker compose down`, los datos se mantienen. Para borrarlos:

```bash
docker compose down -v
```

## Producción con PostgreSQL externo

Usa `docker-compose.produccion.yml` para conectar a una base PostgreSQL externa:

```bash
docker compose -f docker-compose.yml -f docker-compose.produccion.yml up -d --build
```

El frontend se expone en el puerto **8081**.

### Actualizar frontend sin rebuild (volumen vinculado)

El `docker-compose.produccion.yml` monta el directorio `./frontend` como volumen. Así puedes actualizar el sistema tras un `git pull` **sin reconstruir la imagen Docker**:

1. En el servidor, actualiza el código:
   ```bash
   git pull
   ```

2. Reinicia solo el contenedor frontend (reconstruye el frontend al iniciar):
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.produccion.yml up -d --force-recreate frontend
   ```

El contenedor ejecutará `npm ci` y `npm run build` al arrancar y servirá la nueva versión. No hace falta `docker build` ni reconstruir la imagen.
