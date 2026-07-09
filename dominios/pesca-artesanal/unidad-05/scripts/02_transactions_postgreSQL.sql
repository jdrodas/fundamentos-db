-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 5: Transacciones, concurrencia y pruebas
-- Archivo: 02_transactions_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Este script debe ejecutarse en modo transaccional manual.
-- Valide el modo utilizado en su IDE al ejecutar las transacciones.

-- Prerequisito: 
-- Haber ejecutado todos los scripts de las Unidades 1, 2, 3 y 4.
-- Haber ejecutado el script 00_schema_postgreSQL.sql y 01_seed_postgreSQL.sql de la unidad 5.

-- Propósito:
-- Este script evoluciona el procedimiento p_registra_captura (definido originalmente en
-- Unidad 4, script 03_stored_procedures_postgreSQL.sql) agregando 
-- la validación y el descuento de cuota. No se crea un procedimiento 
-- nuevo: se modifica el existente, siguiendo el mismo principio de 
-- evolución aplicado al modelo estructural a lo largo del curso. 
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Actualización del procedimiento p_registra_captura

-- Validaciones, en orden:
--   1. La faena existe (igual que en Unidad 4).
--   2. El pescador participa en esa faena (igual que en Unidad 4).
--   3. La especie no está en veda (igual que en Unidad 4). Se valida
--      ANTES que la cuota deliberadamente: si una especie está vedada,
--      no tiene sentido evaluar su cuota disponible. El caso de mero
--      guasa (vedado a nivel nacional y con cuota nacional simultánea,
--      sembrado en 01_seed.sql) permite comprobar este orden.
--   4. La cantidad no supera la capacidad de carga disponible de la
--      embarcación (igual que en Unidad 4).
--   5. NUEVO: si existe una cuota vigente para la especie/cuenca/fecha,
--      la cantidad no debe superar kg_restante. La fila de la cuota se
--      bloquea con SELECT ... FOR UPDATE durante toda la transacción,
--      impidiendo que otra sesión concurrente lea el mismo kg_restante
--      antes de que esta transacción confirme su descuento.
--
-- Si existen simultáneamente una cuota nacional y una cuota específica
-- de la cuenca para la misma especie y fecha, se aplica la cuota
-- específica de cuenca (ORDER BY cuenca_id NULLS LAST prioriza el valor
-- no nulo). Este caso no ocurre en los datos de prueba de este curso,
-- pero la regla queda definida explícitamente por si se extiende el seed.
--
-- Tras el INSERT exitoso, si se encontró una cuota aplicable, se
-- descuenta kg_restante en la misma transacción. Si cualquier paso
-- posterior a la validación falla, todo el bloque —incluida la
-- inserción de la captura— se revierte, preservando atomicidad.

-- -----------------------------------------------------------------------------

create or replace procedure p_registra_captura(
    in  p_faena_id      integer,
    in  p_pescador_id   integer,
    in  p_especie_id    integer,
    in  p_metodo_id     integer,
    in  p_cantidad_kg   numeric,
    in  p_fecha_hora    timestamp,
    in  p_observaciones varchar,
    out p_captura_id    integer,
    out p_mensaje       varchar
)
language plpgsql
as $$
declare
    v_cuenca_id             integer;
    v_pescador_pertenece    boolean;
    v_capacidad_disponible  numeric;
    v_cuota_id              integer;
    v_kg_restante_cuota     numeric;
