-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 4 — Lógica almacenada
-- Archivo: 03_stored_procedures_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql, 01_seed_postgreSQL.sql y 02_functions_postgreSQL.sql
-- de la unidad 4 antes de este script.
-- ejecutar todos los scripts de las unidades 1, 2 y 3.

-- Propósito:
-- Este script crea procedimientos almacenados que incluyen lógica de negocio
-- como parte de las operaciones CRUD de Inserción, Actualización y borrado.

-- Convención de manejo de errores:
--   Cada procedimiento valida las reglas de negocio con IF ... THEN
--   RAISE EXCEPTION, usando mensajes descriptivos que identifican
--   exactamente qué regla se violó. Un bloque EXCEPTION WHEN OTHERS
--   captura cualquier error (de validación o de la base de datos) y lo
--   traduce a un parámetro de salida p_mensaje, en lugar de dejar que
--   la sesión completa aborte de forma abrupta. Esto permite que quien
--   invoca el procedimiento revise el resultado sin necesidad de manejar
--   excepciones SQL directamente.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. p_registrar_captura
--
-- Orquesta el registro de una nueva captura, validando en orden:
--   1. La faena existe.
--   2. El pescador participa en esa faena (está en faena_pescador).
--   3. La especie no está en veda para la cuenca de la faena en la fecha
--      de la captura (usa esta_en_veda).
--   4. La cantidad no supera la capacidad de carga disponible de la
--      embarcación (usa calcular_capacidad_disponible).
--
-- Parámetros de entrada: los datos de la captura a registrar.
-- Parámetros de salida:
--   p_captura_id  id de la captura creada, o NULL si falló alguna validación
--   p_mensaje     descripción del resultado: éxito o motivo del rechazo
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
begin
    p_captura_id := null;
    p_mensaje    := null;

    -- validación 1: la faena existe. se obtiene de paso la cuenca de su
    -- municipio de zarpe, necesaria para la validación de veda.
    select m.cuenca_id
    into   v_cuenca_id
    from   faenas f
    join   municipios m on m.id = f.municipio_id
    where  f.id = p_faena_id;

    if v_cuenca_id is null then
        raise exception 'La faena % no existe.', p_faena_id;
    end if;

    -- validación 2: el pescador participa en esta faena.
    select exists (
        select 1 from faenas_pescadores
        where faena_id = p_faena_id and pescador_id = p_pescador_id
    )
    into v_pescador_pertenece;

    if not v_pescador_pertenece then
        raise exception
            'el pescador % no participa en la faena %. regístrelo primero con registrar_participante_faena.',
            p_pescador_id, p_faena_id;
    end if;

    -- validación 3: la especie no está en veda en esa cuenca y fecha.
    if f_esta_en_veda(p_especie_id, v_cuenca_id, p_fecha_hora::date) then
        raise exception
            'La especie % está en veda en la cuenca de la faena % durante la fecha %.',
            p_especie_id, p_faena_id, p_fecha_hora::date;
    end if;

    -- validación 4: la cantidad no supera la capacidad de carga disponible.
    v_capacidad_disponible := f_calcula_capacidad_disponible(p_faena_id);

    if p_cantidad_kg > v_capacidad_disponible then
        raise exception
            'la captura de % kg supera la capacidad disponible (% kg) de la embarcación para la faena %.',
            p_cantidad_kg, v_capacidad_disponible, p_faena_id;
    end if;

    -- todas las validaciones pasaron: se registra la captura.
    insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora, observaciones)
    values (p_faena_id, p_pescador_id, p_especie_id, p_metodo_id, p_cantidad_kg, p_fecha_hora, p_observaciones)
    returning id into p_captura_id;

    p_mensaje := 'Captura registrada correctamente con id ' || p_captura_id || '.';

exception
    when others then
        -- captura cualquier error (de validación o de postgresql) y lo
        -- traduce a un resultado controlado en lugar de abortar la sesión.
        p_captura_id := null;
        p_mensaje    := 'Error al registrar la captura: ' || sqlerrm;
end;
$$;

comment on procedure p_registra_captura(integer, integer, integer, integer, numeric, timestamp, varchar) is
    'Orquesta el registro de una captura validando faena, participación del pescador, veda y capacidad de carga.';

