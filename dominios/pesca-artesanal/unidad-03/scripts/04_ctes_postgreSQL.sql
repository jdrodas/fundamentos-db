-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3 — SQL avanzado
-- Archivo: 04_ctes_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql 01_seed_postgreSQL.sql de la unidad 3 antes de este script.
-- ejecutar todos los scripts de las unidades 1 y 2.

-- Una CTE (Common Table Expression) se define con WITH nombre AS (consulta)
-- y existe únicamente durante la ejecución de la consulta que la contiene.
-- A diferencia de una subconsulta en FROM, una CTE se declara antes del
-- SELECT principal y puede reutilizarse varias veces dentro de la misma
-- consulta, lo que mejora la legibilidad de consultas con varios pasos.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CTEs simples

-- Una CTE simple reemplaza una subconsulta en FROM con una sintaxis más
-- legible: el paso intermedio se nombra y se declara antes de usarse,
-- en lugar de anidarse dentro de la consulta principal.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1. Kg totales por faena, reescrito con CTE

-- Pregunta: ¿cuánto pesó en total cada faena?
-- -----------------------------------------------------------------------------

with totales_faena as (
    select
        f.id as faena_id,
        emb.matricula,
        m.nombre as municipio,
        sum(c.cantidad_kg) as total_kg
    from faenas f
        join embarcaciones emb on emb.id = f.embarcacion_id
        join municipios m on m.id = f.municipio_id
        join capturas c on c.faena_id = f.id
    where emb.matricula not like 'MIG-%'
    group by f.id, emb.matricula, m.nombre
)
select
    faena_id,
    matricula,
    municipio,
    round(total_kg, 2) as total_kg
from totales_faena
order by total_kg desc;

-- -----------------------------------------------------------------------------
-- 1.2. Faenas con más pescadores que el promedio

-- Pregunta: ¿qué faenas tuvieron una tripulación más numerosa que el
-- promedio de tripulación de todas las faenas?
-- -----------------------------------------------------------------------------

with participacion_por_faena as (
    select
        fp.faena_id,
        count(fp.pescador_id) as total_pescadores
    from faenas_pescadores fp
    group by fp.faena_id
)
select
    ppf.faena_id,
    emb.matricula,
    m.nombre as municipio,
    ppf.total_pescadores,
    (select round(avg(total_pescadores), 2)
     from participacion_por_faena) as promedio_general_pescadores
from participacion_por_faena ppf
    join faenas f on f.id = ppf.faena_id
    join embarcaciones emb on emb.id = f.embarcacion_id
    join municipios m on m.id = f.municipio_id
where ppf.total_pescadores > (
    select avg(total_pescadores) from participacion_por_faena
)
  and emb.matricula not like 'MIG-%'
order by ppf.total_pescadores desc;

-- =============================================================================
-- 2. CTEs múltiples encadenadas
--
-- Es posible declarar varias CTEs en una misma sentencia WITH, separadas
-- por comas. Cada CTE puede referenciar a las declaradas antes que ella.
-- Este patrón permite construir análisis de varios pasos donde cada paso
-- tiene un nombre claro, facilitando la lectura y el mantenimiento.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1. Comparación de productividad de pescadores contra el promedio de su cuenca
--
-- Pregunta: ¿qué pescadores capturan más que el promedio de los pescadores
-- que operan en su misma cuenca?
--
-- Paso 1 (kg_por_pescador): total de kg capturado por cada pescador.
-- Paso 2 (promedio_por_cuenca): promedio de esos totales, agrupado por cuenca.
-- Paso final: compara cada pescador contra el promedio de su propia cuenca.
-- -----------------------------------------------------------------------------

with kg_por_pescador as (
    select
        p.id as pescador_id,
        m.cuenca_id,
        sum(c.cantidad_kg)  as total_kg
    from pescadores  p
        join municipios m on m.id = p.municipio_id
        join capturas c on c.pescador_id = p.id
    group by p.id, m.cuenca_id
),
promedio_por_cuenca as (
    select
        cuenca_id,
        round(avg(total_kg), 2) as promedio_kg_cuenca
    from kg_por_pescador
    group by cuenca_id
)
select
    kpp.pescador_id,
    cu.nombre as cuenca,
    round(kpp.total_kg, 2) as total_kg_pescador,
    ppc.promedio_kg_cuenca
from kg_por_pescador kpp
    join promedio_por_cuenca ppc on ppc.cuenca_id = kpp.cuenca_id
    join cuencas cu on cu.id = kpp.cuenca_id
