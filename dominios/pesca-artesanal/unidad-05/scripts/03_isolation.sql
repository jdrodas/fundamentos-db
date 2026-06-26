-- =============================================================================
-- Curso: Bases de Datos Relacionales
-- Docente: Juan Dario Rodas - jdrodas@hotmail.com
-- Unidad 5: Transacciones, concurrencia y pruebas
-- Archivo: 03_isolation.sql
-- Propósito: Ejemplos que ilustran los niveles de aislamiento de PostgreSQL
--            y los problemas de concurrencia que cada uno previene.
-- Motor: PostgreSQL 16+
-- Prerequisito: ejecutar 00_schema.sql y 01_seed.sql antes de este archivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- INSTRUCCIONES PARA COMPLETAR ESTE ARCHIVO
-- -----------------------------------------------------------------------------
-- Documenta al menos dos niveles de aislamiento con:
--   1. El problema de concurrencia que previene.
--   2. El comando para establecer el nivel antes de la transacción.
--   3. Un escenario de dos sesiones simultáneas que muestre el comportamiento.
-- Nota: simula concurrencia con dos conexiones psql en paralelo y documenta
--       los pasos de cada sesión con comentarios numerados.
-- -----------------------------------------------------------------------------

-- Niveles disponibles en PostgreSQL:
--   READ COMMITTED    (predeterminado) — previene lecturas sucias
--   REPEATABLE READ                   — previene lecturas no repetibles
--   SERIALIZABLE                      — previene lecturas fantasma

-- Ejemplo de configuración (reemplazar con escenario real):
-- -- SESIÓN 1
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--     SELECT saldo FROM cuenta WHERE id = 1; -- lectura inicial
--     -- (esperar acción de sesión 2)
--     SELECT saldo FROM cuenta WHERE id = 1; -- mismo resultado garantizado
-- COMMIT;

-- -- SESIÓN 2 (ejecutar mientras sesión 1 está activa)
-- BEGIN;
--     UPDATE cuenta SET saldo = saldo + 500 WHERE id = 1;
-- COMMIT;
