-- =============================================================================
-- Scripts de clase - junio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 2: Fundamentos de SQL y operaciones básicas

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
--  -   ejecutar 00_schema_postgreSQL.sql y 01_seed_postgreSQL.sql 
--      de la unidad 2 antes de este script.
--  -   ejecutar todos los scripts de la unidad 1.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- Sección 1 - Operaciones DML con transacciones básicas
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 1.1. INSERT: registrar una nueva captura
--
-- Escenario: un inspector registra una captura de bocachico en Ayapel
-- con atarraya el 28 de marzo de 2026 a las 7:15 AM.
-- Se usa una transacción explícita para garantizar atomicidad.
-- -----------------------------------------------------------------------------

begin; 

insert into capturas (pescador_id, municipio_id, especie_id, metodo_id, cantidad_kg, fecha_hora, observaciones)
select
    (select p.id from pescadores p
     join municipios m on m.id = p.municipio_id
     where m.nombre = 'Ayapel' limit 1),
    (select id from municipios      where nombre = 'Ayapel'),
    (select id from especies        where nombre_comun = 'Bocachico'),
    (select id from metodos_pesca   where nombre = 'Atarraya'),
    8.50,
    '2026-03-28 07:15:00',
    'Registro de prueba — captura matutina en ciénaga de Ayapel';

commit;


-- -----------------------------------------------------------------------------
-- 1.2. UPDATE: corregir cantidad por error de pesaje
--
-- Escenario: el inspector reporta que la báscula del puerto tenía un
-- descalibrado de +2 kg. Se corrige la captura recién insertada.
-- -----------------------------------------------------------------------------

begin; 

update capturas
set    cantidad_kg   = 6.50,
       observaciones = 'Corregido: báscula descalibrada +2 kg. Valor original: 8.50 kg'
where  fecha_hora    = '2026-03-28 07:15:00'
  and  municipio_id  = (select id from municipios where nombre = 'Ayapel')
  and  especie_id    = (select id from especies   where nombre_comun = 'Bocachico');

commit;

-- -----------------------------------------------------------------------------
-- 1.3. UPDATE: corregir especie mal registrada
--
-- Escenario: una captura registrada como "Nicuro" en Lorica corresponde
-- en realidad a "Capaz", especie visualmente similar. Se identifica
-- la captura más reciente en ese municipio con ese método y se corrige.
-- -----------------------------------------------------------------------------

begin;

update capturas
set    especie_id    = (select id from especies where nombre_comun = 'Capaz'),
       observaciones = coalesce(observaciones, '') ||
                       ' | Corrección taxonómica: especie reclasificada de nicuro a capaz'
where  id = (
    select c.id
    from   capturas c
    join   municipios m    on m.id = c.municipio_id
    join   especies   e    on e.id   = c.especie_id
    join   metodos_pesca mt on mt.id  = c.metodo_id
    where  m.nombre       = 'Lorica'
      and  e.nombre_comun = 'Nicuro'
    order  by c.fecha_hora desc
    limit  1
);

commit;


-- -----------------------------------------------------------------------------
-- 1.4. DELETE: eliminar captura duplicada
--
-- Escenario: se detecta que la captura de prueba del paso A1/A2 fue
-- registrada dos veces por error del sistema. Se elimina el duplicado
-- conservando el registro con mayor captura_id (el más reciente).
-- -----------------------------------------------------------------------------

begin;

delete from capturas
where id = (
    select max(c.id)
    from   capturas c
    where  c.fecha_hora   = '2026-03-28 07:15:00'
      and  c.municipio_id = (select id from municipios where nombre = 'Ayapel')
      and  c.especie_id   = (select id from especies   where nombre_comun = 'Bocachico')
);

commit;


-- -----------------------------------------------------------------------------
-- 1.5. Transacción con ROLLBACK: intento de registro inválido
--
-- Escenario: se intenta registrar una captura con cantidad_kg = 0,
-- lo que viola la restricción CHECK definida en el esquema.
-- La transacción debe revertirse completamente.
--
-- Resultado esperado: ERROR seguido de ROLLBACK automático.
-- -----------------------------------------------------------------------------

