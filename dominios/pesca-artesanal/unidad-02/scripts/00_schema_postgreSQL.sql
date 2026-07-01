-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 2 — SQL básico y operaciones de manipulación de datos
-- Archivo: 00_schema_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- Haber ejecutado exitosamente los scripts de la Unidad 1.

-- Propósito:
-- Este script extiende el esquema existente agregando tres tablas nuevas:
--      - metodos_pesca     catálogo de artes de pesca
--      - pescadores        actores que realizan capturas
--      - capturas          tabla de hechos central del dominio
-- Creación de indices de soporte para las consultas más frecuentes

-- =============================================================================


-- -----------------------------------------------------------------------------
-- Creación de tablas nuevas en el modelo de datos
-- -----------------------------------------------------------------------------

-- 1. metodos_pesca
create table metodos_pesca (
    id                          serial constraint metodos_pesca_pk primary key,
    nombre                      varchar(100)  not null,
    constraint metodo_pesca_nombre_uk unique (nombre)
);

comment on table  metodos_pesca                 is 'Catálogo de métodos o artes de pesca utilizados en la actividad artesanal.';
comment on column metodos_pesca.id              is 'Identificador del método de pesca.';
comment on column metodos_pesca.nombre          is 'Nombre del método de pesca.';


-- 2. pescadores
create table pescadores (
    id                          serial constraint pescadores_pk primary key,
    municipio_id                integer not null constraint pescador_municipio_fk references municipios
);

comment on table  pescadores                    is 'Pescadores artesanales registrados en el dominio.';
comment on column pescadores.id                 is 'Identificador del pescador.';
comment on column pescadores.municipio_id       is 'Municipio donde opera habitualmente el pescador.';

-- 3. capturas
create table capturas (
    id                          serial constraint capturas_pk primary key,
    pescador_id                 integer not null constraint captura_pescador_fk references pescadores,
    municipio_id                integer not null constraint captura_municipio_fk references municipios,
    especie_id                  integer not null constraint captura_especie_fk references especies,
    metodo_id                   integer not null constraint captura_metodo_fk references metodos_pesca,
    cantidad_kg                 numeric(8,2)    not null,
    fecha_hora                  timestamp       not null,
    observaciones               varchar(500),

    constraint captura_cantidad_kg_ck check (cantidad_kg > 0)
);

comment on table  capturas               is 'Tabla de hechos central. Registra cada evento de captura artesanal.';
comment on column capturas.id            is 'Identificador de la captura.';
comment on column capturas.pescador_id   is 'Pescador que realizó la captura.';
comment on column capturas.municipio_id  is 'Municipio donde ocurrió el evento de captura.';
comment on column capturas.especie_id    is 'Especie capturada.';
comment on column capturas.metodo_id     is 'Método de pesca utilizado.';
comment on column capturas.cantidad_kg   is 'Cantidad capturada en kilogramos. Debe ser mayor que cero.';
comment on column capturas.fecha_hora    is 'Fecha y hora del evento de captura.';
comment on column capturas.observaciones is 'Notas opcionales sobre la captura.';

-- -----------------------------------------------------------------------------
-- Índices de soporte para consultas frecuentes
-- -----------------------------------------------------------------------------

create index captura_especie_ix     on capturas (especie_id);
create index captura_municipio_ix   on capturas (municipio_id);
create index captura_pescador_ix    on capturas (pescador_id);
create index captura_fecha_hora_ix  on capturas (fecha_hora);
create index captura_metodo_ix      on capturas (metodo_id);


-- -----------------------------------------------------------------------------
-- Zona de peligro
-- Se borran los objetos en el orden inverso que fueron creados
-- -----------------------------------------------------------------------------

drop table capturas;
drop table pescadores;
drop table metodos_pesca;