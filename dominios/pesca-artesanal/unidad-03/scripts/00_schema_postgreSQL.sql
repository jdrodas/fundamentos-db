-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3: SQL avanzado
-- Archivo: 00_schema_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- Haber ejecutado todos los scripts de las Unidades 1 y 2.

-- Propósito:
--   1. Refactoriza la tabla captura: retira municipio_id y agrega faena_id.
--      La estrategia usa ALTER TABLE para preservar todos los datos existentes.
--   2. Crea cuatro tablas nuevas:
--      - tipo_embarcacion  catálogo de tipos con capacidades operativas
--      - embarcacion       embarcaciones individuales registradas
--      - faena             viajes de pesca organizados
--      - faena_pescador    participación de pescadores en cada faena (N:M)

-- Importante: 
-- el paso de refactorización es irreversible en el contexto
-- de este script. Ejecutar únicamente sobre una base de datos con los
-- datos de las unidades anteriores correctamente cargados.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Creación de tablas nuevas en el modelo de datos
-- -----------------------------------------------------------------------------

-- 1. tipos_embarcacion
create table tipos_embarcacion (
    id                          serial constraint tipos_embarcacion_pk primary key,
    nombre                      varchar(100)    not null,
    impulsion                   varchar(20)     not null,
    capacidad_personas          integer         not null,
    capacidad_carga_kg          numeric(8,2)    not null,

    constraint tipo_embarcacion_nombre_uk unique (nombre),
    constraint tipo_embarcacion_impulsion_ck check (impulsion in ('motor', 'remo')),
    constraint tipo_embarcacion_capacidad_personas_ck check (capacidad_personas > 0),
    constraint tipo_embarcacion_capacidad_carga_ck check (capacidad_carga_kg > 0)
);

comment on table  tipos_embarcacion                         is 'Catálogo de tipos de embarcación con sus características operativas.';
comment on column tipos_embarcacion.id                      is 'Identificador del tipo de embarcación.';
comment on column tipos_embarcacion.nombre                  is 'Nombre del tipo de embarcación.';
comment on column tipos_embarcacion.impulsion               is 'Forma de impulsión: motor o remo.';
comment on column tipos_embarcacion.capacidad_personas      is 'Número máximo de personas a bordo.';
comment on column tipos_embarcacion.capacidad_carga_kg      is 'Capacidad máxima de carga en kilogramos.';


-- 2. embarcaciones
create table embarcaciones (
    id                          serial constraint embarcaciones_pk primary key,
    matricula                   varchar(50)   not null,
    tipo_embarcacion_id         integer not null constraint embarcacion_tipo_fk references tipos_embarcacion,
    municipio_id                integer not null constraint embarcacion_municipio_fk references municipios,
    constraint embarcacion_matricula_uk unique (matricula)
);

comment on table  embarcaciones                             is 'Embarcaciones individuales registradas en el dominio pesquero.';
comment on column embarcaciones.id                          is 'Identificador de la embarcación';
comment on column embarcaciones.matricula                   is 'Matrícula oficial de la embarcación.';
comment on column embarcaciones.tipo_embarcacion_id         is 'Tipo de embarcación con sus características operativas.';
comment on column embarcaciones.municipio_id                is 'Municipio donde opera habitualmente la embarcación (puerto base).';


-- 3. faenas
create table faenas (
    id                          serial constraint faenas_pk primary key,
    embarcacion_id              integer not null constraint faena_embarcacion_fk references embarcaciones,
    municipio_id                integer not null constraint faena_municipio_fk references municipios,
    fecha_salida                timestamp   not null,
    fecha_retorno               timestamp,
    constraint faena_fechas_ck check (fecha_retorno > fecha_salida)
);

comment on table  faenas                                    is 'Viaje de pesca organizado. Agrupa capturas de un mismo viaje.';
comment on column faenas.id                                 is 'Identificador de la faena.';
comment on column faenas.embarcacion_id                     is 'Embarcación utilizada en la faena.';
comment on column faenas.municipio_id                       is 'Municipio de salida de la faena.';
comment on column faenas.fecha_salida                       is 'Fecha y hora de inicio de la faena.';
comment on column faenas.fecha_retorno                      is 'Fecha y hora de retorno. NULL indica faena en curso.';

-- 4. faenas_pescadores
create table faenas_pescadores (
    faena_id      integer not null constraint faena_pescador_faena_fk references faenas,
    pescador_id   integer not null constraint faena_pescador_pescador_fk references pescadores,
    constraint faenas_pescadores_pk primary key (faena_id, pescador_id)
);

comment on table  faenas_pescadores                          is 'Participación de pescadores en faenas. Resuelve la relación N:M entre faena y pescador.';
comment on column faenas_pescadores.faena_id                 is 'Referencia a la faena.';
comment on column faenas_pescadores.pescador_id              is 'Referencia al pescador participante.';

-- -----------------------------------------------------------------------------
-- Refactorización de tabla capturas
-- -----------------------------------------------------------------------------

