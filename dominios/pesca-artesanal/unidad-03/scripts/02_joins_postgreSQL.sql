-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3: SQL avanzado
-- Archivo: 02_joins_postgreSQL.sql

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

-- -----------------------------------------------------------------------------
-- 1. INNER JOIN

-- Retorna únicamente las filas que tienen correspondencia en AMBAS tablas.
-- Es el JOIN más común: se usa cuando solo interesan los registros que
-- tienen relación confirmada en los dos lados.
-- -----------------------------------------------------------------------------

-- 1.1. Capturas con nombre de especie y método

-- Pregunta: ¿qué se capturó, con qué método y cuánto pesó en cada evento?

-- Se usa INNER JOIN porque solo interesan las capturas que tienen
-- especie y método válidos registrados; una captura sin especie o sin
-- método no debería existir (NOT NULL en el esquema lo garantiza).
-- -----------------------------------------------------------------------------

select
    c.id captura_id,
    c.fecha_hora,
    e.nombre_comun as especie,
    e.nombre_cientifico,
    mt.nombre as metodo,
    c.cantidad_kg
from capturas c
    join especies e  on e.id  = c.especie_id
    join metodos_pesca mt on mt.id  = c.metodo_id
order by c.fecha_hora desc
limit 20;

-- -----------------------------------------------------------------------------
-- 1.2. Faenas con embarcación y municipio de zarpe
--
-- Pregunta: ¿desde qué municipio salió cada faena y en qué embarcación?
--
-- Se usa INNER JOIN porque una faena siempre tiene embarcación y municipio
-- (NOT NULL en el esquema). No hay faenas huérfanas posibles.

-- Se excluyen las embarcaciones utilizadas en la migración de datos (MIG*)
-- -----------------------------------------------------------------------------

select
    f.id as faena_id,
    emb.matricula,
    te.nombre as tipo_embarcacion,
    te.impulsion,
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
where emb.matricula not like 'MIG-%'
order by f.fecha_salida;

-- -----------------------------------------------------------------------------
-- 1.3. Pescadores y las faenas en las que participaron
--
-- Pregunta: ¿qué pescadores han salido a faena y cuántas veces?
--
-- Se usa INNER JOIN porque solo interesan los pescadores que tienen
-- al menos una faena registrada. Los que nunca han salido no aparecen,
-- lo cual es exactamente lo que la pregunta pide.
-- -----------------------------------------------------------------------------

select
    p.id as pescador_id,
    m.nombre as municipio_base,
    count(fp.faena_id) as total_faenas
from pescadores p
join faenas_pescadores fp on fp.pescador_id = p.id
join municipios  m on m.id = p.municipio_id
group by p.id, m.nombre
order by total_faenas desc;

-- -----------------------------------------------------------------------------
-- 2. LEFT JOIN
--
-- Retorna TODAS las filas de la tabla izquierda, con los valores de la tabla
-- derecha cuando existe correspondencia, y NULL cuando no existe.
-- Se usa cuando interesa conservar todos los registros del lado izquierdo
-- independientemente de si tienen relación en el lado derecho.

-- 2.1. Municipios con y sin faenas registradas
--
-- Pregunta: ¿qué municipios del catálogo nunca han tenido una faena de pesca?
--
-- Se usa LEFT JOIN porque interesa ver TODOS los municipios, incluyendo
-- los que no tienen faenas. Con INNER JOIN los municipios sin faenas
-- desaparecerían del resultado.
-- El filtro WHERE f.faena_id IS NULL aísla los municipios sin ninguna faena.

-- Si la consulta no tiene resultados, todos los municipios tienen faenas
-- -----------------------------------------------------------------------------

select
    distinct
    m.nombre as municipio,
    d.nombre as departamento,
    cu.nombre as cuenca,
    f.id as faena_id   -- null si no tiene faenas
from municipios    m
join departamentos d on d.id = m.departamento_id
join cuencas cu on cu.id = m.cuenca_id
left join faenas f on f.municipio_id = m.id
where f.id is not null
order by cu.nombre, m.nombre;

