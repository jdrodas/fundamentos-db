-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 5: Transacciones, concurrencia y pruebas
-- Archivo: 03_isolation_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Este script debe ejecutarse en modo transaccional manual.
-- Valide el modo utilizado en su IDE al ejecutar las transacciones.

-- Prerequisito: 
-- Haber ejecutado todos los scripts de las Unidades 1, 2, 3 y 4.
-- Haber ejecutado el script 00_schema_postgreSQL.sql, 01_seed_postgreSQL.sql
-- y 02_transactions_postgreSQL.sql de la unidad 5.

-- Propósito:
-- observar en vivo la diferencia de comportamiento entre
-- registrar_captura (con SELECT ... FOR UPDATE) y una variante equivalente
-- sin ese bloqueo, cuando dos sesiones intentan descontar la misma cuota
-- de forma simultánea. 
--
-- Cuota usada para ambos escenarios: Sierra / Caribe, kg_autorizado = 100.00,
-- kg_restante = 100.00 (sembrada en 01_seed.sql y no utilizada por ningún
-- otro script de esta unidad, precisamente para mantenerla en un estado
-- conocido y predecible para esta demostración).
--
-- Convención de lectura: cada paso indica en qué SESIÓN (A o B) se ejecuta.
-- Los pasos marcados "◄── PAUSAR AQUÍ" son el punto donde se debe cambiar
-- de terminal sin haber confirmado (COMMIT) todavía la transacción abierta.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PREPARACIÓN — ejecutar una sola vez, en cualquiera de las dos sesiones
-- -----------------------------------------------------------------------------

-- 1. Verificar el estado inicial de la cuota de prueba.
SELECT cuota_id, kg_autorizado, kg_restante
FROM   cuota_especie cq
JOIN   especie e ON e.especie_id = cq.especie_id
JOIN   cuenca  c ON c.cuenca_id  = cq.cuenca_id
WHERE  e.nombre_comun = 'Sierra' AND c.nombre = 'Caribe';
-- Resultado esperado: kg_autorizado = 100.00, kg_restante = 100.00


-- ****************************
-- Aqui voy revisando
-- ****************************








-- 2. Crear una variante de registrar_captura SIN SELECT ... FOR UPDATE,
-- idéntica en todo lo demás, exclusivamente para esta comparación. No
-- reemplaza ni interfiere con registrar_captura (Unidad 5, con bloqueo),
-- que sigue siendo el procedimiento oficial del modelo.
DROP PROCEDURE IF EXISTS registrar_captura_sin_bloqueo(
    integer, integer, integer, integer, numeric, timestamp, varchar
);

