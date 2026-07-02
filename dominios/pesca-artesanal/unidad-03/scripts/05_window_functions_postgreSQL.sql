-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3 — SQL avanzado
-- Archivo: 05_window_functions_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql 01_seed_postgreSQL.sql de la unidad 3 antes de este script.
-- ejecutar todos los scripts de las unidades 1 y 2.

-- Window Functions:
-- Una función de ventana realiza un cálculo sobre un conjunto de filas
-- relacionadas con la fila actual, SIN colapsar el resultado en una sola
-- fila por grupo (a diferencia de GROUP BY con funciones agregadas).
-- Cada fila conserva su identidad individual, y el cálculo de ventana
-- se agrega como una columna adicional.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Ranking

-- RANK(), DENSE_RANK() y ROW_NUMBER() asignan una posición a cada fila
-- dentro de su partición, según el ORDER BY especificado. Difieren en
-- cómo tratan los empates:
--   ROW_NUMBER()  asigna números consecutivos únicos, incluso con empates.
--   RANK()        asigna el mismo número a los empates y salta posiciones
--                 después de un empate (1, 2, 2, 4).
--   DENSE_RANK()  asigna el mismo número a los empates sin saltar
--                 posiciones (1, 2, 2, 3).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1. Ranking de pescadores por kg total capturado

-- Pregunta: ¿en qué posición queda cada pescador según su producción total?

-- Se usa RANK() porque interesa que los empates compartan posición y que
-- la siguiente posición refleje cuántos pescadores quedaron por encima.
-- -----------------------------------------------------------------------------

select
    p.id as pescador_id,
    m.nombre as municipio_base,
    round(sum(c.cantidad_kg), 2) as total_kg,
    rank() over (order by sum(c.cantidad_kg) desc) as posicion_ranking
from pescadores p
    join municipios m on m.id = p.municipio_id
    join capturas c on c.pescador_id = p.id
group by p.id, m.nombre
order by posicion_ranking;

-- -----------------------------------------------------------------------------
-- 1.2. Comparación de RANK, DENSE_RANK y ROW_NUMBER sobre el mismo conjunto

-- Pregunta pedagógica: ¿cómo difieren las tres funciones cuando hay empates?

-- Se agrupan las capturas por especie y se comparan las tres funciones
-- de ranking simultáneamente sobre el total de kg por especie, para que
-- las diferencias sean visibles en el mismo resultado.
-- -----------------------------------------------------------------------------

select
    e.nombre_comun as especie,
    round(sum(c.cantidad_kg), 2) as total_kg,
    row_number() over (order by sum(c.cantidad_kg) desc) as row_number,
    rank()       over (order by sum(c.cantidad_kg) desc) as rank,
    dense_rank() over (order by sum(c.cantidad_kg) desc) as dense_rank
from capturas c
    join especies e on e.id = c.especie_id
group by e.nombre_comun
order by total_kg desc;

-- -----------------------------------------------------------------------------
-- 1.3. Ranking de especies por cuenca (particionado)

-- Pregunta: dentro de cada cuenca, ¿cuál es la especie más capturada?

-- PARTITION BY cu.id reinicia el ranking en cada cuenca. Sin la
-- partición, el ranking sería global y no permitiría comparar posiciones
-- dentro de cada cuenca por separado.
-- -----------------------------------------------------------------------------

select
    cu.nombre as cuenca,
    e.nombre_comun as especie,
    round(sum(c.cantidad_kg), 2) as total_kg,
    rank() over (
        partition by cu.id
        order by sum(c.cantidad_kg) desc
    )as posicion_en_cuenca
from capturas c
    join especies e  on e.id = c.especie_id
    join faenas f  on f.id = c.faena_id
    join municipios m  on m.id = f.municipio_id
    join cuencas cu on cu.id = m.cuenca_id
group by cu.id, cu.nombre, e.id, e.nombre_comun
order by cu.nombre, posicion_en_cuenca;

-- =============================================================================
-- 2. Numeración de filas dentro de particiones

