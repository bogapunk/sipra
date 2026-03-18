# Desplegar SIP-AIF para demo en la web

Guía rápida para subir el sistema a internet de forma **segura** y **versátil** para mostrar la demo.

---

## Opción 1: VPS + Docker (recomendada para demo estable)

**Tiempo:** ~15 minutos | **Costo:** ~4-5 USD/mes | **Sin cold starts**

### Proveedores sugeridos
- **Hetzner** (Cloud): ~4 €/mes, Europa
- **DigitalOcean**: 6 USD/mes
- **Vultr**: 5 USD/mes

### Pasos

1. **Crear un servidor** (Ubuntu 22.04, 1 GB RAM mínimo).

2. **Conectar por SSH:**
   ```bash
   ssh root@tu-ip-servidor
   ```

3. **Instalar Docker:**
   ```bash
   curl -fsSL https://get.docker.com | sh
   ```

4. **Clonar el proyecto** (o subir los archivos):
   ```bash
   git clone https://github.com/tu-usuario/sipra.git
   cd sipra
   ```

5. **Crear archivo `.env` en la raíz:**
   ```env
   SECRET_KEY=genera-una-clave-aleatoria-larga-de-al-menos-50-caracteres
   DEBUG=0
   ALLOWED_HOSTS=tu-dominio.com,www.tu-dominio.com,tu-ip
   ```

   Para generar SECRET_KEY:
   ```bash
   python3 -c "import secrets; print(secrets.token_urlsafe(50))"
   ```

6. **Levantar el sistema** (opción automática):
   ```bash
   chmod +x deploy-demo.sh
   ./deploy-demo.sh
   ```
   O manualmente:
   ```bash
   docker compose up -d --build
   ```

7. **Crear datos iniciales** (si no usaste el script):
   ```bash
   docker compose exec backend python manage.py crear_datos_iniciales
   docker compose exec backend python manage.py resetear_password_admin
   ```

8. **Acceder:** `http://tu-ip-servidor` (puerto 80)

9. **HTTPS (recomendado):** Instalar Caddy o Nginx como reverse proxy con Let's Encrypt.

---

## Opción 2: Render (gratis para demo corta)

**Tiempo:** ~20 minutos | **Costo:** Gratis | **Limitación:** se apaga tras 15 min sin uso (~1 min para despertar)

### Pasos

1. Sube el código a **GitHub**.

2. En [render.com](https://render.com) → **New** → **Blueprint**.

3. Conecta el repositorio y Render detectará `docker-compose.yml`.

4. **Variables de entorno** (en cada servicio):
   - Backend: `SECRET_KEY`, `DEBUG=0`, `ALLOWED_HOSTS=*.onrender.com`
   - Añade **PostgreSQL** como servicio y usa su `DATABASE_URL` en el backend.

5. **Importante:** Render despliega cada servicio por separado. Puede que necesites:
   - Un **Web Service** para el backend (Dockerfile en `./backend`)
   - Otro para el frontend (Dockerfile en `./frontend`)
   - Una base **PostgreSQL** gestionada

6. Configura el frontend para que apunte al backend: variable `VITE_API_URL` con la URL del backend en Render.

---

## Opción 3: Railway

**Tiempo:** ~15 minutos | **Costo:** ~5 USD de crédito gratis/mes

1. [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub**.

2. Añade **PostgreSQL** desde el panel.

3. Crea dos servicios:
   - **Backend:** raíz `./backend`, Dockerfile, variable `DATABASE_URL` desde Postgres.
   - **Frontend:** raíz `./frontend`, Dockerfile.

4. En el frontend, configura la URL del backend si se despliegan por separado.

5. Asigna dominio público a cada servicio.

---

## Checklist de seguridad para la demo

| Item | Acción |
|------|--------|
| **SECRET_KEY** | Usar una clave larga y aleatoria (nunca la por defecto) |
| **DEBUG** | `DEBUG=0` en producción |
| **ALLOWED_HOSTS** | Listar solo tu dominio o IP |
| **Contraseña Postgres** | Cambiar la de `docker-compose.yml` en producción |
| **HTTPS** | Usar certificado (Let's Encrypt) si es posible |
| **Backups** | Hacer backup de la BD antes de demos importantes |

---

## Credenciales por defecto (tras crear datos iniciales)

- **Admin:** admin@admin.com / admin123  
- **Visualizador:** visualizador@test.com / vis123  
- **Carga:** carga@test.com / carga123  

**Importante:** Cambia las contraseñas antes de exponer la demo públicamente.

---

## Comandos útiles

```bash
# Ver logs
docker compose logs -f

# Reiniciar
docker compose restart

# Detener
docker compose down

# Actualizar y redesplegar
git pull
docker compose up -d --build
```