-- -----------------------------------------------------------------------------
-- 2. p_actualiza_captura
--
-- Orquesta la corrección de una captura existente. Solo revalida las
-- reglas de negocio afectadas por los campos que efectivamente cambian:
--   - Si cambia cantidad_kg: revalida capacidad de carga disponible,
--     excluyendo el valor anterior de la propia captura del cálculo
--     (de lo contrario se estaría descontando dos veces la misma captura).
--   - Si cambia especie_id: revalida veda para la fecha y cuenca de
--     la captura.
--
-- Parámetros de entrada:
--   p_captura_id       captura a corregir
--   p_cantidad_kg_nueva  nuevo valor de cantidad_kg, o NULL si no cambia
--   p_especie_id_nueva   nuevo valor de especie_id, o NULL si no cambia
-- Parámetro de salida:
--   p_mensaje  descripción del resultado
-- -----------------------------------------------------------------------------

create or replace procedure p_actualiza_captura(
    in  p_captura_id         integer,
    in  p_cantidad_kg_nueva  numeric,
    in  p_especie_id_nueva   integer,
    out p_mensaje            varchar
)
language plpgsql
as $$
declare
    v_faena_id              integer;
    v_cuenca_id             integer;
    v_fecha_hora            timestamp;
    v_cantidad_kg_actual    numeric;
    v_capacidad_disponible  numeric;
begin
    p_mensaje := null;

    -- obtener el estado actual de la captura y el contexto de su faena.
    select c.faena_id, c.cantidad_kg, c.fecha_hora, m.cuenca_id
    into   v_faena_id, v_cantidad_kg_actual, v_fecha_hora, v_cuenca_id
    from   capturas c
    join   faenas     f on f.id     = c.faena_id
    join   municipios m on m.id = f.municipio_id
    where  c.id = p_captura_id;

    if v_faena_id is null then
        raise exception 'la captura % no existe.', p_captura_id;
    end if;

    -- si cambia la cantidad, revalidar capacidad de carga disponible.
    -- calcular_capacidad_disponible ya descuenta todas las capturas de
    -- la faena, incluida esta misma con su valor actual; para evaluar
    -- correctamente el nuevo valor se le suma de vuelta la cantidad
    -- actual antes de comparar, evitando el doble descuento.
    if p_cantidad_kg_nueva is not null then
        v_capacidad_disponible := f_calcula_capacidad_disponible(v_faena_id) + v_cantidad_kg_actual;

        if p_cantidad_kg_nueva > v_capacidad_disponible then
            raise exception
                'La nueva cantidad % kg supera la capacidad disponible (% kg) de la embarcación para la faena %.',
                p_cantidad_kg_nueva, v_capacidad_disponible, v_faena_id;
        end if;
    end if;

    -- si cambia la especie, revalidar veda para la fecha y cuenca actuales.
    if p_especie_id_nueva is not null then
        if f_esta_en_veda(p_especie_id_nueva, v_cuenca_id, v_fecha_hora::date) then
            raise exception
                'La especie % está en veda en la cuenca de la faena % durante la fecha %.',
                p_especie_id_nueva, v_faena_id, v_fecha_hora::date;
        end if;
    end if;

    -- aplicar la actualización solo sobre los campos que efectivamente
    -- recibieron un valor nuevo. coalesce conserva el valor actual
    -- cuando el parámetro correspondiente llega en null.
    update capturas
    set    cantidad_kg = coalesce(p_cantidad_kg_nueva, cantidad_kg),
           especie_id  = coalesce(p_especie_id_nueva, especie_id)
    where  id  = p_captura_id;

    p_mensaje := 'Captura ' || p_captura_id || ' actualizada correctamente.';

exception
    when others then
        p_mensaje := 'Error al actualizar la captura: ' || sqlerrm;
end;
$$;

comment on procedure p_actualiza_captura(integer, numeric, integer) is
    'Orquesta la corrección de una captura, revalidando capacidad de carga y veda solo para los campos que cambian.';


-- -----------------------------------------------------------------------------
-- 3. p_elimina_captura
--
-- Orquesta la eliminación de una captura. Rechaza el borrado si la faena
-- a la que pertenece ya tiene fecha_retorno registrada (faena cerrada),
-- siguiendo la decisión de diseño documentada en DESCRIPCION_MODELO.md:
-- preferir la corrección auditable sobre el borrado físico cuando el
-- dato ya forma parte de un registro cerrado.
--
-- Parámetros de entrada:
--   p_captura_id  captura a eliminar
-- Parámetro de salida:
--   p_mensaje  descripción del resultado
-- -----------------------------------------------------------------------------

