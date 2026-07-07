-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 4 — Lógica almacenada
-- Archivo: 02_functions_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql y 01_seed_postgreSQL.sql de la unidad 4 antes de este script.
-- ejecutar todos los scripts de las unidades 1, 2 y 3.

-- Propósito:
-- Este script crea funciones escalares y funciones de tabla

--   Una función escalar retorna un único valor (un booleano, un número,
--   un texto) y se usa dentro de expresiones SQL como si fuera una columna
--   calculada. 

--   Una función de tabla retorna un conjunto de filas y se usa
--   en la cláusula FROM como si fuera una tabla. A diferencia de una vista
--   (Unidad 3), una función de tabla acepta parámetros que modifican su
--   resultado en cada invocación.

-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1.  Funciones escalares
-- -----------------------------------------------------------------------------

-- 1.1. f_esta_en_veda
--
-- Determina si una especie está vedada en una cuenca en una fecha dada.
--
-- Parámetros:
--   p_especie_id  especie a verificar
--   p_cuenca_id   cuenca donde ocurriría la captura
--   p_fecha       fecha de la captura a validar
--
-- Retorna: TRUE si existe una veda vigente para esa especie en esa fecha,
-- ya sea de alcance nacional (veda.cuenca_id IS NULL) o específica de la
-- cuenca indicada. FALSE en caso contrario.
--
-- Lógica: una veda aplica si p_fecha cae dentro de [fecha_inicio, fecha_fin]
-- Y (la veda es nacional O la veda es de la misma cuenca que p_cuenca_id).
-- -----------------------------------------------------------------------------

create or replace function f_esta_en_veda(
    p_especie_id integer,
    p_cuenca_id  integer,
    p_fecha      date
)
returns boolean
language plpgsql
as $$
declare
    v_existe_veda boolean;
begin
    select exists (
        select 1
        from   vedas v
        where  v.especie_id  = p_especie_id
          and  p_fecha between v.fecha_inicio and v.fecha_fin
          and  (v.cuenca_id is null or v.cuenca_id = p_cuenca_id)
    )
    into v_existe_veda;

    return v_existe_veda;
end;
$$;


-- -----------------------------------------------------------------------------
-- 1.2. f_calcula_capacidad_disponible
--
-- Calcula cuántos kg de capacidad de carga le quedan disponibles a una
-- faena antes de alcanzar el límite de su embarcación.
--
-- Parámetros:
--   p_faena_id  faena a evaluar
--
-- Retorna: capacidad_carga_kg de la embarcación menos la suma de
-- cantidad_kg ya registrada en captura para esa faena. Puede ser negativo
-- si, por alguna razón, la faena ya superó su capacidad (lo cual las
-- validaciones de los procedimientos de 03_stored_procedures.sql deberían
-- impedir que ocurra en el flujo normal).
-- -----------------------------------------------------------------------------

create or replace function f_calcula_capacidad_disponible(
    p_faena_id integer
)
returns numeric
language plpgsql
as $$
declare
    v_capacidad_total numeric(8,2);
    v_kg_registrados  numeric(8,2);
begin
    select te.capacidad_carga_kg
    into   v_capacidad_total
    from   faenas f
    join   embarcaciones emb    on emb.id    = f.embarcacion_id
    join   tipos_embarcacion te on te.id = emb.tipo_embarcacion_id
    where  f.id = p_faena_id;

    if v_capacidad_total is null then
        raise exception 'La faena % no existe.', p_faena_id;
    end if;

    select coalesce(sum(c.cantidad_kg), 0)
    into   v_kg_registrados
    from   capturas c
    where  c.faena_id = p_faena_id;

    return v_capacidad_total - v_kg_registrados;
end;
$$;

comment on function f_calcula_capacidad_disponible(integer) is
    'kg de capacidad de carga disponibles en una faena antes de alcanzar el límite de la embarcación.';


-- -----------------------------------------------------------------------------
-- 2. Funciones de tabla
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 2.1. f_capturas_de_faena
--
-- Retorna el detalle de capturas de una faena: quién capturó, qué especie,
-- con qué método y cuánto. Encapsula un JOIN de cuatro tablas que de otro
-- modo se repetiría en cada reporte que necesite este detalle.
--
-- Parámetros:
--   p_faena_id  faena de la cual se quiere el detalle
--
-- Retorna: una fila por cada captura de la faena, con columnas nombradas.
-- -----------------------------------------------------------------------------

create or replace function f_capturas_de_faena(p_faena_id integer)
returns table (
    captura_id     integer,
    pescador_id    integer,
    especie        varchar,
    metodo         varchar,
    cantidad_kg    numeric,
    fecha_hora     timestamp
)
language sql
as $$
    select
        c.id,
        c.pescador_id,
        e.nombre_comun,
        mt.nombre,
        c.cantidad_kg,
        c.fecha_hora
    from capturas c
    join especies      e  on e.id  = c.especie_id
    join metodos_pesca mt on mt.id  = c.metodo_id
    where c.faena_id = p_faena_id
    order by c.fecha_hora;
