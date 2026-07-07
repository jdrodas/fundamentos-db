-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 4 — Lógica almacenada
-- Archivo: 04_triggers_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql, 01_seed_postgreSQL.sql y 02_functions_postgreSQL.sql
-- de la unidad 4 antes de este script.
-- ejecutar todos los scripts de las unidades 1, 2 y 3.

-- Propósito:
-- Este script implementa la auditoría automática de captura mediante dos
-- triggers AFTER, cada uno asociado a su propia función de trigger:
--   - tr_auditoria_captura_insert  →  ft_auditoria_captura_insert
--   - tr_auditoria_captura_update  →  ft_auditoria_captura_update
--
-- Recordatorio de la decisión de diseño (ver DESCRIPCION_MODELO.md):
-- los triggers de esta unidad se reservan exclusivamente para auditoría.
-- La auditoría debe ser automática e inevitable: ocurre sin importar si el
-- cambio llega a través de un procedimiento o mediante un INSERT/UPDATE
-- directo sobre la tabla captura.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. ft_auditoria_captura_insert / tr_auditoria_captura_insert
--
-- Ante cada INSERT en captura, registra un evento de auditoría con
-- operacion = 'INSERT'. cantidad_kg_anterior queda en NULL porque no
-- existía un valor previo.
--
-- NEW es una variable implícita disponible dentro de funciones de trigger
-- en PL/pgSQL: representa la fila que se acaba de insertar. RETURN NEW
-- es obligatorio en un trigger AFTER aunque su valor no se use para
-- modificar la operación (a diferencia de un trigger BEFORE, donde
-- modificar y retornar NEW sí altera la fila que se inserta).
-- -----------------------------------------------------------------------------

create or replace function ft_auditoria_captura_insert()
returns trigger
language plpgsql
as $$
begin
    insert into auditoria_capturas (
        captura_id,
        operacion,
        cantidad_kg_anterior,
        cantidad_kg_nueva,
        usuario_bd)
    values (
        new.id,
        'insert',
        null,
        new.cantidad_kg,
        current_user);

    return new;
end;
$$;

comment on function ft_auditoria_captura_insert() is
    'Función de trigger: registra en auditoria_captura cada inserción sobre captura.';

create trigger tr_auditoria_captura_insert
    after insert on capturas
    for each row
    execute function ft_auditoria_captura_insert();

comment on trigger tr_auditoria_captura_insert on capturas is
    'dispara fn_auditoria_captura_insert después de cada insert en captura.';


-- -----------------------------------------------------------------------------
-- 2. ft_auditoria_captura_update / tr_auditoria_captura_update

-- Ante cada UPDATE en captura, registra un evento de auditoría con
-- operacion = 'UPDATE', capturando tanto el valor anterior como el nuevo
-- de cantidad_kg mediante las variables implícitas OLD (fila antes del
-- cambio) y NEW (fila después del cambio).

-- Se registra el evento únicamente cuando cantidad_kg efectivamente
-- cambió (OLD.cantidad_kg IS DISTINCT FROM NEW.cantidad_kg), para no
-- generar ruido de auditoría en actualizaciones que solo tocan otras
-- columnas como observaciones. IS DISTINCT FROM se usa en lugar de <>
-- porque compara correctamente valores que podrían ser NULL, aunque en
-- este caso cantidad_kg es NOT NULL; se mantiene la práctica seguida
-- por ser la forma correcta y segura de comparar en PL/pgSQL en general.
-- -----------------------------------------------------------------------------

create or replace function ft_auditoria_captura_update()
returns trigger
language plpgsql
as $$
begin
    if old.cantidad_kg is distinct from new.cantidad_kg then
        insert into auditoria_capturas (
            captura_id,
            operacion,
            cantidad_kg_anterior,
            cantidad_kg_nueva,
            usuario_bd)
        values (
            new.id,
            'udpate',
            old.cantidad_kg,
            new.cantidad_kg,
            current_user);
    end if;

    return new;
end;
$$;

comment on function ft_auditoria_captura_update() is
    'Función de trigger: registra en auditoria_captura cada actualización de cantidad_kg sobre captura.';

create or replace trigger tr_auditoria_captura_update
    after update on capturas
    for each row
    execute function ft_auditoria_captura_update();

comment on trigger tr_auditoria_captura_update on capturas is
    'dispara fn_auditoria_captura_update después de cada update en captura.';


-- -----------------------------------------------------------------------------
-- Consultas de verificación
-- -----------------------------------------------------------------------------

-- Estas pruebas confirman que la auditoría ocurre automáticamente, sin
-- importar si el cambio llega por un procedimiento o por
-- una sentencia directa sobre la tabla.
-- =============================================================================

-- Verificar que registrar_captura (Unidad 4, script 03) generó auditoría
-- automáticamente para las capturas insertadas en las pruebas anteriores.
select
    ac.id,
    ac.captura_id,
    ac.operacion,
    ac.cantidad_kg_anterior,
    ac.cantidad_kg_nueva,
    ac.usuario_bd,
    ac.modificado_en
from auditoria_capturas ac
order by ac.modificado_en desc
limit 10;

-- Probar que un UPDATE directo (sin pasar por actualizar_captura)
-- también queda auditado, demostrando que el trigger es inevitable.
do $$
declare
    v_captura_id integer;
begin
    select captura_id into v_captura_id from captura limit 1;
    update captura set cantidad_kg = cantidad_kg + 0.01
    where captura_id = v_captura_id;
    raise notice 'captura_id modificada directamente: %', v_captura_id;
end;
$$;

-- Verificar resultado: 
select *
from auditoria_capturas
order by modificado_en desc
limit 1;

-- Confirmar que un UPDATE que no cambia cantidad_kg (solo observaciones)
-- NO genera un nuevo registro de auditoría, validando el filtro
-- IS DISTINCT FROM de fn_auditoria_captura_update.
do $$
declare
    v_captura_id integer;
    v_total_antes integer;
    v_total_despues integer;
begin
    select id into v_captura_id from capturas limit 1;
    
    select count(*) into v_total_antes from auditoria_capturas;
    
    update capturas set observaciones = 'solo cambio de observación, sin cambio de cantidad'
    where id = v_captura_id;
    
    select count(*) into v_total_despues from auditoria_capturas;
    
    raise notice 'registros de auditoría antes: %, después: %', v_total_antes, v_total_despues;
end;
$$;

