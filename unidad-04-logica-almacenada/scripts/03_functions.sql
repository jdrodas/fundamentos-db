-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 4: Lógica almacenada
-- Archivo: 03_functions.sql
-- Propósito: Funciones definidas por el usuario (escalares y de tabla)
--            integrables directamente en consultas SQL del dominio.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- INSTRUCCIONES PARA COMPLETAR ESTE ARCHIVO
-- -----------------------------------------------------------------------------
-- Incluye al menos:
--   - Una función escalar: recibe parámetros y retorna un valor único.
--   - Una función de tabla (RETURNS TABLE): retorna un conjunto de filas.
-- Cada función debe incluir comentario con su propósito y ejemplo de uso
-- dentro de una consulta SELECT.
-- -----------------------------------------------------------------------------

-- Ejemplo de función escalar (reemplazar con lógica real):
-- CREATE OR REPLACE FUNCTION calcular_descuento(
--     p_total       NUMERIC,
--     p_porcentaje  NUMERIC
-- )
-- RETURNS NUMERIC LANGUAGE plpgsql AS $$
-- BEGIN
--     RETURN ROUND(p_total * (p_porcentaje / 100.0), 2);
-- END;
-- $$;

-- Uso en consulta:
-- SELECT nombre, total, calcular_descuento(total, 10) AS descuento
-- FROM   pedido;


-- Ejemplo de función de tabla (reemplazar con lógica real):
-- CREATE OR REPLACE FUNCTION pedidos_por_cliente(p_cliente_id INTEGER)
-- RETURNS TABLE (
--     pedido_id  INTEGER,
--     total      NUMERIC,
--     estado     VARCHAR,
--     creado_en  TIMESTAMP
-- )
-- LANGUAGE plpgsql AS $$
-- BEGIN
--     RETURN QUERY
--     SELECT id, total, estado, creado_en
--     FROM   pedido
--     WHERE  cliente_id = p_cliente_id
--     ORDER BY creado_en DESC;
-- END;
-- $$;

-- Uso en consulta:
-- SELECT * FROM pedidos_por_cliente(1);
