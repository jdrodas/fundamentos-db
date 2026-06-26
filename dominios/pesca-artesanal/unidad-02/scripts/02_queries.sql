-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 2: Fundamentos de SQL y operaciones básicas
-- Archivo: 02_queries.sql
-- Propósito: Consultas de referencia que demuestran el uso de SELECT, WHERE,
--            ORDER BY, LIMIT, GROUP BY, HAVING y funciones agregadas sobre
--            el dominio de la cohorte.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECCIÓN 1: Consultas básicas con SELECT, WHERE y ORDER BY
-- -----------------------------------------------------------------------------

-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   ...
-- WHERE  ...
-- ORDER BY ...;


-- -----------------------------------------------------------------------------
-- SECCIÓN 2: Consultas con funciones agregadas y GROUP BY
-- -----------------------------------------------------------------------------

-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT   ...,
--          COUNT(*) AS total,
--          AVG(...)  AS promedio
-- FROM     ...
-- GROUP BY ...
-- HAVING   ...;


-- -----------------------------------------------------------------------------
-- SECCIÓN 3: Consultas con funciones de fecha y hora (TIMESTAMP)
-- -----------------------------------------------------------------------------

-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...,
--        DATE_PART('year',  registrado_en)  AS anio,
--        DATE_TRUNC('month', registrado_en) AS mes
-- FROM   ...
-- ORDER BY registrado_en DESC;