CREATE PROCEDURE registrar_captura_sin_bloqueo(
    IN  p_faena_id      integer,
    IN  p_pescador_id   integer,
    IN  p_especie_id    integer,
    IN  p_metodo_id     integer,
    IN  p_cantidad_kg   numeric,
    IN  p_fecha_hora    timestamp,
    IN  p_observaciones varchar,
    OUT p_captura_id    integer,
    OUT p_mensaje       varchar
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cuenca_id             integer;
    v_capacidad_disponible  numeric;
    v_cuota_id              integer;
    v_kg_restante_cuota     numeric;
BEGIN
    p_captura_id := NULL;
    p_mensaje    := NULL;

    SELECT m.cuenca_id INTO v_cuenca_id
    FROM   faena f JOIN municipio m ON m.municipio_id = f.municipio_id
    WHERE  f.faena_id = p_faena_id;

    v_capacidad_disponible := calcular_capacidad_disponible(p_faena_id);
    IF p_cantidad_kg > v_capacidad_disponible THEN
        RAISE EXCEPTION 'Capacidad insuficiente.';
    END IF;

    -- Diferencia clave frente a registrar_captura: esta lectura NO usa
    -- FOR UPDATE. La fila de cuota_especie no queda bloqueada tras esta
    -- lectura; ambas sesiones pueden leer el mismo kg_restante "vigente"
    -- antes de que cualquiera de las dos confirme su descuento.
    SELECT cuota_id, kg_restante
    INTO   v_cuota_id, v_kg_restante_cuota
    FROM   cuota_especie
    WHERE  especie_id = p_especie_id
      AND  (cuenca_id IS NULL OR cuenca_id = v_cuenca_id)
      AND  p_fecha_hora::date BETWEEN periodo_inicio AND periodo_fin
    ORDER BY cuenca_id NULLS LAST
    LIMIT 1;
    -- (sin FOR UPDATE)

    IF v_cuota_id IS NOT NULL AND p_cantidad_kg > v_kg_restante_cuota THEN
        RAISE EXCEPTION 'La captura de % kg supera la cuota disponible (% kg).',
            p_cantidad_kg, v_kg_restante_cuota;
    END IF;

    INSERT INTO captura (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora, observaciones)
    VALUES (p_faena_id, p_pescador_id, p_especie_id, p_metodo_id, p_cantidad_kg, p_fecha_hora, p_observaciones)
    RETURNING captura_id INTO p_captura_id;

    IF v_cuota_id IS NOT NULL THEN
        UPDATE cuota_especie
        SET    kg_restante = kg_restante - p_cantidad_kg
        WHERE  cuota_id    = v_cuota_id;
    END IF;

    p_mensaje := 'Captura registrada (variante sin bloqueo) con id ' || p_captura_id || '.';

EXCEPTION
    WHEN OTHERS THEN
        p_captura_id := NULL;
        p_mensaje    := 'Error: ' || SQLERRM;
END;
$$;

COMMENT ON PROCEDURE registrar_captura_sin_bloqueo(integer, integer, integer, integer, numeric, timestamp, varchar) IS
    'Variante de registrar_captura SIN SELECT FOR UPDATE, exclusiva para la demostración de concurrencia de esta unidad. No usar fuera de este ejercicio.';

-- 3. Identificar la faena y el pescador que se usarán en ambas sesiones
-- (Santa Marta, cuenca Caribe, con participantes ya registrados).
SELECT f.faena_id, fp.pescador_id
FROM   faena f
JOIN   embarcacion e  ON e.embarcacion_id = f.embarcacion_id
JOIN   faena_pescador fp ON fp.faena_id   = f.faena_id
WHERE  e.matricula = 'STA-002' AND f.fecha_salida = '2026-04-09 05:30:00'
LIMIT 1;
-- Anote el faena_id y pescador_id que retorne esta consulta: se usan
-- como <FAENA_ID> y <PESCADOR_ID> en los pasos siguientes.


-- =============================================================================
-- ESCENARIO 1 — SIN SELECT ... FOR UPDATE
-- Usa registrar_captura_sin_bloqueo. Demuestra que ambas sesiones alcanzan
-- a leer el mismo kg_restante antes de que cualquiera confirme.
-- =============================================================================

-- --- SESIÓN A -----------------------------------------------------------
-- Abra una terminal psql y ejecute:

BEGIN;

DO $$
DECLARE
    v_captura_id integer;
    v_mensaje    varchar;
BEGIN
    CALL registrar_captura_sin_bloqueo(
        <FAENA_ID>, <PESCADOR_ID>,
        (SELECT especie_id FROM especie WHERE nombre_comun = 'Sierra'),
        (SELECT metodo_id  FROM metodo_pesca WHERE nombre = 'Chinchorro'),
        60.00, '2026-04-09 09:00:00', 'Sesión A — escenario sin bloqueo',
        v_captura_id, v_mensaje
    );
    RAISE NOTICE 'Sesión A — captura_id: %, mensaje: %', v_captura_id, v_mensaje;
END;
$$;

-- ◄── PAUSAR AQUÍ. NO ejecute COMMIT todavía.
-- La captura de 60 kg ya se procesó dentro de esta transacción (el
-- procedimiento reportó éxito), pero como no hay FOR UPDATE, la fila de
-- cuota_especie NO quedó bloqueada durante la lectura: solo se bloqueará
-- en el momento del UPDATE, que ya ocurrió dentro del procedimiento.
-- Sin embargo, esa fila SÍ queda bloqueada ahora por el UPDATE ya
-- ejecutado, hasta que esta sesión haga COMMIT o ROLLBACK. Continúe con
-- la Sesión B antes de confirmar esta.


-- --- SESIÓN B -----------------------------------------------------------
-- Abra una SEGUNDA terminal psql (mientras la Sesión A sigue pausada
-- sin COMMIT) y ejecute:

BEGIN;

DO $$
DECLARE
    v_captura_id integer;
    v_mensaje    varchar;
BEGIN
    CALL registrar_captura_sin_bloqueo(
        <FAENA_ID>, <PESCADOR_ID>,
        (SELECT especie_id FROM especie WHERE nombre_comun = 'Sierra'),
        (SELECT metodo_id  FROM metodo_pesca WHERE nombre = 'Chinchorro'),
        60.00, '2026-04-09 09:15:00', 'Sesión B — escenario sin bloqueo',
        v_captura_id, v_mensaje
    );
    RAISE NOTICE 'Sesión B — captura_id: %, mensaje: %', v_captura_id, v_mensaje;
END;
$$;

-- OBSERVACIÓN ESPERADA: la Sesión B queda COLGADA (no retorna) en este
-- punto. No es un error; está esperando a que la Sesión A libere el
-- bloqueo que su propio UPDATE (dentro del procedimiento) ya tomó sobre
-- la fila de cuota_especie. Esto confirma lo explicado en
-- MODELO_RELACIONAL.md: PostgreSQL serializa los UPDATE concurrentes
-- sobre la misma fila incluso sin FOR UPDATE explícito.


-- --- SESIÓN A (continuación) ---------------------------------------------
-- Vuelva a la primera terminal y ejecute:

COMMIT;

-- Efecto inmediato: kg_restante queda en 100.00 - 60.00 = 40.00.


-- --- SESIÓN B (continuación) -----------------------------------------------
-- La Sesión B, que estaba bloqueada, se desbloquea automáticamente en
-- cuanto la Sesión A confirma. Observe el mensaje que produce.
--
-- RESULTADO ESPERADO: la Sesión B falla, pero NO con el mensaje de
-- negocio "cuota insuficiente". El procedimiento ya había leído
-- kg_restante = 100.00 ANTES de que la Sesión A confirmara, validó
-- 60 ≤ 100 como admisible, insertó su captura, y solo al intentar el
-- UPDATE (que estaba bloqueado) descubre —tras desbloquearse— que la
-- expresión relativa kg_restante - 60.00 ahora se evalúa sobre el valor
-- ya actualizado por A (40.00), dando 40.00 - 60.00 = -20.00, lo que
-- viola CHECK (kg_restante >= 0). El mensaje de error de la Sesión B
-- debe mostrar una violación de restricción CHECK, no el mensaje
-- personalizado de "cuota disponible".

ROLLBACK;
-- Se revierte la Sesión B para dejar la cuota en un estado conocido
-- antes del Escenario 2. La captura de la Sesión A (60 kg, COMMIT ya
-- confirmado) permanece registrada.

-- Verificación tras el Escenario 1:
-- SELECT kg_autorizado, kg_restante FROM cuota_especie cq
-- JOIN especie e ON e.especie_id = cq.especie_id
-- JOIN cuenca  c ON c.cuenca_id  = cq.cuenca_id
-- WHERE e.nombre_comun = 'Sierra' AND c.nombre = 'Caribe';
-- Resultado esperado: kg_restante = 40.00 (solo el descuento de la Sesión A)


-- =============================================================================
-- ESCENARIO 2 — CON SELECT ... FOR UPDATE
-- Usa registrar_captura (la versión oficial de esta unidad). Demuestra
-- que el bloqueo ocurre en la lectura y el rechazo llega con mensaje de
-- negocio, antes de tocar la tabla captura.
--
-- Estado de partida: kg_restante = 40.00 (dejado por el Escenario 1).
-- =============================================================================

-- --- SESIÓN A -----------------------------------------------------------

BEGIN;

DO $$
DECLARE
    v_captura_id integer;
    v_mensaje    varchar;
BEGIN
    CALL registrar_captura(
        <FAENA_ID>, <PESCADOR_ID>,
        (SELECT especie_id FROM especie WHERE nombre_comun = 'Sierra'),
        (SELECT metodo_id  FROM metodo_pesca WHERE nombre = 'Chinchorro'),
        25.00, '2026-04-09 10:00:00', 'Sesión A — escenario con FOR UPDATE',
        v_captura_id, v_mensaje
    );
    RAISE NOTICE 'Sesión A — captura_id: %, mensaje: %', v_captura_id, v_mensaje;
END;
$$;

-- ◄── PAUSAR AQUÍ. NO ejecute COMMIT todavía.
-- En este punto, la fila de cuota_especie para Sierra/Caribe está
-- bloqueada por el SELECT ... FOR UPDATE ejecutado dentro del
-- procedimiento, desde el momento de la lectura (antes del INSERT).


-- --- SESIÓN B -----------------------------------------------------------
-- En la segunda terminal, con la Sesión A todavía sin COMMIT:

BEGIN;

DO $$
DECLARE
    v_captura_id integer;
    v_mensaje    varchar;
BEGIN
    CALL registrar_captura(
        <FAENA_ID>, <PESCADOR_ID>,
        (SELECT especie_id FROM especie WHERE nombre_comun = 'Sierra'),
        (SELECT metodo_id  FROM metodo_pesca WHERE nombre = 'Chinchorro'),
        20.00, '2026-04-09 10:15:00', 'Sesión B — escenario con FOR UPDATE',
        v_captura_id, v_mensaje
    );
    RAISE NOTICE 'Sesión B — captura_id: %, mensaje: %', v_captura_id, v_mensaje;
END;
$$;

-- OBSERVACIÓN ESPERADA: la Sesión B queda COLGADA en este punto, igual
-- que en el Escenario 1, pero por una razón distinta: aquí el bloqueo
-- ocurre en el SELECT ... FOR UPDATE, antes de cualquier INSERT. En el
-- Escenario 1 el bloqueo ocurría más tarde, en el UPDATE, después de
-- haber ejecutado ya el INSERT.


-- --- SESIÓN A (continuación) ---------------------------------------------

COMMIT;

-- Efecto inmediato: kg_restante queda en 40.00 - 25.00 = 15.00.


-- --- SESIÓN B (continuación) -----------------------------------------------
-- La Sesión B se desbloquea en cuanto A confirma.
--
-- RESULTADO ESPERADO: la Sesión B falla, y esta vez el mensaje SÍ es de
-- negocio: "La captura de 20.00 kg supera la cuota disponible (15.00 kg)
-- para la especie...". El procedimiento relee kg_restante (ya en 15.00)
-- inmediatamente al desbloquearse, evalúa 20.00 > 15.00, y hace
-- RAISE EXCEPTION con el mensaje descriptivo ANTES de intentar el INSERT
-- en captura. A diferencia del Escenario 1, aquí no se llegó a insertar
-- ninguna fila en captura para luego revertirla.

ROLLBACK;
-- Se revierte la Sesión B (aunque ya había fallado internamente y el
-- procedimiento capturó su propia excepción, se hace ROLLBACK explícito
-- de la transacción exterior por prolijidad).

-- Verificación final:
-- SELECT kg_autorizado, kg_restante FROM cuota_especie cq
-- JOIN especie e ON e.especie_id = cq.especie_id
-- JOIN cuenca  c ON c.cuenca_id  = cq.cuenca_id
-- WHERE e.nombre_comun = 'Sierra' AND c.nombre = 'Caribe';
-- Resultado esperado: kg_restante = 15.00


-- =============================================================================
-- Limpieza opcional
--
-- Si desea repetir la demostración completa desde el estado original
-- (kg_restante = 100.00), ejecute lo siguiente en cualquiera de las dos
-- sesiones. Esto NO es parte de la demostración; es solo para reiniciar
-- el estado antes de volver a practicar los dos escenarios.
-- =============================================================================

-- BEGIN;
-- UPDATE cuota_especie SET kg_restante = kg_autorizado
-- WHERE cuota_id = (
--     SELECT cq.cuota_id FROM cuota_especie cq
--     JOIN especie e ON e.especie_id = cq.especie_id
--     JOIN cuenca  c ON c.cuenca_id  = cq.cuenca_id
--     WHERE e.nombre_comun = 'Sierra' AND c.nombre = 'Caribe'
-- );
-- DELETE FROM captura WHERE observaciones LIKE 'Sesión%escenario%';
-- COMMIT;