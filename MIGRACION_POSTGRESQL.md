# Migración de SQLite a PostgreSQL

Esta guía describe cómo migrar SIP-AIF de SQLite a PostgreSQL y qué cambios afectan al sistema.

---

## 1. Ventajas de migrar a PostgreSQL

| Aspecto | SQLite (actual) | PostgreSQL |
|---------|-----------------|------------|
| **Concurrencia** | Limitada (1 escritor por vez) | Múltiples conexiones simultáneas |
| **Errores "database is locked"** | Pueden ocurrir con varios usuarios | No ocurren |
| **Producción** | No recomendado para múltiples usuarios | Recomendado para producción |
| **Escalabilidad** | Limitada | Alta |
| **Backup** | Copia archivo .sqlite3 | pg_dump, replicación |

---

## 2. Cambios que afectan al sistema

### 2.1 Configuración (ya implementada)

El archivo `backend/config/settings.py` **ya soporta PostgreSQL** cuando existe la variable de entorno `DATABASE_URL`:

```python
# Si DATABASE_URL está definida, usa PostgreSQL
# Si no, usa SQLite por defecto
```

### 2.2 Dependencias

- **psycopg2-binary** ya está en `requirements.txt` (driver de PostgreSQL para Django)
- No se requieren cambios adicionales

### 2.3 Módulo Backup/Restore

| Funcionalidad | SQLite | PostgreSQL |
|---------------|--------|------------|
| Backup interno | Copia archivo .sqlite3 | Usa pg_dump (dump SQL) |
| Restore interno | Copia archivo .sqlite3 | Usa psql para cargar dump |
| List backups | Archivos backup_*.sqlite3 | Archivos backup_*.sql |

El módulo `backup_restore` debe actualizarse para soportar PostgreSQL (ver sección 5).

### 2.4 Código de la aplicación

- **Modelos Django**: No requieren cambios (Django ORM abstrae la base de datos)
- **Consultas**: Las consultas estándar funcionan igual
- **Migraciones**: Las mismas migraciones se aplican en PostgreSQL

### 2.5 Inicio del sistema

- **iniciar-sistema.bat**: Actualmente inicia solo backend y frontend. Para PostgreSQL local necesitas instalar y ejecutar PostgreSQL antes.
- **Docker**: Ya usa PostgreSQL (ver `docker-compose.yml`)

---

## 3. Pasos para migrar (desarrollo local)

### Paso 1: Instalar PostgreSQL

**Windows:**
- Descarga: https://www.postgresql.org/download/windows/
- O con Chocolatey: `choco install postgresql`
- Durante la instalación, anota el usuario y contraseña que configures

**Linux:**
```bash
sudo apt install postgresql postgresql-contrib   # Ubuntu/Debian
sudo dnf install postgresql-server               # Fedora
```

### Paso 2: Crear la base de datos

```bash
# Conectar a PostgreSQL (como usuario postgres)
psql -U postgres

# Crear base de datos y usuario
CREATE DATABASE sipra;
CREATE USER sipra WITH PASSWORD 'tu_password_seguro';
ALTER ROLE sipra SET client_encoding TO 'utf8';
ALTER ROLE sipra SET default_transaction_isolation TO 'read committed';
GRANT ALL PRIVILEGES ON DATABASE sipra TO sipra;
\q
```

### Paso 3: Exportar datos desde SQLite

```bash
cd backend
python manage.py dumpdata --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 2 -o datos_migracion.json
```

### Paso 4: Configurar variables de entorno

Copia `.env.example` a `.env` en la raíz del proyecto:

```bash
copy .env.example .env
```

Edita `.env` y configura:

```env
DATABASE_URL=postgres://sipra:tu_password_seguro@localhost:5432/sipra
SECRET_KEY=tu-clave-secreta-segura
DEBUG=1
```

El proyecto carga automáticamente `.env` gracias a python-dotenv.

### Paso 5: Migrar a PostgreSQL

**Opción A - Script automático (Windows):**
```bash
cd backend\scripts
migrar_a_postgresql.bat
```

**Opción B - Manual:**
```bash
cd backend

# Si usas .env, ya se cargará DATABASE_URL automáticamente
# Si no: set DATABASE_URL=postgres://sipra:tu_password@localhost:5432/sipra

# Crear tablas y aplicar migraciones
python manage.py migrate

# Cargar datos exportados
python manage.py loaddata datos_migracion.json
```

### Paso 6: Verificar

```bash
python manage.py runserver 8001
```

Accede a http://localhost:5173 y comprueba que los datos se cargaron correctamente.

---

## 4. Uso con Docker (ya configurado)

```bash
docker-compose up -d
```

El `docker-compose.yml` ya incluye:
- Servicio PostgreSQL (puerto 5432 interno)
- Variable `DATABASE_URL` para el backend
- Volumen persistente para los datos

---

## 5. Actualización del módulo Backup/Restore

Para que el backup funcione con PostgreSQL, el módulo debe usar `pg_dump` en lugar de copiar archivos. Los cambios se documentan en el código del servicio.

---

## 6. Resumen de archivos afectados

| Archivo | Cambio |
|---------|--------|
| `backend/config/settings.py` | Ya soporta PostgreSQL (sin cambios) |
| `backend/requirements.txt` | Ya tiene psycopg2-binary (sin cambios) |
| `backend/backup_restore/services.py` | Requiere soporte para pg_dump |
| `backend/backup_restore/views.py` | Posible ajuste de mensajes de error |
| `.env` | Nuevo archivo con DATABASE_URL |
| `iniciar-sistema.bat` | Opcional: variante para PostgreSQL local |

---

## 7. Volver a SQLite (si es necesario)

1. Elimina o comenta `DATABASE_URL` del entorno
2. Restaura `db.sqlite3` desde un backup si lo tienes
3. O ejecuta migraciones desde cero: `python manage.py migrate`