-- -----------------------------------------------------------------------------
-- 2.2. Faenas con y sin capturas registradas
--
-- Pregunta: ¿hay faenas que no tienen ninguna captura registrada?
--
-- Se usa LEFT JOIN porque interesa conservar todas las faenas, incluso
-- las que no tienen capturas (como la faena 14 en curso).

-- Se usa la función coalesce(expr, valor_alternativo) retorna valor_alternativo 
-- cuando expr es null. Se usa aquí porque sum sobre un conjunto vacío 
-- retorna null y en el dominio "ninguna captura" equivale a 0 kg, 
-- no a dato desconocido.
-- -----------------------------------------------------------------------------
select
    f.id as faena_id,
    emb.matricula,
    m.nombre as municipio,
    f.fecha_salida,
    f.fecha_retorno,
    count(c.id) as total_capturas,
    coalesce(sum(c.cantidad_kg), 0) as total_kg
from faenas f
join embarcaciones emb on emb.id = f.embarcacion_id
join municipios m on m.id = f.municipio_id
left join capturas c on c.faena_id = f.id
where emb.matricula not like 'MIG-%'
group by f.id, emb.matricula, m.nombre, f.fecha_salida, f.fecha_retorno
order by total_capturas, f.fecha_salida;

-- -----------------------------------------------------------------------------
-- 2.3. Tipos de embarcación con y sin embarcaciones registradas
--
-- Pregunta: ¿hay algún tipo de embarcación que aún no tiene
-- ninguna embarcación asociada en el dominio?
-- -----------------------------------------------------------------------------

select
    te.nombre as tipo,
    te.impulsion,
    te.capacidad_personas,
    te.capacidad_carga_kg,
    count(emb.id) as total_embarcaciones
from tipos_embarcacion  te
left join embarcaciones emb on emb.tipo_embarcacion_id = te.id
group by 
    te.nombre, 
    te.impulsion,
    te.capacidad_personas, 
    te.capacidad_carga_kg
order by total_embarcaciones, te.nombre;

-- =============================================================================
-- 3. RIGHT JOIN
--
-- Equivalente al LEFT JOIN pero conservando TODAS las filas de la tabla
-- derecha. En la práctica, todo RIGHT JOIN puede reescribirse como LEFT JOIN
-- invirtiendo el orden de las tablas. Se incluye aquí por completitud y para
-- mostrar que la elección entre LEFT y RIGHT es una decisión de legibilidad.

-- 3.1. Capturas asociadas a cada especie (desde la perspectiva de la especie)

-- Pregunta: ¿qué especies del catálogo no tienen ninguna captura registrada?

-- Se usa RIGHT JOIN para partir desde la tabla especie (lado derecho)
-- y traer las capturas (lado izquierdo) cuando existen.
-- El resultado es equivalente a hacer LEFT JOIN con las tablas invertidas.
-- -----------------------------------------------------------------------------

select
    e.nombre_comun as especie,
    e.nombre_cientifico,
    count(c.id) as total_capturas,
    coalesce(sum(c.cantidad_kg), 0)  as total_kg
from capturas c
right join especies e on e.id = c.especie_id
group by e.nombre_comun, e.nombre_cientifico
order by total_capturas, e.nombre_comun;

-- -----------------------------------------------------------------------------
-- 3.2. La misma consulta reescrita con LEFT JOIN
--
-- Propósito pedagógico: mostrar que las consultas 3.1 y 3.2 producen 
-- exactamente el mismo resultado. 

-- La diferencia es solo el orden de las tablas en la cláusula FROM.
-- En equipos de trabajo es más común usar LEFT JOIN por convención de lectura
-- (la tabla de referencia siempre queda a la izquierda).
-- -----------------------------------------------------------------------------

select
    e.nombre_comun as especie,
    e.nombre_cientifico,
    count(c.id) as total_capturas,
    coalesce(sum(c.cantidad_kg), 0)  as total_kg
from especies e
left join capturas c on c.especie_id = e.id
group by e.nombre_comun, e.nombre_cientifico
order by total_capturas, e.nombre_comun;