-- ROW_NUMBER() particionado permite enumerar las filas de cada grupo por
-- separado, útil para identificar "el primero", "el segundo", etc. dentro
-- de cada categoría, o para filtrar un número fijo de filas por grupo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1. Las dos capturas más grandes de cada faena

-- Pregunta: ¿cuáles fueron las dos capturas de mayor peso en cada faena?

-- Se numeran las capturas dentro de cada faena ordenadas por cantidad_kg
-- descendente, y se filtra a las dos primeras de cada partición mediante
-- una subconsulta en FROM (las funciones de ventana no pueden usarse
-- directamente en WHERE porque se calculan después de ese filtro).
-- -----------------------------------------------------------------------------

select
    faena_id,
    pescador_id,
    especie,
    cantidad_kg,
    posicion_en_faena
from (
    select
        c.faena_id,
        c.pescador_id,
        e.nombre_comun as especie,
        c.cantidad_kg,
        row_number() over (
            partition by c.faena_id
            order by c.cantidad_kg desc
        ) as posicion_en_faena
    from capturas c
        join especies e on e.id = c.especie_id
) capturas_numeradas
where posicion_en_faena <= 2
order by faena_id, posicion_en_faena;

-- -----------------------------------------------------------------------------
-- 2.2. Orden cronológico de las faenas de cada embarcación

-- Pregunta: ¿cuál fue la primera, segunda, tercera... faena de cada
-- embarcación, en orden de fecha de salida?

-- Esta es la misma pregunta planteada en 04_ctes.sql, resuelta allí con
-- una CTE recursiva por ser el concepto correspondiente en ese script.
-- Aquí se resuelve con ROW_NUMBER(), que es la herramienta natural para
-- este tipo de numeración secuencial y la que se preferiría en código
-- de producción por su menor costo de ejecución frente a la recursión.
-- -----------------------------------------------------------------------------

select
    emb.matricula,
    f.id as faena_id,
    f.fecha_salida,
    row_number() over (
        partition by f.embarcacion_id
        order by f.fecha_salida
    ) as numero_faena
from faenas f
    join embarcaciones emb on emb.id = f.embarcacion_id
where emb.matricula not like 'MIG-%'
order by emb.matricula, numero_faena;

-- =============================================================================
-- 3. Cálculos acumulativos (running totals)

-- Una función agregada usada como función de ventana (SUM, AVG, COUNT)
-- con ORDER BY en la cláusula OVER calcula el acumulado progresivo hasta
-- la fila actual, en lugar del total del grupo completo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1. Acumulado progresivo de kg capturados por fecha

-- Pregunta: día a día, ¿cuál ha sido el total acumulado de kg capturados
-- desde el inicio del período?

-- SUM() OVER (ORDER BY dia) sin PARTITION BY calcula el acumulado sobre
-- todo el conjunto ordenado por fecha. Cada fila muestra la suma de todas
-- las filas anteriores más la propia, hasta llegar al total general en
-- la última fila.

-- La función de ventana envuelve a SUM(c.cantidad_kg), que ya es un
-- agregado del GROUP BY. Esto es válido en PostgreSQL: primero se
-- calcula el agregado por grupo (GROUP BY), y luego la función de
-- ventana opera sobre esos resultados ya agregados.
-- -----------------------------------------------------------------------------

select
    date(f.fecha_salida) as dia,
    round(sum(c.cantidad_kg), 2) as total_kg_dia,
    round(
        sum(sum(c.cantidad_kg)) over (order by date(f.fecha_salida)),
    2) as acumulado_kg
from faenas   f
    join capturas c on c.faena_id = f.id
group by date(f.fecha_salida)
order by dia;

-- -----------------------------------------------------------------------------
-- 3.2. Porcentaje que representa cada faena sobre el total de su embarcación

-- Pregunta: ¿qué porcentaje del total capturado por cada embarcación
-- corresponde a cada una de sus faenas?

