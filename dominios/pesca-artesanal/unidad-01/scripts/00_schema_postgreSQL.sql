-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 1: Fundamentos y diseño de bases de datos relacionales
-- Archivo: 00_schema_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql y 01_seed_postgreSQL.sql de la unidad 3 antes de este script.
-- ejecutar todos los scripts de las unidades 1 y 2.

-- Propósito: 
-- Ejemplos de referencia de cada tipo de JOIN aplicados al dominio
-- de la cohorte, con la pregunta de negocio que cada uno responde.

-- Principio de lectura de cada consulta:
--   Cada bloque incluye la pregunta de negocio que responde, el tipo de JOIN
--   utilizado, la justificación de por qué ese tipo es el adecuado para esa
--   pregunta, y el resultado esperado en términos del dominio.

-- =============================================================================

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Propósito:
-- Este script inicia el proceso de implementación del modelo de datos:
--      - Abasteciendo el contenedor de PostgreSQL en Docker
--      - Creación de base de datos y usuarios
--      - Creación del modelo de datos
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Abastecimiento de imagen en Docker
-- -----------------------------------------------------------------------------

-- Descargar la imagen
docker pull postgres:latest

-- Crear el contenedor
docker run --name pgsql-pesca -e POSTGRES_PASSWORD=unaClav3 -d -p 5432:5432 postgres:latest


-- -----------------------------------------------------------------------------
-- Creación de base de datos y usuarios
-- -----------------------------------------------------------------------------

-- Con usuario Postgres, desde el shell del contenedor
psql -U postgres

-- crear el esquema la base de datos
create database pesca_db;

-- Conectarse a la base de datos
\c pesca_db;

-- crear el usuario con el que se implementará la creación del modelo
create user pesca_usr with encrypted password 'unaClav3';

-- asignación de privilegios para el usuario

-- Privilegios para establecer conexiones
grant connect on database pesca_db to pesca_usr;

-- privilegios para crear tablas temporales
grant temporary on database pesca_db to pesca_usr;

-- Privilegios de uso en el esquema
grant usage on schema public to pesca_usr;

-- privilegios para crear objetos
grant create on schema public to pesca_usr;

-- Privilegios sobre tablas existentes
grant select, insert, update, delete, trigger on all tables in schema public to pesca_usr;

-- privilegios sobre secuencias existentes
grant usage, select on all sequences in schema public to pesca_usr;

-- privilegios sobre funciones existentes
grant execute on all functions in schema public to pesca_usr;

-- privilegios sobre procedimientos existentes
grant execute on all procedures in schema public to pesca_usr;

-- privilegios sobre futuras tablas y secuencias
alter default privileges in schema public grant select, insert, update, delete, trigger on tables to pesca_usr;

alter default privileges in schema public grant select, usage on sequences to pesca_usr;

-- privilegios sobre futuras funciones y procedimientos
alter default privileges in schema public grant execute on routines to pesca_usr;

--Privilegios de consulta sobre el esquema information_schema
grant usage on schema information_schema to pesca_usr;


-- -----------------------------------------------------------------------------
-- Creación del modelo de datos
-- -----------------------------------------------------------------------------

-- ****************************************
-- Creación de Tablas
-- ****************************************

-- Con el usuario pesca_app

-- 1. cuencas
create table cuencas (
    id                          serial          constraint cuencas_pk primary key,
    nombre                      varchar(100)    not null,
    descripcion                 varchar(500),
    constraint cuenca_nombre_uk unique (nombre)
);

comment on table  cuencas                       is 'cuencas hidrográficas donde se registra actividad de pesca artesanal.';
comment on column cuencas.id                    is 'identificador de la cuenca';
comment on column cuencas.nombre                is 'nombre de la cuenca.';
comment on column cuencas.descripcion           is 'descripción opcional de la cuenca.';

-- 2. departamentos
create table departamentos (
    id                          serial        constraint departamentos_pk primary key,
    nombre                      varchar(100)  not null,
    constraint departamento_nombre_uk unique (nombre)
);

comment on table  departamentos                 is 'departamentos de colombia con presencia en el dominio pesquero.';
comment on column departamentos.id              is 'identificador del departamento';
comment on column departamentos.nombre          is 'nombre del departamento.';


-- 3. municipios
create table municipios (
    id                          serial        constraint municipios_pk primary key,
    nombre                      varchar(150)  not null,
    departamento_id             integer       not null constraint municipio_departamento_fk references departamentos,
    cuenca_id                   integer       not null constraint municipio_cuenca_fk references cuencas,
    constraint municipio_nombre_departamento_uk unique (nombre, departamento_id)
);

comment on table  municipios                    is 'municipios con actividad de pesca artesanal registrada.';
comment on column municipios.id                 is 'identificador del municipio';
comment on column municipios.nombre             is 'nombre del municipio.';
comment on column municipios.departamento_id    is 'departamento al que pertenece el municipio.';
comment on column municipios.cuenca_id          is 'cuenca principal asociada al municipio.';

-- 4. especies
create table especies (
    id                          serial        constraint especies_pk primary key,
    nombre_comun                varchar(150)  not null,
    nombre_cientifico           varchar(200)  not null,
    constraint especie_nombre_cientifico_uk unique (nombre_cientifico)
);

comment on table  especies                      is 'especies de peces presentes en la actividad pesquera artesanal.';
comment on column especies.id                   is 'identificador de la especie.';
comment on column especies.nombre_comun         is 'nombre común de la especie en colombia.';
comment on column especies.nombre_cientifico    is 'nombre científico en notación binomial. debe ser único.';


-- 5. especies_cuencas
create table especies_cuencas (
    especie_id    integer    not null constraint especies_cuencas_especie_fk references especies,
    cuenca_id     integer    not null constraint especies_cuencas_cuenca_fk references cuencas,
    es_nativa     boolean    not null default true,
    constraint especies_cuencas_pk primary key (especie_id, cuenca_id)
);

comment on table  especies_cuencas              is 'distribución de especies por cuenca.';
comment on column especies_cuencas.especie_id   is 'referencia a la especie.';
comment on column especies_cuencas.cuenca_id    is 'referencia a la cuenca.';
comment on column especies_cuencas.es_nativa    is 'indica si la especie es nativa de esa cuenca (true) o introducida (false).';


-- -----------------------------------------------------------------------------
-- Zona de peligro
-- Se borran los objetos en el orden inverso que fueron creados
-- -----------------------------------------------------------------------------

drop table especies_cuencas;
drop table especies;
drop table municipios;
drop table cuencas;
drop table departamentos;