create or replace procedure p_elimina_captura(
    in  p_captura_id integer,
    out p_mensaje    varchar
)
language plpgsql
as $$
declare
    v_faena_id      integer;
    v_fecha_retorno timestamp;
begin
    p_mensaje := null;

    select c.faena_id, f.fecha_retorno
    into   v_faena_id, v_fecha_retorno
    from   capturas c
    join   faenas   f on f.id = c.faena_id
    where  c.id = p_captura_id;

    if v_faena_id is null then
        raise exception 'La captura % no existe.', p_captura_id;
    end if;

    if v_fecha_retorno is not null then
        raise exception
            'La captura % pertenece a la faena % que ya está cerrada (fecha_retorno registrada). use actualizar_captura para corregirla en lugar de eliminarla.',
            p_captura_id, v_faena_id;
    end if;

    delete from capturas where id = p_captura_id;

    p_mensaje := 'Captura ' || p_captura_id || ' eliminada correctamente.';

exception
    when others then
        p_mensaje := 'error al eliminar la captura: ' || sqlerrm;
end;
$$;

comment on procedure p_elimina_captura(integer) is
    'orquesta la eliminación de una captura, rechazando el borrado si la faena ya está cerrada.';


-- -----------------------------------------------------------------------------
-- Ejemplos de invocación
--
-- Los procedimientos con parámetros OUT se invocan con CALL, pasando NULL
-- (o cualquier valor, que será ignorado) en la posición de cada parámetro
-- de salida. El resultado se muestra como una fila con los valores OUT.

-- IMPORTANTE: el comando CALL de PostgreSQL no acepta subconsultas
-- (SELECT ...) directamente como argumentos; solo admite constantes,
-- variables o expresiones simples. Por eso cada ejemplo resuelve primero
-- los identificadores necesarios en variables, dentro de un bloque DO,
-- y luego invoca el procedimiento con esas variables. Un bloque DO
-- ejecuta código PL/pgSQL una sola vez sin necesidad de crear una función.

-- -----------------------------------------------------------------------------
 
-- Registrar una captura válida en una faena existente con cupo y sin veda
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

    select fp.pescador_id into v_pescador_id
    from faenas_pescadores fp
    where fp.faena_id = v_faena_id
    limit 1;

    select id into v_especie_id
    from especies where nombre_comun = 'Jurel';

    select id into v_metodo_id
    from metodos_pesca where nombre = 'Atarraya';

    call p_registra_captura(
        v_faena_id, v_pescador_id, v_especie_id, v_metodo_id,
        4.50, '2026-04-08 11:00:00', 'prueba de procedimiento',
        v_captura_id, v_mensaje
    );
    raise notice 'Captura_id: %, mensaje: %', v_captura_id, v_mensaje;
end;
$$;
 
-- Intentar registrar una captura de bocachico en Magdalena durante la veda
-- de abril (debe fallar con mensaje de veda)
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
    from faenas f
        join embarcaciones e on e.id = f.embarcacion_id
    where e.matricula = 'MAG-001'
      and f.fecha_salida = '2026-04-01 05:30:00';

    select fp.pescador_id into v_pescador_id
    from faenas_pescadores fp
    where fp.faena_id = v_faena_id
    limit 1;

    select id into v_especie_id from especies where nombre_comun = 'Bocachico';
    select id into v_metodo_id  from metodos_pesca where nombre = 'Atarraya';

    call p_registra_captura(
        v_faena_id, v_pescador_id, v_especie_id, v_metodo_id,
        4.50, '2026-04-15 11:00:00', 'debe fallar por veda',
        v_captura_id, v_mensaje
    );
    raise notice 'Captura_id: %, mensaje: %', v_captura_id, v_mensaje;
end;
$$;
 
-- Intentar eliminar una captura de una faena ya cerrada (debe fallar)
do $$
declare
    v_captura_id integer;
    v_mensaje    varchar;
begin
    select c.id into v_captura_id
    from capturas c
        join faenas f on f.id = c.faena_id
    where f.fecha_retorno is not null
    limit 1;

    call p_elimina_captura(v_captura_id, v_mensaje);
    raise notice 'mensaje: %', v_mensaje;
end;
$$;
