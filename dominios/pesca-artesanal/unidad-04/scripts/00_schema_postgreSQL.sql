-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 4 — Lógica almacenada
-- Archivo: 00_schema_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- Haber ejecutado todos los scripts de las Unidades 1, 2 y 3.

-- Propósito:
-- Este script crea dos tablas nuevas:
--   - veda                     períodos de prohibición de captura por especie/cuenca
--   - auditoria_captura        historial automático de cambios sobre captura

-- La lógica programable (funciones, procedimientos, triggers) se define
-- en los scripts siguientes de esta unidad, una vez que estas tablas
-- existen y pueden ser referenciadas.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Creación de tablas nuevas en el modelo de datos
-- -----------------------------------------------------------------------------


-- 1. vedas
create table vedas (
    id                          serial constraint vedas_pk primary key,
    especie_id                  integer not null constraint veda_especie_fk references especies,
    cuenca_id                   integer constraint veda_cuenca_fk references cuencas,
    fecha_inicio                date not null,
    fecha_fin                   date not null,
    descripcion                 varchar(300),
    constraint veda_fechas_ck check (fecha_fin >= fecha_inicio)
);

comment on table  vedas                                     is 'períodos de prohibición de captura por especie, a nivel nacional o por cuenca.';
comment on column vedas.id                                  is 'identificador de la veda';
comment on column vedas.especie_id                          is 'especie sujeta a la veda.';
comment on column vedas.cuenca_id                           is 'cuenca donde aplica la veda. null indica veda de alcance nacional.';
comment on column vedas.fecha_inicio                        is 'fecha de inicio del período de veda.';
comment on column vedas.fecha_fin                           is 'fecha de fin del período de veda. debe ser mayor o igual a fecha_inicio.';
comment on column vedas.descripcion                         is 'motivo o contexto de la veda.';

create index veda_especie_ix on vedas (especie_id);
create index veda_cuenca_ix  on vedas (cuenca_id);
create index veda_fechas_ix  on vedas (fecha_inicio, fecha_fin);


-- 2. auditoria_capturas
create table auditoria_capturas (
    id                          serial constraint auditoria_capturas_pk primary key,
    captura_id                  integer not null constraint auditoria_captura_captura_fk references capturas,
    operacion                   varchar(10) not null,
    cantidad_kg_anterior        numeric(8,2),
    cantidad_kg_nueva           numeric(8,2) not null,
    modificado_en               timestamp not null default now(),
    usuario_bd                  varchar(100) not null
);

comment on table  auditoria_capturas                        is 'historial automático de inserciones y actualizaciones sobre captura.';
comment on column auditoria_capturas.id                     is 'identificador del evento de auditoría';
comment on column auditoria_capturas.captura_id             is 'captura afectada por la operación auditada.';
comment on column auditoria_capturas.operacion              is 'tipo de operación registrada: insert o update.';
comment on column auditoria_capturas.cantidad_kg_anterior   is 'valor de cantidad_kg antes del cambio. null cuando operacion = insert.';
comment on column auditoria_capturas.cantidad_kg_nueva      is 'valor de cantidad_kg después de la operación.';
comment on column auditoria_capturas.modificado_en          is 'fecha y hora en que ocurrió la operación auditada.';
comment on column auditoria_capturas.usuario_bd             is 'usuario de postgresql que ejecutó la operación (current_user).';

create index auditoria_captura_captura_ix on auditoria_capturas (captura_id);
create index auditoria_captura_fecha_ix on auditoria_capturas (modificado_en);
