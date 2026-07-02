-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3: SQL avanzado
-- Archivo: 06_views_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql 01_seed_postgreSQL.sql de la unidad 3 antes de este script.
-- ejecutar todos los scripts de las unidades 1 y 2.

-- Propósito:
-- Este script encapsula como vistas (CREATE VIEW) tres consultas ya
-- construidas y validadas en los scripts anteriores. 

-- Nota de alcance: 
-- Estas son vistas simples. Las vistas materializadas,
-- que sí almacenan físicamente el resultado y requieren una estrategia
-- de actualización (REFRESH), se abordan en la Unidad 5 junto con las
-- demás consideraciones de rendimiento y producción del curso.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. v_faenas_detalle
--
-- Encapsula la consulta que indica cada faena con su embarcación,
-- tipo de embarcación, municipio de zarpe, departamento y cuenca en una
-- sola fila. Excluye las embarcaciones sintéticas de migración.
--
-- Uso típico: punto de partida para cualquier análisis que necesite el
-- contexto geográfico y operativo completo de una faena, sin repetir
-- la cadena de cinco JOINs en cada consulta nueva.
-- -----------------------------------------------------------------------------

create view v_faenas_detalle as
select
    f.id as faena_id,
    emb.matricula,
    te.nombre as tipo_embarcacion,
    te.impulsion,
    te.capacidad_personas,
    te.capacidad_carga_kg,
    m.nombre as municipio_zarpe,
    d.nombre as departamento,
    cu.nombre as cuenca,
    f.fecha_salida,
    f.fecha_retorno
from faenas f
    join embarcaciones emb on emb.id = f.embarcacion_id
    join tipos_embarcacion te on te.id = emb.tipo_embarcacion_id
    join municipios m on m.id = f.municipio_id
    join departamentos d on d.id = m.departamento_id
    join cuencas cu on cu.id = m.cuenca_id
where emb.matricula not like 'MIG-%';

comment on view v_faenas_detalle is
    'Faenas con embarcación, tipo, municipio, departamento y cuenca. Excluye embarcaciones de migración.';

-- -----------------------------------------------------------------------------
-- 2. v_productividad_pescador
--
-- Encapsula la consulta B2 de 03_subqueries.sql: total de capturas y kg
-- acumulados por pescador, restringido a faenas reales (no de migración).
--
-- Uso típico: base para consultas de ranking, comparación entre pescadores
-- o análisis de productividad por municipio y cuenca.
-- -----------------------------------------------------------------------------

create view v_productividad_pescador as
select
    p.id as pescador_id,
    m.nombre as municipio_base,
    cu.nombre as cuenca_base,
    count(c.id) as total_capturas,
    round(sum(c.cantidad_kg), 2) as total_kg
from pescadores p
    join municipios m  on m.id = p.municipio_id
    join cuencas cu on cu.id = m.cuenca_id
    join capturas c  on c.pescador_id = p.id
    join faenas f  on f.id = c.faena_id
    join embarcaciones emb on emb.id = f.embarcacion_id
where emb.matricula not like 'MIG-%'
group by p.id, m.nombre, cu.nombre;

comment on view v_productividad_pescador is
    'Total de capturas y kg acumulados por pescador, en faenas reales.';

-- -----------------------------------------------------------------------------
-- 3. v_ranking_especies_cuenca
--
-- Encapsula la consulta A3 de 05_window_functions.sql: posición de cada
-- especie dentro de su cuenca según el total de kg capturado, usando
-- RANK() particionado por cuenca.
--
-- Uso típico: identificar rápidamente la especie líder de cada cuenca
-- (posicion_en_cuenca = 1) o comparar el desempeño relativo de una
-- especie dentro de su cuenca sin recalcular el ranking cada vez.
-- -----------------------------------------------------------------------------

create view v_ranking_especies_cuenca as
select
    cu.nombre as cuenca,
    e.nombre_comun as especie,
    round(sum(c.cantidad_kg), 2) as total_kg,
    rank() over (
        partition by cu.id
        order by sum(c.cantidad_kg) desc
    ) as posicion_en_cuenca
from capturas c
    join especies e  on e.id = c.especie_id
    join faenas f  on f.id = c.faena_id
    join municipios m  on m.id = f.municipio_id
    join cuencas cu on cu.id = m.cuenca_id
group by cu.id, cu.nombre, e.id, e.nombre_comun;

comment on view v_ranking_especies_cuenca is
    'Ranking de especies por kg capturado, particionado por cuenca.';


-- -----------------------------------------------------------------------------
-- Consultas de verificación
--
-- Estas consultas muestran el valor de las vistas: preguntas que antes
-- requerían repetir varios JOINs ahora se responden con un SELECT simple
-- sobre la vista, como si fuera una tabla más.
-- -----------------------------------------------------------------------------

-- Faenas activas (en curso) con su contexto completo, sin repetir JOINs
select * from v_faenas_detalle where fecha_retorno is null order by fecha_salida;

-- Los 5 pescadores más productivos
select * from v_productividad_pescador order by total_kg desc limit 5;

-- La especie líder de cada cuenca
select cuenca, especie, total_kg from v_ranking_especies_cuenca where posicion_en_cuenca = 1;

-- Combinar dos vistas: productividad de pescadores que operan en la cuenca
-- cuya especie líder es el Corvina
select vp.*
from v_productividad_pescador vp
where vp.cuenca_base in (
    select cuenca from v_ranking_especies_cuenca
    where especie = 'Corvina' and posicion_en_cuenca = 1
)
order by vp.total_kg desc;
