-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3 — SQL avanzado
-- Archivo: 03_subqueries_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql 01_seed_postgreSQL.sql de la unidad 3 antes de este script.
-- ejecutar todos los scripts de las unidades 1 y 2.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Subconsultas en WHERE
--
-- Una subconsulta en WHERE filtra las filas del resultado principal según
-- una condición que involucra un conjunto de valores calculados por separado.
-- Se usa cuando el criterio de filtro no puede expresarse directamente
-- como una condición sobre columnas de las tablas del FROM principal.

-- -----------------------------------------------------------------------------
-- 1.1. Capturas de especies que habitan la cuenca Pacífico
--
-- Pregunta: ¿qué capturas corresponden a especies propias del Pacífico?
--
-- La subconsulta produce el conjunto de especie_id que tienen distribución
-- en el Pacífico. El operador IN verifica si cada especie_id de la consulta
-- exterior pertenece a ese conjunto.
-- -----------------------------------------------------------------------------

select
    c.id captura_id,
    c.fecha_hora,
    e.nombre_comun as especie,
    mt.nombre as metodo,
    c.cantidad_kg
from capturas c
    join especies e on e.id  = c.especie_id
    join metodos_pesca mt on mt.id  = c.metodo_id
where c.especie_id in (
    select ec.especie_id
    from  especies_cuencas ec
        join  cuencas cu on cu.id = ec.cuenca_id
    where cu.nombre = 'Pacífico'
)
order by c.fecha_hora;

-- -----------------------------------------------------------------------------
-- 1.2. Pescadores que han participado en más de una faena

-- Pregunta: ¿qué pescadores tienen experiencia en múltiples viajes?

-- La subconsulta cuenta las faenas por pescador y retorna los pescador_id
-- que superan el umbral. El resultado principal muestra el detalle de
-- cada uno de esos pescadores.
-- -----------------------------------------------------------------------------

select
    p.id as pescador_id,
    m.nombre as municipio_base,
    cu.nombre  as cuenca_base
from pescadores  p
    join municipios m  on m.id = p.municipio_id
    join cuencas    cu on cu.id = m.cuenca_id
where p.id in (
    select fp.pescador_id
    from   faenas_pescadores fp
    group  by fp.pescador_id
    having count(fp.faena_id) > 1
)
order by p.id;


-- -----------------------------------------------------------------------------
-- 1.3. Faenas cuya captura total supera el promedio general

-- Pregunta: ¿qué faenas produjeron más kg que el promedio de todas las faenas?

-- La subconsulta escalar calcula el promedio total de kg por faena.
-- La consulta exterior compara cada faena contra ese valor.

-- Nota: una subconsulta escalar retorna exactamente un valor (una fila,
-- una columna). Si retorna más de una fila, PostgreSQL lanza un error.
-- El uso de AVG sobre SUM garantiza que sea escalar.
-- -----------------------------------------------------------------------------

select
    f.id as faena_id,
    emb.matricula,
    m.nombre as municipio,
    f.fecha_salida,
    round(sum(c.cantidad_kg), 2) as total_kg_faena
from faenas f
    join embarcaciones emb on emb.id = f.embarcacion_id
    join municipios m on m.id = f.municipio_id
    join capturas c on c.faena_id = f.id
where emb.matricula not like 'MIG-%'
group by f.id, emb.matricula, m.nombre, f.fecha_salida
having sum(c.cantidad_kg) > (
    select avg(total_por_faena)
    from (
        select sum(c2.cantidad_kg) as total_por_faena
        from capturas c2
            join faenas f2  on f2.id = c2.faena_id
            join embarcaciones e2 on e2.id = f2.embarcacion_id
        where e2.matricula not like 'MIG-%'
        group by c2.faena_id
    ) promedios
)
order by total_kg_faena desc;


-- -----------------------------------------------------------------------------
-- 1.4. Municipios sin ninguna embarcación registrada

-- Pregunta: ¿qué municipios del catálogo no tienen flota pesquera propia?

-- NOT IN es la forma más directa de expresar "no pertenece al conjunto".
-- Se usa aquí como alternativa al LEFT JOIN con IS NULL de la Unidad 2,
-- para mostrar que ambas formas producen el mismo resultado.
-- -----------------------------------------------------------------------------

select
    m.nombre as municipio,
    d.nombre as departamento,
    cu.nombre as cuenca
