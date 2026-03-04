/* ============================================
   PLANIFICACIÓN 2026 - Script SQL de referencia
   (Para Django se usan migraciones y el comando: python manage.py cargar_planificacion_2026)
============================================ */

-- CREACIÓN DE TABLAS (sintaxis SQL Server / PostgreSQL)

CREATE TABLE ejes (
    id_eje INT PRIMARY KEY,
    nombre_eje VARCHAR(300) NOT NULL
);

CREATE TABLE planes (
    id_plan INT PRIMARY KEY,
    id_eje INT NOT NULL,
    nombre_plan VARCHAR(300) NOT NULL,
    proposito_politica_publica TEXT,
    vision_estrategica TEXT,
    FOREIGN KEY (id_eje) REFERENCES ejes(id_eje)
);

CREATE TABLE programas (
    id_programa VARCHAR(10) PRIMARY KEY,
    id_plan INT NOT NULL,
    nombre_programa VARCHAR(500) NOT NULL,
    FOREIGN KEY (id_plan) REFERENCES planes(id_plan)
);

CREATE TABLE objetivos_estrategicos (
    id_objetivo INT IDENTITY(1,1) PRIMARY KEY,
    id_programa VARCHAR(10) NOT NULL,
    descripcion TEXT NOT NULL,
    FOREIGN KEY (id_programa) REFERENCES programas(id_programa)
);

-- Vincular proyectos a programas
ALTER TABLE proyectos ADD id_programa VARCHAR(10);
ALTER TABLE proyectos 
ADD CONSTRAINT FK_proyecto_programa 
FOREIGN KEY (id_programa) REFERENCES programas(id_programa);