-- =============================================================================
-- 4. FULL JOIN
--
-- Combina LEFT JOIN y RIGHT JOIN: retorna TODAS las filas de ambas tablas,
-- con NULL donde no hay correspondencia en el otro lado.
-- Se usa cuando interesa ver el panorama completo de dos conjuntos,
-- incluyendo los elementos sin pareja en cualquiera de los dos lados.

-- 4.1. Embarcaciones y faenas: panorama completo
--
-- Pregunta: ¿existen embarcaciones sin faenas o faenas sin embarcación?
--
-- En el modelo actual las faenas siempre tienen embarcación (NOT NULL),
-- por lo que el FULL JOIN aquí ilustra el concepto sin producir NULLs
-- en el lado derecho. Sin embargo, si se eliminara una embarcación con
-- CASCADE, las faenas podrían quedar huérfanas; FULL JOIN las mostraría.
-- -----------------------------------------------------------------------------

select
    emb.matricula as matricula_embarcacion,
    emb.municipio_id as municipio_base_embarcacion_id,
    f.id as faena_id,
    f.fecha_salida
from embarcaciones emb
full join faenas f on f.embarcacion_id = emb.id
where emb.matricula not like 'MIG-%'
   or emb.matricula is null
order by emb.matricula nulls last, f.fecha_salida;


-- 4.2. Cuencas y especies: distribución completa
--
-- Pregunta: ¿qué cuencas no tienen especies asignadas y qué especies
-- no tienen cuenca asignada?
--
-- Se usa FULL JOIN para ver ambos lados del vacío simultáneamente.
-- En el modelo actual ambos catálogos deberían estar completamente
-- cruzados via especie_cuenca; esta consulta lo verifica.
-- -----------------------------------------------------------------------------

select
    cu.nombre as cuenca,
    e.nombre_comun as especie,
    ec.es_nativa
from cuencas cu
full join especies_cuencas ec on ec.cuenca_id  = cu.id
full join especies e on e.id = ec.especie_id
order by cu.nombre, e.nombre_comun;


-- =============================================================================
-- 5. CROSS JOIN
--
-- Produce el producto cartesiano: cada fila de la tabla izquierda se combina
-- con cada fila de la tabla derecha. Si la tabla A tiene M filas y la tabla B
-- tiene N filas, el resultado tiene M × N filas.
--
-- No se usa para consultas cotidianas de negocio; sus casos de uso típicos
-- son la generación de combinaciones para análisis de escenarios, pruebas
-- de carga o generación de datos.

-- 5.1. Todas las combinaciones posibles de cuenca y método de pesca
--
-- Pregunta: ¿cuántas combinaciones distintas de cuenca y método existen
-- en el catálogo? (sin importar si alguna combinación ocurrió realmente)
--
-- El CROSS JOIN produce todas las combinaciones posibles. La consulta
-- que sigue a este bloque (5.2) compara este total contra las combinaciones
-- que sí tienen capturas registradas.
-- -----------------------------------------------------------------------------

select
    cu.nombre as cuenca,
    mt.nombre  as metodo
from cuencas cu
cross join metodos_pesca mt
order by cu.nombre, mt.nombre;

-- -----------------------------------------------------------------------------
-- E2. Combinaciones cuenca-método con y sin capturas registradas
--
-- Propósito: contrastar el universo de combinaciones posibles (CROSS JOIN)
-- con las que realmente ocurrieron en el dominio.
-- Se usa LEFT JOIN sobre el resultado del CROSS JOIN para identificar
-- cuáles combinaciones no tienen ninguna captura.
-- -----------------------------------------------------------------------------

select
    cu.nombre as cuenca,
    mt.nombre as metodo,
    count(c.id) as total_capturas
from cuencas cu
cross join metodos_pesca mt
left join municipios m on m.cuenca_id   = cu.id
left join faenas f on f.municipio_id = m.id
left join capturas c on c.faena_id    = f.id
                      and c.metodo_id  = mt.id
