-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 4: Lógica almacenada
-- Archivo: 01_seed_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql de la unidad 4 antes de este script.
-- ejecutar todos los scripts de las unidades 1, 2 y 3.

-- Propósito:
-- Este script inserta vedas representativas del dominio, basadas en
-- períodos reales de veda pesquera en Colombia, para que los procedimientos
-- y funciones de los scripts siguientes tengan datos realistas contra
-- los cuales validar.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Inserción de datos semilla
-- -----------------------------------------------------------------------------

-- 1. vedas
insert into vedas (especie_id, cuenca_id, fecha_inicio, fecha_fin, descripcion)
select e.id, c.id, v.fecha_inicio, v.fecha_fin, v.descripcion
from (values
    ('Bagre rayado', 'Magdalena', '2026-05-01'::date, '2026-05-30'::date,
     'Veda de reproducción del bagre rayado en la cuenca Magdalena, primer período del año.'),
    ('Bagre rayado', 'Magdalena', '2026-09-15'::date, '2026-10-15'::date,
     'Veda de reproducción del bagre rayado en la cuenca Magdalena, segundo período del año.'),
    ('Bocachico',    'Magdalena', '2026-04-01'::date, '2026-04-30'::date,
     'Veda de reproducción del bocachico en la cuenca Magdalena, coincide con el inicio de la subienda.'),
    ('Bocachico',    'Sinú',      '2025-11-01'::date, '2025-11-30'::date,
     'Veda vencida de bocachico en la cuenca Sinú, período de referencia histórica del año anterior.')
) as v (nombre_especie, nombre_cuenca, fecha_inicio, fecha_fin, descripcion)
join especies e on e.nombre_comun = v.nombre_especie
join cuencas  c on c.nombre = v.nombre_cuenca;

-- Veda de alcance nacional (cuenca_id NULL): mero guasa en riesgo de conservación
insert into vedas (especie_id, cuenca_id, fecha_inicio, fecha_fin, descripcion)
select e.id, null, '2026-01-01'::date, '2026-12-31'::date,
       'veda nacional de mero guasa por riesgo de conservación de la especie, vigente todo el año 2026.'
from especies e
where e.nombre_comun = 'Mero guasa';

-- Veda futura: pargo lunarejo, segundo semestre de 2026, aún no vigente
-- a la fecha de las capturas y faenas registradas en el seed del curso.
insert into veda (especie_id, cuenca_id, fecha_inicio, fecha_fin, descripcion)
select e.especie_id, c.cuenca_id, '2026-11-01'::date, '2026-11-30'::date,
       'veda futura de pargo lunarejo en la cuenca caribe, no vigente durante el período de capturas registradas.'
from especie e
join cuenca  c on c.nombre = 'Caribe'
where e.nombre_comun = 'Pargo lunarejo';

-- -----------------------------------------------------------------------------
-- Consultas de verificación
-- -----------------------------------------------------------------------------

-- Vedas registradas, con especie y cuenca (NULL = nacional)
select
    e.nombre_comun as especie,
    coalesce(c.nombre, 'nacional')   as alcance,
    v.fecha_inicio,
    v.fecha_fin,
    v.descripcion
from vedas v
join especies e on e.id = v.especie_id
left join cuencas c on c.id = v.cuenca_id
order by v.fecha_inicio;

-- ¿Qué vedas están vigentes hoy?
select
    e.nombre_comun as especie,
    coalesce(c.nombre, 'nacional')   as alcance,
    v.fecha_inicio,
    v.fecha_fin
from vedas v
join especies e on e.id = v.especie_id
left join cuencas c on c.id = v.cuenca_id
where current_date between v.fecha_inicio and v.fecha_fin
order by e.nombre_comun;
