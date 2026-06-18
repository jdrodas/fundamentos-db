-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 5: Transacciones, concurrencia y pruebas
-- Archivo: 02_transactions.sql
-- Propósito: Implementación de transacciones que garantizan las propiedades
--            ACID ante escenarios de éxito y fallo del dominio trabajado.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- INSTRUCCIONES PARA COMPLETAR ESTE ARCHIVO
-- -----------------------------------------------------------------------------
-- Para cada transacción incluye:
--   1. Comentario con el escenario de negocio que representa.
--   2. La propiedad ACID que queda evidenciada.
--   3. La versión de éxito (con COMMIT) y la versión de fallo (con ROLLBACK).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- ESCENARIO 1: Transacción exitosa
-- Propiedad evidenciada: Atomicidad y Consistencia
-- -----------------------------------------------------------------------------
-- BEGIN;
--     UPDATE cuenta SET saldo = saldo - 100 WHERE id = 1;
--     UPDATE cuenta SET saldo = saldo + 100 WHERE id = 2;
-- COMMIT;


-- -----------------------------------------------------------------------------
-- ESCENARIO 2: Transacción con error y ROLLBACK
-- Propiedad evidenciada: Atomicidad (todo o nada)
-- -----------------------------------------------------------------------------
-- BEGIN;
--     UPDATE cuenta SET saldo = saldo - 500 WHERE id = 3; -- saldo insuficiente
-- ROLLBACK;


-- -----------------------------------------------------------------------------
-- ESCENARIO 3: Manejo de errores con bloque de excepción
-- -----------------------------------------------------------------------------
-- DO $$
-- BEGIN
--     UPDATE cuenta SET saldo = saldo - 2000 WHERE id = 3;
-- EXCEPTION
--     WHEN check_violation THEN
--         RAISE NOTICE 'Saldo insuficiente. Transacción revertida.';
-- END;
-- $$;