from municipios m
    join departamentos d on d.id = m.departamento_id
    join cuencas cu on cu.id = m.cuenca_id
where m.id not in (
    select distinct emb.municipio_id
    from   embarcaciones emb
)
order by cu.nombre, m.nombre;

-- =============================================================================
-- 2. Subconsultas en FROM (tablas derivadas)
--
-- Una subconsulta en FROM genera un conjunto de resultados temporal que
-- se trata como si fuera una tabla. Se le asigna un alias y se puede
-- referenciar en el SELECT y WHERE de la consulta exterior.
-- Se usa cuando la pregunta requiere dos pasos de agregación: primero
-- calcular un resumen, luego operar sobre ese resumen.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1. Promedio de kg por faena, agrupado por cuenca
--
-- Pregunta: ¿en qué cuenca las faenas son más productivas en promedio?
--
-- No es posible responder esta pregunta con un solo GROUP BY porque
-- requiere dos niveles: primero sumar kg por faena, luego promediar
-- esas sumas por cuenca. La subconsulta en FROM resuelve el primer nivel.
-- -----------------------------------------------------------------------------

select
    resumen.cuenca,
    count(*) as total_faenas,
    round(avg(resumen.total_kg), 2) as promedio_kg_por_faena,
    round(sum(resumen.total_kg), 2) as total_kg_cuenca
from (
    select
        cu.nombre as cuenca,
        f.id as faena_id,
        sum(c.cantidad_kg) as total_kg
    from faenas f
        join embarcaciones emb on emb.id = f.embarcacion_id
        join municipios m on m.id = f.municipio_id
        join cuencas cu on cu.id = m.cuenca_id
        join capturas c on c.faena_id = f.id
    where emb.matricula not like 'MIG-%'
    group by cu.nombre, f.id
) resumen
group by resumen.cuenca
order by promedio_kg_por_faena desc;

-- -----------------------------------------------------------------------------
-- 2.2. Ranking de pescadores por kg total en faenas reales
--
-- Pregunta: ¿cuáles son los tres pescadores más productivos?
--
-- La subconsulta en FROM agrega primero el total de kg por pescador.
-- La consulta exterior ordena y limita el resultado.
-- Este patrón de dos niveles permite poner ORDER BY y LIMIT sobre
-- un resultado ya agregado, algo que no es posible con un solo SELECT.
-- -----------------------------------------------------------------------------

select
    productividad.pescador_id,
    productividad.municipio_base,
    productividad.total_capturas,
    productividad.total_kg
from (
    select
        p.id as pescador_id,
        m.nombre as municipio_base,
        count(c.id) as total_capturas,
        round(sum(c.cantidad_kg), 2) as total_kg
    from pescadores p
        join municipios m on m.id = p.municipio_id
        join capturas c on c.pescador_id = p.id
        join faenas f on f.id = c.faena_id
        join embarcaciones emb on emb.id = f.embarcacion_id
    where emb.matricula not like 'MIG-%'
    group by p.id, m.nombre
) productividad
order by productividad.total_kg desc
limit 3;

-- -----------------------------------------------------------------------------
-- 2.3. Métodos de pesca con captura por encima y por debajo del promedio
--
-- Pregunta: ¿qué métodos producen capturas por encima del promedio
-- general y cuáles quedan por debajo?
--
-- La subconsulta en FROM calcula el promedio de kg por método.
-- La consulta exterior agrega la comparación contra el promedio general.

-- CASE WHEN evalúa condiciones en orden y retorna el primer valor
-- cuya condición es verdadera. Es el equivalente SQL de un if/else.
-- -----------------------------------------------------------------------------

select
    por_metodo.metodo,
    por_metodo.total_capturas,
    por_metodo.promedio_kg,
    (select round(avg(c2.cantidad_kg), 2)
     from capturas c2) as promedio_general_kg,
    case
        when por_metodo.promedio_kg >
             (select avg(c2.cantidad_kg) from capturas c2)
        then 'por encima del promedio'
        else 'por debajo del promedio'
    end as comparacion
from (
    select
        mt.nombre as metodo,
        count(c.id) as total_capturas,
        round(avg(c.cantidad_kg), 2) as promedio_kg
    from capturas c
        join metodos_pesca mt on mt.id = c.metodo_id
    group by mt.id, mt.nombre
) por_metodo
order by por_metodo.promedio_kg desc;

