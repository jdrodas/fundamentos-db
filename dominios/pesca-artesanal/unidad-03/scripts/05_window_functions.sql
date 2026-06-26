-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 3: SQL avanzado
-- Archivo: 05_window_functions.sql
-- Propósito: Ejemplos de referencia de funciones de ventana para ranking,
--            numeración de filas y cálculos acumulativos sobre el dominio.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECCIÓN 1: Ranking con RANK() y DENSE_RANK()
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT  nombre,
--         cantidad,
--         RANK()       OVER (ORDER BY cantidad DESC) AS ranking,
--         DENSE_RANK() OVER (ORDER BY cantidad DESC) AS ranking_denso
-- FROM    tabla_b;


-- -----------------------------------------------------------------------------
-- SECCIÓN 2: Numeración de filas con ROW_NUMBER()
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT  ROW_NUMBER() OVER (PARTITION BY tabla_a_id ORDER BY registrado_en) AS nro,
--         tabla_a_id,
--         cantidad,
--         registrado_en
-- FROM    tabla_b;


-- -----------------------------------------------------------------------------
-- SECCIÓN 3: Acumulados con SUM() OVER
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT  registrado_en,
--         cantidad,
--         SUM(cantidad) OVER (ORDER BY registrado_en) AS acumulado
-- FROM    tabla_b
-- ORDER BY registrado_en;
