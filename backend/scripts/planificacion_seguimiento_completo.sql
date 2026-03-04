/* ============================================
   SCRIPT SQL – PLANIFICACIÓN Y SEGUIMIENTO
   Estructura: Plan → Programa → Objetivo → Proyecto → Indicador
   
   Características:
   ✅ Evitar duplicados (ON CONFLICT / UNIQUE)
   ✅ Integridad relacional (FOREIGN KEY)
   ✅ Seguimiento posterior (indicadores)
   ✅ Compatible PostgreSQL
   
   NOTA: Este script es para PostgreSQL standalone.
   El sistema Django usa estructura similar con:
   - Eje → Plan → Programa → ObjetivoEstrategico → Proyecto → Indicador
   - Modelo Indicador y FK objetivo_estrategico en projects/models.py
============================================ */

-- ============================================
-- 1️⃣ ESTRUCTURA BASE
-- ============================================

-- ÁREAS (con código para referencias)
CREATE TABLE IF NOT EXISTS areas (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    nombre VARCHAR(100)
);

-- PLANES
CREATE TABLE IF NOT EXISTS planes (
    id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL
);

-- PROGRAMAS
CREATE TABLE IF NOT EXISTS programas (
    id SERIAL PRIMARY KEY,
    plan_id INT REFERENCES planes(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    UNIQUE(plan_id, nombre)
);

-- OBJETIVOS ESTRATÉGICOS
CREATE TABLE IF NOT EXISTS objetivos_estrategicos (
    id SERIAL PRIMARY KEY,
    programa_id INT REFERENCES programas(id) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,
    UNIQUE(programa_id, descripcion)
);

-- PROYECTOS
CREATE TABLE IF NOT EXISTS proyectos (
    id SERIAL PRIMARY KEY,
    objetivo_id INT REFERENCES objetivos_estrategicos(id) ON DELETE SET NULL,
    area_id INT REFERENCES areas(id) ON DELETE SET NULL,
    nombre TEXT NOT NULL,
    responsable TEXT,
    UNIQUE(objetivo_id, nombre)
);

-- INDICADORES
CREATE TABLE IF NOT EXISTS indicadores (
    id SERIAL PRIMARY KEY,
    proyecto_id INT REFERENCES proyectos(id) ON DELETE CASCADE,
    descripcion TEXT,
    unidad_medida VARCHAR(50),
    frecuencia VARCHAR(50)
);

-- Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_programas_plan ON programas(plan_id);
CREATE INDEX IF NOT EXISTS idx_objetivos_programa ON objetivos_estrategicos(programa_id);
CREATE INDEX IF NOT EXISTS idx_proyectos_objetivo ON proyectos(objetivo_id);
CREATE INDEX IF NOT EXISTS idx_proyectos_area ON proyectos(area_id);
CREATE INDEX IF NOT EXISTS idx_indicadores_proyecto ON indicadores(proyecto_id);

-- ============================================
-- 2️⃣ CARGA DE ÁREAS
-- ============================================

INSERT INTO areas (codigo, nombre) VALUES
('CYT', 'Ciencia y Tecnología'),
('EC', 'Economía del Conocimiento')
ON CONFLICT (codigo) DO NOTHING;

-- ============================================
-- 3️⃣ CARGA DE PLANES
-- ============================================

INSERT INTO planes (nombre) VALUES
('1. Fortalecimiento de la Economía del Conocimiento'),
('2. Impulso a la Ciencia y Tecnología'),
('3. Transformación Digital y Gobierno Abierto'),
('4. Gestión y Fortalecimiento Institucional'),
('5. Fortalecimiento del Acceso y Desarrollo Cultural'),
('6. Monetización y generación de recursos propios')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================
-- 4️⃣ PROGRAMA 1.2 – Desarrollo de Talento
-- ============================================

-- Programa
INSERT INTO programas (plan_id, nombre)
SELECT p.id, '1.2. Desarrollo de Talento'
FROM planes p
WHERE p.nombre = '1. Fortalecimiento de la Economía del Conocimiento'
ON CONFLICT (plan_id, nombre) DO NOTHING;

-- Objetivo
INSERT INTO objetivos_estrategicos (programa_id, descripcion)
SELECT pr.id, 'Reducir la brecha de talento en tecnologías clave.'
FROM programas pr
JOIN planes p ON pr.plan_id = p.id
WHERE pr.nombre = '1.2. Desarrollo de Talento'
  AND p.nombre = '1. Fortalecimiento de la Economía del Conocimiento'
ON CONFLICT (programa_id, descripcion) DO NOTHING;

-- Proyecto 1: Práctica profesionalizante
INSERT INTO proyectos (objetivo_id, area_id, nombre, responsable)
SELECT o.id, a.id,
       'Práctica profesionalizante / formación situada',
       'CYT'
FROM objetivos_estrategicos o
JOIN programas pr ON o.programa_id = pr.id
JOIN planes p ON pr.plan_id = p.id
CROSS JOIN areas a
WHERE o.descripcion = 'Reducir la brecha de talento en tecnologías clave.'
  AND pr.nombre = '1.2. Desarrollo de Talento'
  AND p.nombre = '1. Fortalecimiento de la Economía del Conocimiento'
  AND a.codigo = 'CYT'
ON CONFLICT (objetivo_id, nombre) DO NOTHING;

INSERT INTO indicadores (proyecto_id, descripcion, unidad_medida, frecuencia)
SELECT pr.id,
       'Cantidad de participantes en programas de incentivo y vinculación',
       'Cantidad',
       'Anual'
FROM proyectos pr
WHERE pr.nombre = 'Práctica profesionalizante / formación situada'
  AND NOT EXISTS (SELECT 1 FROM indicadores i WHERE i.proyecto_id = pr.id AND i.descripcion = 'Cantidad de participantes en programas de incentivo y vinculación');

-- Proyecto 2: Laboratorio IA
INSERT INTO proyectos (objetivo_id, area_id, nombre, responsable)
SELECT o.id, a.id,
       'Laboratorio IA',
       'CYT'
FROM objetivos_estrategicos o
JOIN programas pr ON o.programa_id = pr.id
JOIN planes p ON pr.plan_id = p.id
CROSS JOIN areas a
WHERE o.descripcion = 'Reducir la brecha de talento en tecnologías clave.'
  AND pr.nombre = '1.2. Desarrollo de Talento'
  AND p.nombre = '1. Fortalecimiento de la Economía del Conocimiento'
  AND a.codigo = 'CYT'
ON CONFLICT (objetivo_id, nombre) DO NOTHING;

INSERT INTO indicadores (proyecto_id, descripcion, unidad_medida, frecuencia)
SELECT pr.id,
       'Cantidad de participantes',
       'Cantidad',
       'Anual'
FROM proyectos pr
WHERE pr.nombre = 'Laboratorio IA'
  AND NOT EXISTS (SELECT 1 FROM indicadores i WHERE i.proyecto_id = pr.id AND i.descripcion = 'Cantidad de participantes');

-- Proyecto 3: CISCO Networking Academy
INSERT INTO proyectos (objetivo_id, area_id, nombre, responsable)
SELECT o.id, a.id,
       'CISCO Networking Academy',
       'Horacio Bogarin / Abel Cortez'
FROM objetivos_estrategicos o
JOIN programas pr ON o.programa_id = pr.id
JOIN planes p ON pr.plan_id = p.id
CROSS JOIN areas a
WHERE o.descripcion = 'Reducir la brecha de talento en tecnologías clave.'
  AND pr.nombre = '1.2. Desarrollo de Talento'
  AND p.nombre = '1. Fortalecimiento de la Economía del Conocimiento'
  AND a.codigo = 'EC'
ON CONFLICT (objetivo_id, nombre) DO NOTHING;

INSERT INTO indicadores (proyecto_id, descripcion, unidad_medida, frecuencia)
SELECT pr.id,
       'Cantidad de personas que finalizaron los trayectos',
       'Cantidad',
       'Anual'
FROM proyectos pr
WHERE pr.nombre = 'CISCO Networking Academy'
  AND NOT EXISTS (SELECT 1 FROM indicadores i WHERE i.proyecto_id = pr.id AND i.descripcion = 'Cantidad de personas que finalizaron los trayectos');

-- ============================================
-- 5️⃣ PLAN 2 – Apropiación Social (Ciencia en Foco)
-- ============================================

INSERT INTO programas (plan_id, nombre)
SELECT p.id, '2.1. Apropiación Social de la Ciencia, Tecnología e Innovación'
FROM planes p
WHERE p.nombre = '2. Impulso a la Ciencia y Tecnología'
ON CONFLICT (plan_id, nombre) DO NOTHING;

INSERT INTO objetivos_estrategicos (programa_id, descripcion)
SELECT pr.id, 'Fomentar y despertar las vocaciones científicas'
FROM programas pr
JOIN planes p ON pr.plan_id = p.id
WHERE pr.nombre = '2.1. Apropiación Social de la Ciencia, Tecnología e Innovación'
  AND p.nombre = '2. Impulso a la Ciencia y Tecnología'
ON CONFLICT (programa_id, descripcion) DO NOTHING;

INSERT INTO proyectos (objetivo_id, area_id, nombre, responsable)
SELECT o.id, a.id,
       'Ciencia en foco - Estación experimental',
       'CYT'
FROM objetivos_estrategicos o
JOIN programas pr ON o.programa_id = pr.id
JOIN planes p ON pr.plan_id = p.id
CROSS JOIN areas a
WHERE o.descripcion = 'Fomentar y despertar las vocaciones científicas'
  AND pr.nombre = '2.1. Apropiación Social de la Ciencia, Tecnología e Innovación'
  AND p.nombre = '2. Impulso a la Ciencia y Tecnología'
  AND a.codigo = 'CYT'
ON CONFLICT (objetivo_id, nombre) DO NOTHING;

INSERT INTO indicadores (proyecto_id, descripcion, unidad_medida, frecuencia)
SELECT pr.id,
       'Cantidad de visitas',
       'Cantidad',
       'Semestral'
FROM proyectos pr
WHERE pr.nombre = 'Ciencia en foco - Estación experimental'
  AND NOT EXISTS (SELECT 1 FROM indicadores i WHERE i.proyecto_id = pr.id AND i.descripcion = 'Cantidad de visitas');

-- ============================================
-- 6️⃣ VISTAS ÚTILES PARA REPORTES
-- ============================================

-- Vista: Proyectos con su cadena completa (Plan → Programa → Objetivo)
CREATE OR REPLACE VIEW v_proyectos_planificacion AS
SELECT
    pr.id AS proyecto_id,
    pr.nombre AS proyecto_nombre,
    pr.responsable,
    a.codigo AS area_codigo,
    a.nombre AS area_nombre,
    o.descripcion AS objetivo_descripcion,
    prog.nombre AS programa_nombre,
    p.nombre AS plan_nombre
FROM proyectos pr
LEFT JOIN objetivos_estrategicos o ON pr.objetivo_id = o.id
LEFT JOIN programas prog ON o.programa_id = prog.id
LEFT JOIN planes p ON prog.plan_id = p.id
LEFT JOIN areas a ON pr.area_id = a.id;

-- Vista: Indicadores con contexto del proyecto
CREATE OR REPLACE VIEW v_indicadores_proyecto AS
SELECT
    i.id AS indicador_id,
    i.descripcion AS indicador_descripcion,
    i.unidad_medida,
    i.frecuencia,
    pr.id AS proyecto_id,
    pr.nombre AS proyecto_nombre,
    p.nombre AS plan_nombre,
    prog.nombre AS programa_nombre
FROM indicadores i
JOIN proyectos pr ON i.proyecto_id = pr.id
LEFT JOIN objetivos_estrategicos o ON pr.objetivo_id = o.id
LEFT JOIN programas prog ON o.programa_id = prog.id
LEFT JOIN planes p ON prog.plan_id = p.id;

-- ============================================
-- 📋 MODELO PARA REPLICAR (otros programas)
-- ============================================
/*
-- 1. Insertar programa
INSERT INTO programas (plan_id, nombre)
SELECT p.id, 'X.X. Nombre del Programa'
FROM planes p
WHERE p.nombre = 'N. Nombre del Plan'
ON CONFLICT (plan_id, nombre) DO NOTHING;

-- 2. Insertar objetivo
INSERT INTO objetivos_estrategicos (programa_id, descripcion)
SELECT pr.id, 'Descripción del objetivo.'
FROM programas pr
JOIN planes p ON pr.plan_id = p.id
WHERE pr.nombre = 'X.X. Nombre del Programa'
  AND p.nombre = 'N. Nombre del Plan'
ON CONFLICT (programa_id, descripcion) DO NOTHING;

-- 3. Insertar proyecto
INSERT INTO proyectos (objetivo_id, area_id, nombre, responsable)
SELECT o.id, a.id, 'Nombre del Proyecto', 'Responsable'
FROM objetivos_estrategicos o
JOIN programas pr ON o.programa_id = pr.id
JOIN planes p ON pr.plan_id = p.id
CROSS JOIN areas a
WHERE o.descripcion = 'Descripción del objetivo.'
  AND pr.nombre = 'X.X. Nombre del Programa'
  AND p.nombre = 'N. Nombre del Plan'
  AND a.codigo = 'CYT'  -- o 'EC'
ON CONFLICT (objetivo_id, nombre) DO NOTHING;

-- 4. Insertar indicador
INSERT INTO indicadores (proyecto_id, descripcion, unidad_medida, frecuencia)
SELECT pr.id, 'Descripción del indicador', 'Cantidad', 'Anual'
FROM proyectos pr
WHERE pr.nombre = 'Nombre del Proyecto'
  AND NOT EXISTS (SELECT 1 FROM indicadores i WHERE i.proyecto_id = pr.id AND i.descripcion = 'Descripción del indicador');
*/

-- ============================================
-- 🧠 NOTAS
-- ============================================
-- • Proyectos sin indicador: permitir NULL en indicadores.descripcion
-- • Proyectos en definición: crear con nombre "En definición" o objetivo_id NULL
-- • Unidades de medida comunes: Cantidad, Porcentaje, Índice, Sí/No
-- • Frecuencias: Anual, Semestral, Trimestral, Mensual