-- =============================================================================
-- 3. Subconsultas correlacionadas
--
-- Una subconsulta correlacionada referencia una columna de la consulta
-- exterior. A diferencia de las subconsultas no correlacionadas (que se
-- ejecutan una sola vez), una subconsulta correlacionada se ejecuta una
-- vez por cada fila que procesa la consulta exterior.
--
-- Son más costosas en términos de rendimiento que los JOINs equivalentes,
-- pero expresan ciertos tipos de preguntas de forma más natural y directa.
-- Se usan cuando la pregunta requiere comparar cada fila contra un valor
-- calculado específicamente para esa fila.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1. Captura máxima de cada pescador en cada faena
--
-- Pregunta: ¿cuál fue la captura individual más grande que hizo cada
-- pescador en cada faena en la que participó?
--
-- La subconsulta correlacionada referencia c.pescador_id y c.faena_id
-- de la fila actual para calcular el máximo solo dentro de esa
-- combinación pescador-faena.
-- -----------------------------------------------------------------------------

select
    c.id as captura_id,
    c.faena_id,
    c.pescador_id,
    e.nombre_comun as especie,
    c.cantidad_kg
from capturas c
    join especies e on e.id = c.especie_id
where c.cantidad_kg = (
    select max(c2.cantidad_kg)
    from capturas c2
    where c2.pescador_id = c.pescador_id  -- correlación: mismo pescador
      and c2.faena_id = c.faena_id     -- correlación: misma faena
)
order by c.faena_id, c.pescador_id;

-- -----------------------------------------------------------------------------
-- 3.2. Municipios cuya captura total supera a su propio departamento en promedio
--
-- Pregunta: ¿qué municipios producen más que el promedio de los demás
-- municipios de su mismo departamento?
--
-- La subconsulta calcula el promedio de kg de los otros municipios del
-- mismo departamento (excluyendo el municipio actual con <> m.municipio_id).
-- Esto es un cálculo relativo: el umbral cambia para cada municipio
-- según el departamento al que pertenece.
-- -----------------------------------------------------------------------------

select
    m.nombre as municipio,
    d.nombre  as departamento,
    round(sum(c.cantidad_kg), 2) as total_kg
from municipios m
    join departamentos d on d.id  = m.departamento_id
    join faenas f on f.municipio_id = m.id
    join capturas c on c.faena_id = f.id
group by m.id, m.nombre, d.id, d.nombre
having sum(c.cantidad_kg) > (
    select avg(kg_municipio.total)
    from (
        select sum(c2.cantidad_kg) as total
        from   municipios m2
            join   faenas      f2 on f2.municipio_id = m2.id
            join   capturas    c2 on c2.faena_id     = f2.id
        where  m2.departamento_id = d.id    -- correlación: mismo depto
          and  m2.id <> m.id                -- excluye el municipio actual
        group  by m2.id
    ) kg_municipio
)
order by d.nombre, total_kg desc;

-- -----------------------------------------------------------------------------
-- 3.3. Especies capturadas en TODAS las cuencas donde habitan
--
-- Pregunta: ¿hay alguna especie que tenga capturas registradas en todas
-- las cuencas donde su distribución está catalogada?
--
-- La subconsulta correlacionada cuenta cuántas cuencas tiene catalogadas
-- la especie (según especie_cuenca). La consulta exterior cuenta en cuántas
-- cuencas distintas esa especie tiene capturas reales. Cuando ambos números
-- coinciden, la especie tiene presencia completa en el dominio registrado.
-- -----------------------------------------------------------------------------

select
    e.nombre_comun as especie,
    e.nombre_cientifico,
    count(distinct m.cuenca_id) as cuencas_con_captura,
    (
        select count(*)
        from   especies_cuencas ec2
        where  ec2.especie_id = e.id  -- correlación: misma especie
    ) as cuencas_catalogadas
from especies e
    join capturas c on c.especie_id = e.id
    join faenas f  on f.id = c.faena_id
    join municipios m on m.id = f.municipio_id
group by e.id, e.nombre_comun, e.nombre_cientifico
having count(distinct m.cuenca_id) = (
    select count(*)
    from   especies_cuencas ec3
    where  ec3.especie_id = e.id  -- correlación: misma especie
)
order by e.nombre_comun;