$$;

comment on function f_capturas_de_faena(integer) is
    'Detalle de capturas de una faena: pescador, especie, método, cantidad y fecha.';
create or replace function f_capturas_de_faena(p_faena_id integer)
returns table (
    captura_id     integer,
    pescador_id    integer,
    especie        varchar,
    metodo         varchar,
    cantidad_kg    numeric,
    fecha_hora     timestamp
)
language sql
as $$
    select
        c.id,
        c.pescador_id,
        e.nombre_comun,
        mt.nombre,
        c.cantidad_kg,
        c.fecha_hora
    from capturas c
    join especies      e  on e.id  = c.especie_id
    join metodos_pesca mt on mt.id  = c.metodo_id
    where c.faena_id = p_faena_id
    order by c.fecha_hora;
$$;

comment on function f_capturas_de_faena(integer) is
    'Detalle de capturas de una faena: pescador, especie, método, cantidad y fecha.';

-- -----------------------------------------------------------------------------
-- 2.2. f_pescadores_disponibles_para_faena
--
-- Retorna los pescadores que aún podrían sumarse a una faena sin exceder
-- la capacidad_personas de su embarcación. Si la faena ya alcanzó su
-- capacidad máxima, retorna un conjunto vacío (ninguna fila).
--
-- Parámetros:
--   p_faena_id  faena a evaluar
--
-- Retorna: pescadores que NO están ya registrados en faenas_pescadores para
-- esta faena, únicamente si todavía hay cupo disponible según la
-- capacidad de la embarcación.
--
-- Esta función tiene lógica de negocio propia, pues decide si retornar filas o un
-- conjunto vacío según una condición calculada, lo que requiere PL/pgSQL
-- con control de flujo en lugar de un SELECT simple en SQL puro.
-- -----------------------------------------------------------------------------

create or replace function f_pescadores_disponibles_para_faena(
    p_faena_id integer
)
returns table (
    pescador_id    integer,
    municipio_base varchar
)
language plpgsql
as $$
declare
    v_capacidad_personas   integer;
    v_pescadores_actuales  integer;
begin
    select te.capacidad_personas
    into   v_capacidad_personas
    from   faenas f
    join   embarcaciones emb     on emb.id     = f.embarcacion_id
    join   tipos_embarcacion te on te.id = emb.tipo_embarcacion_id
    where  f.id = p_faena_id;

    if v_capacidad_personas is null then
        raise exception 'La faena % no existe.', p_faena_id;
    end if;

    select count(*)
    into   v_pescadores_actuales
    from   faenas_pescadores fp
    where  fp.faena_id = p_faena_id;

    -- si la faena ya alcanzó su capacidad máxima, no hay cupo disponible:
    -- se retorna sin producir ninguna fila.
    if v_pescadores_actuales >= v_capacidad_personas then
        return;
    end if;

    -- hay cupo disponible: retornar los pescadores que aún no participan
    -- en esta faena.
    return query
    select p.id, m.nombre
    from   pescadores  p
    join   municipios m on m.id = p.municipio_id
    where  p.id not in (
        select fp.pescador_id
        from   faenas_pescadores fp
        where  fp.faena_id = p_faena_id
    )
    order by p.id;
end;
$$;

comment on function f_pescadores_disponibles_para_faena(integer) is
    'Pescadores que podrían sumarse a una faena sin exceder la capacidad de personas de la embarcación. retorna vacío si la faena ya está al máximo.';

-- -----------------------------------------------------------------------------
-- Consultas de verificación
-- -----------------------------------------------------------------------------


-- Probar f_esta_en_veda con la veda conocida de bocachico en Magdalena (abril 2026)
select f_esta_en_veda(
    (select id from especies where nombre_comun = 'Bocachico'),
    (select id  from cuencas  where nombre = 'Magdalena'),
    '2026-04-15'
);  -- esperado: true

-- Probar f_esta_en_veda con una fecha fuera del período de veda
select f_esta_en_veda(
    (select id from especies where nombre_comun = 'Bocachico'),
    (select id  from cuencas  where nombre = 'Magdalena'),
    '2026-06-01'
);  -- esperado: false

-- Capacidad disponible de una faena real del seed de la Unidad 3
select f_calcula_capacidad_disponible(
    (select f.id from faenas f
     join embarcaciones e on e.id = f.embarcacion_id
     where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-01 05:00:00')
);

-- Detalle de capturas de esa misma faena, usando la función de tabla
select * from f_capturas_de_faena(
    (select f.id from faenas f
     join embarcaciones e on e.id = f.embarcacion_id
     where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-01 05:00:00')
);

-- Pescadores disponibles para sumarse a esa faena
select * from f_pescadores_disponibles_para_faena(
    (select f.id from faenas f
     join embarcaciones e on e.id = f.embarcacion_id
     where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-01 05:00:00')
);