insert into capturas (pescador_id, municipio_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    (select id from pescadores limit 1),
    (select id from municipios where nombre = 'Lorica'),
    (select id from especies   where nombre_comun = 'Lisa'),
    (select id from metodos_pesca where nombre = 'Red'),
    0,   -- viola CHECK (cantidad_kg > 0)
    now();


-- -----------------------------------------------------------------------------
-- Sección 2 - Consultas con GROUP BY, HAVING y funciones de fecha
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 2.1. Kg totales capturados por especie
--
-- Pregunta de negocio: ¿cuáles son las especies más capturadas en el período?
-- -----------------------------------------------------------------------------

select
    e.nombre_comun                       as especie,
    e.nombre_cientifico,
    count(*)                             as total_capturas,
    round(sum(c.cantidad_kg), 2)         as total_kg,
    round(avg(c.cantidad_kg), 2)         as promedio_kg,
    round(max(c.cantidad_kg), 2)         as max_kg
from capturas c
join especies e on e.id = c.especie_id
group by e.nombre_comun, e.nombre_cientifico
order by total_kg desc;

-- -----------------------------------------------------------------------------
-- 2.2. Kg totales por cuenca
--
-- Pregunta de negocio: ¿qué cuenca concentra mayor volumen de captura?
-- -----------------------------------------------------------------------------

select
    cu.nombre                            as cuenca,
    count(*)                             as total_capturas,
    round(sum(c.cantidad_kg), 2)         as total_kg,
    round(avg(c.cantidad_kg), 2)         as promedio_por_captura_kg
from capturas c
join municipios m on m.id = c.municipio_id
join cuencas   cu on cu.id   = m.cuenca_id
group by cu.nombre
order by total_kg desc;


-- -----------------------------------------------------------------------------
-- 2.3. Promedio diario de captura por municipio
--
-- Pregunta de negocio: ¿qué municipios tienen mayor actividad pesquera
-- promedio por día de operación?
-- -----------------------------------------------------------------------------

select
    d.nombre                             as departamento,
    m.nombre                             as municipio,
    count(distinct date(c.fecha_hora))   as dias_con_captura,
    round(sum(c.cantidad_kg), 2)         as total_kg,
    round(
        sum(c.cantidad_kg) /
        nullif(count(distinct date(c.fecha_hora)), 0),
    2)                                   as promedio_kg_dia
from capturas c
join municipios    m on m.id    = c.municipio_id
join departamentos d on d.id = m.departamento_id
group by d.nombre, m.nombre
order by promedio_kg_dia desc;

-- -----------------------------------------------------------------------------
-- 2.4. Métodos más usados por cuenca
--
-- Pregunta de negocio: ¿qué artes de pesca predominan en cada cuenca?
-- -----------------------------------------------------------------------------

select
    cu.nombre                            as cuenca,
    mt.nombre                            as metodo,
    count(*)                             as total_capturas,
    round(sum(c.cantidad_kg), 2)         as total_kg
from capturas c
join municipios    m  on m.id  = c.municipio_id
join cuencas       cu on cu.id    = m.cuenca_id
join metodos_pesca mt on mt.id    = c.metodo_id
group by cu.nombre, mt.nombre
order by cu.nombre, total_capturas desc;

-- -----------------------------------------------------------------------------
-- 2.5. Municipios con más de 50 kg capturados en el período
--
-- Pregunta de negocio: ¿qué municipios superan el umbral de 50 kg?
-- Introduce HAVING como filtro post-agrupamiento.
-- -----------------------------------------------------------------------------

select
    cu.nombre                            as cuenca,
    d.nombre                             as departamento,
    m.nombre                             as municipio,
    count(*)                             as total_capturas,
    round(sum(c.cantidad_kg), 2)         as total_kg
from capturas c
join municipios    m  on m.id    = c.municipio_id
join departamentos d  on d.id = m.departamento_id
join cuencas       cu on cu.id      = m.cuenca_id
group by cu.nombre, d.nombre, m.nombre
having sum(c.cantidad_kg) > 50
order by total_kg desc;


-- -----------------------------------------------------------------------------
-- 2.6. Capturas por mes
--
-- Pregunta de negocio: ¿cómo evoluciona el volumen de captura mes a mes?
-- Introduce DATE_TRUNC para agrupar por período temporal.
-- -----------------------------------------------------------------------------

select
    date_trunc('month', c.fecha_hora)   as mes,
    to_char(
        date_trunc('month', c.fecha_hora),
        'month yyyy')                   as mes_nombre,
    count(*)                            as total_capturas,
    round(sum(c.cantidad_kg), 2)        as total_kg,
    round(avg(c.cantidad_kg), 2)        as promedio_kg
from capturas c
group by date_trunc('month', c.fecha_hora)
order by mes;


-- -----------------------------------------------------------------------------
-- 2.7. Capturas por hora del día
--
-- Pregunta de negocio: ¿en qué franja horaria se concentra la actividad?
-- Introduce EXTRACT para descomponer el timestamp.
-- -----------------------------------------------------------------------------

select
    extract(hour from c.fecha_hora)      as hora_del_dia,
    count(*)                             as total_capturas,
    round(sum(c.cantidad_kg), 2)         as total_kg,
    round(avg(c.cantidad_kg), 2)         as promedio_kg
from capturas c
group by extract(hour from c.fecha_hora)
order by hora_del_dia;