where kpp.total_kg > ppc.promedio_kg_cuenca
order by cu.nombre, kpp.total_kg desc;

-- -----------------------------------------------------------------------------
-- 2.2. Ranking de municipios por productividad, con clasificación
--
-- Pregunta: ¿cómo se clasifican los municipios según su productividad
-- pesquera total: alta, media o baja?
--
-- Paso 1 (kg_por_municipio): total de kg por municipio.
-- Paso 2 (estadisticas_generales): promedio del conjunto.
-- Paso final: clasifica cada municipio comparándolo contra el promedio
-- general, usando CASE WHEN sobre el valor calculado en el paso anterior.
-- El umbral de clasificación se define como un porcentaje del promedio:
-- por encima del 120% del promedio es 'Alta', por debajo del 80% es 'Baja',
-- el resto es 'Media'. Este criterio es una simplificación pedagógica;
-- en la práctica profesional los umbrales de clasificación suelen surgir
-- de análisis estadístico o reglas de negocio específicas del dominio.
-- -----------------------------------------------------------------------------

with kg_por_municipio as (
    select
        m.id as municipio_id,
        m.nombre as municipio,
        sum(c.cantidad_kg) as total_kg
    from municipios m
        join faenas f on f.municipio_id = m.id
        join capturas c on c.faena_id     = f.id
    group by m.id, m.nombre
),
estadisticas_generales as (
    select
        round(avg(total_kg), 2) as promedio_general
    from kg_por_municipio
)
select
    kpm.municipio,
    round(kpm.total_kg, 2) as total_kg,
    eg.promedio_general,
    case
        when kpm.total_kg > eg.promedio_general * 1.2
            then 'alta'
        when kpm.total_kg < eg.promedio_general * 0.8
            then 'baja'
        else 'media'
    end as clasificacion_productividad
from kg_por_municipio kpm
cross join estadisticas_generales eg
order by kpm.total_kg desc;

-- =============================================================================
-- 3. CTE recursiva

-- Una CTE recursiva se declara con WITH RECURSIVE y consta de dos partes
-- unidas por UNION o UNION ALL:
--   1. Consulta ancla (caso base): produce las filas iniciales.
--   2. Consulta recursiva: referencia a la CTE misma y produce nuevas filas
--      a partir de las anteriores, hasta que no se generan filas nuevas.

-- Se usa para recorrer estructuras jerárquicas o secuenciales que no
-- tienen una profundidad fija conocida de antemano.

-- El dominio de pesca artesanal no tiene una jerarquía natural evidente
-- (no hay categorías anidadas ni árboles organizacionales). Para ilustrar
-- el concepto de forma honesta, se construye una CTE recursiva sobre una
-- secuencia temporal: generar la serie de fechas del período de faenas
-- registradas, útil para detectar días sin actividad pesquera.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1. Serie de fechas del período de faenas y su actividad diaria

-- Pregunta: para cada día del período en que hay faenas registradas,
-- ¿cuántas faenas zarparon y cuántos kg se capturaron ese día?

-- Caso base: el primer día es la fecha mínima de fecha_salida en faena.
-- Caso recursivo: cada fila siguiente suma un día a la anterior, hasta
-- alcanzar la fecha máxima de fecha_salida en faena.

-- Este patrón (generar una serie de fechas) es uno de los usos más
-- comunes de CTE recursiva en la práctica profesional, porque permite
-- identificar huecos (días sin actividad) que un GROUP BY simple no
-- puede mostrar, ya que un GROUP BY solo agrupa filas que existen.
-- -----------------------------------------------------------------------------

with recursive serie_dias as (
    -- caso base: el primer día del período
    select min(date(fecha_salida)) as dia
    from faenas

    union all

    -- caso recursivo: cada día siguiente, hasta llegar al último
    select date(sd.dia + interval '1 day')
    from serie_dias sd
    where sd.dia < (select max(date(fecha_salida)) from faenas)
),
actividad_por_dia as (
    select
        date(f.fecha_salida) as dia,
        count(distinct f.id) as faenas_zarpadas,
        coalesce(sum(c.cantidad_kg), 0) as total_kg
    from faenas f
    left join capturas c on c.faena_id = f.id
    group by date(f.fecha_salida)
)
select
    sd.dia,
    coalesce(ap.faenas_zarpadas, 0) as faenas_zarpadas,
    coalesce(ap.total_kg, 0) as total_kg,
    case
        when ap.faenas_zarpadas is null then 'Sin actividad'
        else 'Con actividad'
    end as estado_dia
from serie_dias sd
left join actividad_por_dia ap on ap.dia = sd.dia
order by sd.dia;
