# Restauración de datos - SIP-AIF

## Pasos para restaurar los datos del sistema

### 1. Abrir terminal en la carpeta del proyecto

### 2. Ejecutar migraciones (si la base de datos está vacía o fue reiniciada)

```bash
cd backend
python manage.py migrate
```

### 3. Restaurar datos

```bash
python manage.py restaurar_datos
```

Este comando:
- **Reactiva todos los usuarios** que pudieron haber sido desactivados (eliminación lógica)
- **Crea datos iniciales** si no existen:
  - Roles: Administrador, Carga, Visualización
  - Usuarios: admin@admin.com, visualizador@test.com, carga@test.com
  - Áreas: Presidencia, Desarrollo, Infraestructura, Comunicación, Recursos Humanos
  - Proyectos de ejemplo
  - Tareas de ejemplo

### 4. Reiniciar el servidor

**Backend (Django):**
```bash
cd backend
python manage.py runserver 8001
```

**Frontend (Vite):**
```bash
cd frontend
npm run dev
```

### Credenciales de acceso

| Usuario | Email | Contraseña | Rol |
|---------|-------|------------|-----|
| Admin | admin@admin.com | admin123 | Administrador |
| Visualizador | visualizador@test.com | vis123 | Visualización |
| Carga | carga@test.com | carga123 | Carga |

---

**Nota:** Si tenía datos personalizados (usuarios, proyectos, tareas) que no estaban en los datos iniciales, estos solo pueden recuperarse desde una copia de seguridad (backup) del archivo `backend/db.sqlite3`. Se recomienda hacer copias de seguridad periódicas de ese archivo.