begin
    p_captura_id := null;
    p_mensaje    := null;

    -- validación 1: la faena existe. se obtiene de paso la cuenca de su
    -- municipio de zarpe.
    select m.cuenca_id
    into   v_cuenca_id
    from   faenas f
    join   municipios m on m.id = f.municipio_id
    where  f.id = p_faena_id;

    if v_cuenca_id is null then
        raise exception 'la faena % no existe.', p_faena_id;
    end if;

    -- validación 2: el pescador participa en esta faena.
    select exists (
        select 1 from faenas_pescadores
        where faena_id = p_faena_id and pescador_id = p_pescador_id
    )
    into v_pescador_pertenece;

    if not v_pescador_pertenece then
        raise exception
            'El pescador % no participa en la faena %. Regístrelo primero con registrar_participante_faena.',
            p_pescador_id, p_faena_id;
    end if;

    -- validación 3: la especie no está en veda. se evalúa antes que la
    -- cuota a propósito: una especie vedada se rechaza sin necesidad de
    -- revisar su disponibilidad de cuota.
    if f_esta_en_veda(p_especie_id, v_cuenca_id, p_fecha_hora::date) then
        raise exception
            'La especie % está en veda en la cuenca de la faena % durante la fecha %.',
            p_especie_id, p_faena_id, p_fecha_hora::date;
    end if;

    -- validación 4: la cantidad no supera la capacidad de carga disponible.
    v_capacidad_disponible := f_calcula_capacidad_disponible(p_faena_id);

    if p_cantidad_kg > v_capacidad_disponible then
        raise exception
            'La captura de % kg supera la capacidad disponible (% kg) de la embarcación para la faena %.',
            p_cantidad_kg, v_capacidad_disponible, p_faena_id;
    end if;

    -- validación 5 (nueva en unidad 5): cuota disponible, si aplica.
    -- select ... for update bloquea la fila encontrada hasta que esta
    -- transacción termine (commit o rollback), evitando que una segunda
    -- sesión concurrente lea el mismo kg_restante mientras esta
    -- transacción todavía no ha confirmado su descuento.
    select id, kg_restante
    into   v_cuota_id, v_kg_restante_cuota
    from   cuotas_especies
    where  especie_id = p_especie_id
      and  (cuenca_id is null or cuenca_id = v_cuenca_id)
      and  p_fecha_hora::date between periodo_inicio and periodo_fin
    order by cuenca_id nulls last
    limit 1
    for update;

    -- si no hay ninguna cuota que coincida, la especie no está regulada
    -- por cuota en esa cuenca y fecha: no se aplica ninguna restricción
    -- adicional y el flujo continúa directamente al insert.
    if v_cuota_id is not null then
        if p_cantidad_kg > v_kg_restante_cuota then
            raise exception
                'La captura de % kg supera la cuota disponible (% kg) para la especie % en el período vigente.',
                p_cantidad_kg, v_kg_restante_cuota, p_especie_id;
        end if;
    end if;

    -- todas las validaciones pasaron: se registra la captura.
    insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora, observaciones)
    values (p_faena_id, p_pescador_id, p_especie_id, p_metodo_id, p_cantidad_kg, p_fecha_hora, p_observaciones)
    returning id into p_captura_id;

    -- si se encontró una cuota aplicable, se descuenta en la misma
    -- transacción que el insert. si este update fallara por cualquier
    -- razón (por ejemplo, la restricción check kg_restante >= 0), todo
    -- el bloque se revierte, incluida la captura recién insertada.
    if v_cuota_id is not null then
        update cuotas_especies
        set    kg_restante = kg_restante - p_cantidad_kg
        where  id    = v_cuota_id;

        p_mensaje := 'Captura registrada correctamente con id ' || p_captura_id ||
                     '. Cuota descontada: ' || p_cantidad_kg || ' kg.';
    else
        p_mensaje := 'Captura registrada correctamente con id ' || p_captura_id ||
                     '. No aplica ninguna cuota para esta especie/cuenca/fecha.';
    end if;

exception
    when others then
        p_captura_id := null;
        p_mensaje    := 'Error al registrar la captura: ' || SQLERRM;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Transacción explícita: escenario de éxito con COMMIT

-- Se usa Jurel en cuenca Caribe (faena CART-001, Cartagena), especie sin
-- ninguna veda vigente y con cuota sembrada en 01_seed.sql:
-- kg_autorizado = 12.00, kg_restante inicial = 12.00.
--
-- Se registra una captura de 3.00 kg. Estado esperado tras el COMMIT:
-- kg_restante = 12.00 - 3.00 = 9.00.

do $$
declare
    v_faena_id    integer;
    v_pescador_id integer;
    v_especie_id  integer;
    v_metodo_id   integer;
    v_captura_id  integer;
    v_mensaje     varchar;
begin
    select f.id into v_faena_id
    from faenas f join embarcaciones e on e.id = f.embarcacion_id
    where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-08 05:00:00';

    SELECT fp.pescador_id INTO v_pescador_id
    FROM faenas_pescadores fp
    WHERE fp.faena_id = v_faena_id
    LIMIT 1;

    select id into v_especie_id from especies where nombre_comun = 'Jurel';
    select id  into v_metodo_id  from metodos_pesca where nombre = 'Atarraya';

    call p_registra_captura(
        v_faena_id, v_pescador_id, v_especie_id, v_metodo_id,
        3.00, '2026-04-08 09:00:00', 'Escenario de éxito con cuota',
        v_captura_id, v_mensaje
    );

    raise notice 'Resultado de la transacción: captura_id: %, mensaje: %', v_captura_id, v_mensaje;
end;
$$;


-- Verificación: kg_restante de Jurel/Caribe debe ser 9.00 (12.00 - 3.00)
select kg_autorizado, kg_restante from cuotas_especies cq
join especies e on e.id = cq.especie_id
join cuencas  c on c.id  = cq.cuenca_id
where e.nombre_comun = 'Jurel' and c.nombre = 'Caribe';


--  ****************************
--  Aqui   voy actualizando
--  ****************************



