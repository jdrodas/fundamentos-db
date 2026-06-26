-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 3: SQL avanzado
-- Archivo: 02_joins.sql
-- Propósito: Ejemplos de referencia de cada tipo de JOIN aplicados al dominio
--            de la cohorte, con la pregunta de negocio que cada uno responde.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECCIÓN 1: INNER JOIN
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   tabla_a a
--        INNER JOIN tabla_b b ON a.id = b.tabla_a_id
-- WHERE  ...;


-- -----------------------------------------------------------------------------
-- SECCIÓN 2: LEFT JOIN
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   tabla_a a
--        LEFT JOIN tabla_b b ON a.id = b.tabla_a_id;


-- -----------------------------------------------------------------------------
-- SECCIÓN 3: RIGHT JOIN
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   tabla_a a
--        RIGHT JOIN tabla_b b ON a.id = b.tabla_a_id;


-- -----------------------------------------------------------------------------
-- SECCIÓN 4: FULL JOIN
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   tabla_a a
--        FULL JOIN tabla_b b ON a.id = b.tabla_a_id;


-- -----------------------------------------------------------------------------
-- SECCIÓN 5: JOIN entre más de dos tablas
-- -----------------------------------------------------------------------------
-- Pregunta de negocio: (describir aquí qué información se busca obtener)
-- SELECT ...
-- FROM   tabla_a a
--        INNER JOIN tabla_b b ON a.id = b.tabla_a_id
--        INNER JOIN tabla_c c ON b.id = c.tabla_b_id;
