-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 5: Transacciones, concurrencia y pruebas
-- Archivo: 00_schema_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- Haber ejecutado todos los scripts de las Unidades 1, 2, 3 y 4.

-- Propósito:
-- Este script crea la última tabla del modelo del curso: cuotas_especies.
-- La lógica transaccional (evolución de registrar_captura, pruebas de
-- concurrencia y pruebas unitarias) se define en los scripts siguientes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Creación de tablas nuevas en el modelo de datos
-- -----------------------------------------------------------------------------


-- 1. cuotas_especies
create table cuotas_especies (
    id                          serial constraint cuotas_especies_pk primary key,
    especie_id                  integer not null constraint cuotas_especies_especie_fk references especies,
    cuenca_id                   integer constraint cuotas_especies_cuenca_fk references cuencas,
    periodo_inicio              date not null,
    periodo_fin                 date not null,
    kg_autorizado               numeric(10,2) not null,
    kg_restante                 numeric(10,2) not null,
    constraint cuota_especie_periodo_ck  check (periodo_fin >= periodo_inicio),
    constraint cuota_especie_kg_autorizado_ck check (kg_autorizado > 0),
    constraint cuota_especie_kg_restante_ck check (kg_restante >= 0),
    constraint cuota_especie_restante_no_supera_autorizado_ck check (kg_restante <= kg_autorizado)
);

comment on table  cuotas_especies                   is 'límite de kg autorizados para capturar una especie durante un período, nacional o por cuenca.';
comment on column cuotas_especies.id                is 'identificador de la cuota por especie.';
comment on column cuotas_especies.especie_id        is 'especie sujeta a la cuota.';
comment on column cuotas_especies.cuenca_id         is 'cuenca donde aplica la cuota. null indica cuota de alcance nacional.';
comment on column cuotas_especies.periodo_inicio    is 'fecha de inicio del período de la cuota.';
comment on column cuotas_especies.periodo_fin       is 'fecha de fin del período de la cuota. debe ser mayor o igual a periodo_inicio.';
comment on column cuotas_especies.kg_autorizado     is 'límite total de kg autorizados para el período. valor fijo, no cambia tras la creación.';
comment on column cuotas_especies.kg_restante       is 'kg disponibles antes de alcanzar el límite. se decrementa activamente con cada captura que aplica a esta cuota.';

create index cuota_especie_especie_ix on cuotas_especies (especie_id);
create index cuota_especie_cuenca_ix on cuotas_especies (cuenca_id);
create index cuota_especie_periodo_ix on cuotas_especies (periodo_inicio, periodo_fin);