-- =============================================================================
-- 3. Transacción explícita: fallo por cuota insuficiente
--
-- Continuando desde el estado dejado por la Sección B (kg_restante = 9.00
-- en Jurel/Caribe), se intenta registrar una captura de 15.00 kg, que
-- supera lo disponible. Debe ser rechazada.
--
-- RAISE EXCEPTION dentro del procedimiento es capturado por su propio
-- bloque EXCEPTION WHEN OTHERS (heredado de Unidad 4), por lo que la
-- transacción exterior no aborta: el procedimiento retorna un mensaje
-- de error controlado en lugar de una excepción no manejada.
-- -----------------------------------------------------------------------------

do $$
declare
    v_faena_id    integer;
    v_pescador_id integer;
    v_especie_id  integer;
    v_metodo_id   integer;
    v_captura_id  integer;
    v_mensaje     varchar;
begin
    select f.faena_id into v_faena_id
    from faena f join embarcacion e on e.embarcacion_id = f.embarcacion_id
    where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-08 05:00:00';

    select fp.pescador_id into v_pescador_id
    from faena_pescador fp
    where fp.faena_id = v_faena_id
    limit 1;

    select especie_id into v_especie_id from especie where nombre_comun = 'Jurel';
    select metodo_id  into v_metodo_id  from metodo_pesca where nombre = 'Atarraya';

    call registrar_captura(
        v_faena_id, v_pescador_id, v_especie_id, v_metodo_id,
        15.00, '2026-04-08 09:30:00', 'Debe fallar: kg_restante disponible es 9.00 tras la Sección B (Sección C)',
        v_captura_id, v_mensaje
    );

    raise notice 'Resultado de la transacción: captura_id: %, mensaje: %', v_captura_id, v_mensaje;
end;
$$;


-- Verificación: kg_restante de Jurel/Caribe debe seguir en 9.00, sin
-- cambios, porque la validación rechazó la captura antes del INSERT
-- y del UPDATE.
select kg_autorizado, kg_restante from cuotas_especies cq
join especies e on e.id = cq.especie_id
join cuencas  c on c.id  = cq.cuenca_id
where e.nombre_comun = 'Jurel' and c.nombre = 'Caribe';


-- =============================================================================
-- 4. Transacción explícita: ROLLBACK deliberado
--
-- Continuando desde el estado dejado por la Sección C (kg_restante = 9.00,
-- sin cambios), esta sección registra una captura válida de 4.00 kg —el
-- procedimiento la reporta como exitosa y descuenta la cuota dentro de
-- la transacción— pero la transacción exterior se revierte explícitamente
-- con ROLLBACK antes de confirmar.
--
-- El propósito es demostrar que ROLLBACK deshace tanto el INSERT en
-- captura como el UPDATE en cuota_especie, aunque el procedimiento haya
-- reportado éxito: el mensaje de éxito describe el resultado dentro de
-- la transacción en curso, no una garantía de persistencia final. Esa
-- garantía solo la da COMMIT.
--
-- Estado esperado tras el ROLLBACK: kg_restante permanece en 9.00,
-- exactamente igual que antes de esta sección.
-- -----------------------------------------------------------------------------

begin;

do $$
declare
    v_faena_id    integer;
    v_pescador_id integer;
    v_especie_id  integer;
    v_metodo_id   integer;
    v_captura_id  integer;
    v_mensaje     varchar;
begin
    select f.faena_id into v_faena_id
    from faena f join embarcacion e on e.embarcacion_id = f.embarcacion_id
    where e.matricula = 'cart-001' and f.fecha_salida = '2026-04-08 05:00:00';

    select fp.pescador_id into v_pescador_id
    from faena_pescador fp
    where fp.faena_id = v_faena_id
    limit 1;

    select especie_id into v_especie_id from especie where nombre_comun = 'Jurel';
    select metodo_id  into v_metodo_id  from metodo_pesca where nombre = 'Atarraya';

    call registrar_captura(
        v_faena_id, v_pescador_id, v_especie_id, v_metodo_id,
        4.00, '2026-04-08 10:00:00', 'Captura válida que será revertida con rollback - unidad 5',
        v_captura_id, v_mensaje
    );

    raise notice 'Unidad 5 (antes de rollback) — captura_id: %, mensaje: %', v_captura_id, v_mensaje;
end;
$$;

rollback;

-- Verificación: kg_restante de Jurel/Caribe debe seguir en 9.00 (el
-- mismo valor que antes de esta sección), porque ROLLBACK deshizo por
-- completo la transacción, incluido el descuento de 4.00 kg que el
-- procedimiento había reportado como exitoso.
select kg_autorizado, kg_restante from cuotas_especies cq
join especies e on e.id = cq.especie_id
join cuencas  c on c.id  = cq.cuenca_id
where e.nombre_comun = 'Jurel' and c.nombre = 'Caribe';

-- Verificación adicional: la captura de la Sección D NO debe existir,
-- porque el ROLLBACK también deshizo el INSERT en captura.
select count(*) from captura where observaciones like '%Unidad 5%';
--resultado esperado: 0