-- Objetivo: retirar municipio_id y agregar faena_id.
--
-- Estrategia en tres pasos para preservar datos existentes:
--
--   Paso 1 — Agregar faena_id como columna nullable (sin FK aún).
--              No puede ser NOT NULL de inmediato porque las filas
--              existentes no tienen valor para esta columna todavía.
--
--   Paso 2 — Crear una faena de referencia temporal que consolide
--              las capturas existentes. En un entorno de producción
--              este paso requeriría mapear cada captura a su faena real;
--              aquí se usa una faena por municipio para preservar el
--              dato geográfico que se retira.
--
--   Paso 3 — Agregar la FK, activar NOT NULL y retirar municipio_id.
--
--   Paso 4 - Agregar UK que impida registro de capturas duplicadas por faena
--
-- IMPORTANTE: este proceso ilustra cómo realizar migraciones de esquema
-- sin pérdida de datos, una habilidad crítica en entornos de producción.
-- En un sistema real el Paso 2 requeriría análisis detallado de los
-- datos existentes para asignar cada captura a su faena correcta.
-- -----------------------------------------------------------------------------

-- Paso 1: agregar faena_id como nullable
alter table capturas add column faena_id integer;
comment on column capturas.faena_id is 'Faena en la que se realizó la captura.';

-- Paso 2: crear una embarcación y faena de referencia por municipio
-- para asignar las capturas existentes preservando el dato geográfico.
--
-- Se inserta primero un tipo de embarcación y embarcaciones de referencia,
-- luego una faena por municipio usando la fecha mínima de captura de ese
-- municipio como fecha de salida.

-- Tipo de referencia para las embarcaciones de migración
insert into tipos_embarcacion (nombre, impulsion, capacidad_personas, capacidad_carga_kg)
values ('Canoa de migración', 'remo', 2, 50.00);

-- Una embarcación de referencia por municipio con capturas existentes
insert into embarcaciones (matricula, tipo_embarcacion_id, municipio_id)
select
    -- matrícula sintética: 'mig-' + municipio_id con ceros a la izquierda
    'MIG-' || lpad(m.id::text, 4, '0'),
    (select id from tipos_embarcacion
     where nombre = 'Canoa de migración'),
    m.id
from municipios m
where m.id in (select distinct municipio_id from capturas);

-- Una faena de referencia por municipio, con la fecha mínima de captura
-- de ese municipio como fecha de salida y la máxima como fecha de retorno.
insert into faenas (embarcacion_id, municipio_id, fecha_salida, fecha_retorno)
select
    e.id,
    e.municipio_id,
    min(c.fecha_hora),
    max(c.fecha_hora)
from capturas c
join embarcaciones e on e.municipio_id = c.municipio_id
    and e.matricula = 'MIG-' || lpad(c.municipio_id::text, 4, '0')
group by e.id, e.municipio_id;

-- Asignar faena_id a cada captura según su municipio_id
update capturas c
set faena_id = f.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
where e.municipio_id = c.municipio_id
  and e.matricula = 'MIG-' || lpad(c.municipio_id::text, 4, '0');

-- Paso 3: activar restricciones y retirar municipio_id

-- Verificar que todas las capturas tienen faena_id asignado antes de
-- activar NOT NULL. Si este SELECT retorna valor mayor que cero, detener y revisar.

select count(*) as capturas_sin_faena 
from capturas 
where faena_id is null;

alter table capturas
    alter column faena_id set not null;

alter table capturas
    add constraint captura_faena_fk
        foreign key (faena_id) references faenas (id);

-- retirar municipio_id de captura.
-- el municipio se obtiene ahora a través de faena → municipio.
alter table capturas
    drop column municipio_id;

-- retirar el índice de municipio_id que ya no existe
drop index if exists captura_municipio_ix;

-- crear índice de soporte para faena_id que lo reemplaza
create index captura_faena_ix on capturas (faena_id); 

-- Paso 4: Unicidad de captura en faena
alter table public.capturas
    add constraint captura_faena_pescador_especie_metodo_cantidad_fecha_uk
        unique (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora);

-- -----------------------------------------------------------------------------
-- Índices de soporte para las nuevas tablas
-- -----------------------------------------------------------------------------

create index faena_embarcacion_ix       on faenas                (embarcacion_id);
create index faena_municipio_ix         on faenas                (municipio_id);
create index faena_fecha_salida_ix      on faenas                (fecha_salida);
create index faena_pescador_faena_ix    on faenas_pescadores     (faena_id);
create index faena_pescador_ix          on faenas_pescadores     (pescador_id);
create index embarcacion_tipo_ix        on embarcaciones         (tipo_embarcacion_id);
create index embarcacion_municipio_ix   on embarcaciones         (municipio_id);

-- -----------------------------------------------------------------------------
-- Zona de peligro
-- Se borran los objetos en el orden inverso que fueron creados
-- -----------------------------------------------------------------------------

drop table faenas_pescadores;
drop table faenas;
drop table embarcaciones;
drop table tipos_embarcacion;

