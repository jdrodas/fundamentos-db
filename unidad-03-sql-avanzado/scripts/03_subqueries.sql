-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 3: SQL avanzado
-- Archivo: 03_subqueries.sql
-- Propósito: Ejemplos de referencia de subconsultas simples y correlacionadas
--            aplicadas al dominio de la cohorte.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECCIÓN 1: Subconsulta en WHERE
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   tabla_a
-- WHERE  id IN (SELECT tabla_a_id FROM tabla_b WHERE ...);


-- -----------------------------------------------------------------------------
-- SECCIÓN 2: Subconsulta en FROM
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM  (SELECT ..., COUNT(*) AS total FROM tabla_b GROUP BY ...) sub
-- WHERE  sub.total > 1;


-- -----------------------------------------------------------------------------
-- SECCIÓN 3: Subconsulta correlacionada
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT a.*
-- FROM   tabla_a a
-- WHERE  EXISTS (
--            SELECT 1
--            FROM   tabla_b b
--            WHERE  b.tabla_a_id = a.id
--              AND  b.cantidad   > 100
--        );