-- SUM() OVER (PARTITION BY embarcacion_id) sin ORDER BY calcula el total
-- de la partición completa (no un acumulado progresivo), porque no hay
-- ORDER BY dentro de OVER. Se usa para calcular la proporción de cada
-- fila respecto al total de su grupo, sin colapsar las filas individuales.
-- -----------------------------------------------------------------------------

select
    emb.matricula,
    f.id as faena_id,
    f.fecha_salida,
    round(sum(c.cantidad_kg), 2) as total_kg_faena,
    round(
        sum(sum(c.cantidad_kg)) over (partition by emb.id),
    2) as total_kg_embarcacion,
    round(
        100.0 * sum(c.cantidad_kg) /
        sum(sum(c.cantidad_kg)) over (partition by emb.id),
    2) as porcentaje_del_total
from faenas f
join embarcaciones emb on emb.id = f.embarcacion_id
join capturas c on c.faena_id = f.id
where emb.matricula not like 'MIG-%'
group by emb.id, emb.matricula, f.id, f.fecha_salida
order by emb.matricula, f.fecha_salida;

-- =============================================================================
-- 4. Cálculos móviles (LAG, LEAD)
--
-- LAG() accede al valor de una fila anterior dentro de la partición.
-- LEAD() accede al valor de una fila posterior.
-- Ambas requieren ORDER BY dentro de OVER para definir qué fila es
-- "anterior" o "posterior". Se usan para comparar cada fila contra su
-- vecina inmediata, típicamente para calcular variaciones o diferencias.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1. Variación de kg capturados entre faenas consecutivas de una embarcación
--
-- Pregunta: para cada embarcación, ¿cuánto varió la producción respecto
-- a su faena inmediatamente anterior?
--
-- LAG(total_kg_faena) OVER (PARTITION BY ... ORDER BY fecha_salida) trae
-- el total de la faena anterior a la fila actual. La primera faena de
-- cada embarcación no tiene faena previa, por lo que LAG retorna NULL.
-- -----------------------------------------------------------------------------

select
    matricula,
    faena_id,
    fecha_salida,
    total_kg_faena,
    lag(total_kg_faena) over (
        partition by embarcacion_id
        order by fecha_salida
    ) as kg_faena_anterior,
    round(
        total_kg_faena -
        lag(total_kg_faena) over (
            partition by embarcacion_id
            order by fecha_salida
        ),
    2) as variacion_kg
from (
    select
        emb.id as embarcacion_id,
        emb.matricula,
        f.id as faena_id,
        f.fecha_salida,
        round(sum(c.cantidad_kg), 2)  as total_kg_faena
    from faenas f
    join embarcaciones emb on emb.id = f.embarcacion_id
    join capturas c   on c.faena_id         = f.id
    where emb.matricula not like 'mig-%'
    group by emb.id, emb.matricula, f.id, f.fecha_salida
) totales_por_faena
order by matricula, fecha_salida;

-- -----------------------------------------------------------------------------
-- 4.2. Tiempo transcurrido hasta la siguiente faena de la misma embarcación
--
-- Pregunta: ¿cuántos días pasaron entre una faena y la siguiente de la
-- misma embarcación?
--
-- LEAD(fecha_salida) trae la fecha de la faena siguiente. La resta entre
-- fechas en PostgreSQL retorna un INTERVAL; EXTRACT(DAY FROM ...) extrae
-- el número de días de ese intervalo.
-- -----------------------------------------------------------------------------

select
    emb.matricula,
    f.id as faena_id,
    f.fecha_salida,
    lead(f.fecha_salida) over (
        partition by f.embarcacion_id
        order by f.fecha_salida
    ) as fecha_siguiente_faena,
    extract(
        day from
        lead(f.fecha_salida) over (
            partition by f.embarcacion_id
            order by f.fecha_salida
        ) - f.fecha_salida
    ) as dias_hasta_siguiente_faena
from faenas f
    join embarcaciones emb on emb.id = f.embarcacion_id
where emb.matricula not like 'MIG-%'
order by emb.matricula, f.fecha_salida;