group by cu.nombre, mt.nombre
order by total_capturas, cu.nombre, mt.nombre;

-- =============================================================================
-- 6. JOINs encadenados (múltiples tablas)
--
-- Las consultas de negocio reales raramente involucran solo dos tablas.
-- Esta sección muestra cómo encadenar varios JOINs para responder preguntas
-- que atraviesan múltiples entidades del dominio.
--
-- Regla de escritura: se declara cada JOIN en una línea propia con su
-- condición ON inmediatamente después, en el mismo orden en que las tablas
-- se relacionan lógicamente. Esto hace el código legible y fácil de depurar.

-- 6.1. Cadena completa: captura → faena → embarcación → tipo → municipio → cuenca
--
-- Pregunta: ¿cuántos kg totales capturó cada tipo de embarcación por cuenca?
-- -----------------------------------------------------------------------------

select
    te.nombre                        as tipo_embarcacion,
    cu.nombre                        as cuenca,
    count(c.id)              as total_capturas,
    round(sum(c.cantidad_kg), 2)     as total_kg,
    round(avg(c.cantidad_kg), 2)     as promedio_kg
from capturas          c
join faenas            f   on f.id            = c.faena_id
join embarcaciones      emb on emb.id    = f.embarcacion_id
join tipos_embarcacion te  on te.id = emb.tipo_embarcacion_id
join municipios        m   on m.id         = f.municipio_id
join cuencas           cu  on cu.id           = m.cuenca_id
where emb.matricula not like 'MIG-%'
group by te.nombre, cu.nombre
order by cu.nombre, total_kg desc;

-- 6.2. Cadena completa: pescador → faena_pescador → faena → captura → especie
--
-- Pregunta: ¿cuáles son las tres especies más capturadas por cada pescador
-- en las faenas reales (no de migración)?
-- -----------------------------------------------------------------------------

select
    p.id as pescador_id,
    mp.nombre as municipio_base,
    e.nombre_comun as especie,
    count(c.id) as veces_capturada,
    round(sum(c.cantidad_kg), 2) as total_kg
from pescadores p
join municipios  mp on mp.id = p.municipio_id
join faenas_pescadores fp on fp.pescador_id = p.id
join faenas f on f.id = fp.faena_id
join embarcaciones emb on emb.id = f.embarcacion_id
join capturas c on c.faena_id = f.id
                and c.pescador_id = p.id
join especies e on e.id = c.especie_id
where emb.matricula not like 'MIG-%'
group by p.id, mp.nombre, e.id, e.nombre_comun
order by p.id, total_kg desc;

-- -----------------------------------------------------------------------------
-- F3. Faenas en curso con detalle de participantes y capturas parciales
--
-- Pregunta: ¿cuál es el estado actual de las faenas en curso: quiénes
-- participan y qué han capturado hasta ahora?
--
-- Se usa LEFT JOIN desde faena hacia captura para incluir la faena 14
-- (Nuquí, sin capturas aún) en el resultado.
-- -----------------------------------------------------------------------------

select
    f.id as faena_id,
    emb.matricula,
    te.nombre as tipo_embarcacion,
    m.nombre as municipio_zarpe,
    f.fecha_salida,
    f.fecha_retorno,
    p.id as pescador_id,
    mp.nombre as municipio_pescador,
    e.nombre_comun as especie_capturada,
    c.cantidad_kg,
    c.fecha_hora as hora_captura
from faenas f
join embarcaciones emb on emb.id = f.embarcacion_id
join tipos_embarcacion  te on te.id = emb.tipo_embarcacion_id
join municipios m on m.id = f.municipio_id
join faenas_pescadores fp on fp.faena_id = f.id
join pescadores p on p.id = fp.pescador_id
join municipios  mp on mp.id = p.municipio_id
left join capturas c on c.faena_id = f.id
                    and c.pescador_id = p.id
left join especies e on e.id = c.especie_id
where f.fecha_retorno is null
  and emb.matricula not like 'MIG-%'
order by f.id, p.id, c.fecha_hora;
