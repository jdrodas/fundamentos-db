-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 5: Transacciones, concurrencia y pruebas
-- Archivo: 01_seed_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisitos: 
-- Haber ejecutado todos los scripts de las Unidades 1, 2, 3 y 4.
-- Haber ejecutado el script 00_schema_postgreSQL.sql de la unidad 5.

-- Propósito:
-- Inserta cuotas de prueba con kg_restante inicial igual a kg_autorizado
-- (ninguna captura previa de las Unidades 2 y 3 se descuenta retroactivamente,
-- porque el concepto de cuota no existía cuando esas capturas se registraron).
-- Los períodos cubren abril y mayo de 2026, coincidiendo con las faenas
-- sembradas en la Unidad 3, para que los procedimientos de 02_transactions_postgreSQL.sql
-- tengan cuotas vigentes contra las cuales operar.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Inserción de datos semilla
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- 1. cuotas_especies

--      Caso 1:
--      - Bocachico / Magdalena: cuota amplia (200 kg) para el caso de éxito
--        estándar en 02_transactions_postgreSQL.sql.

--      Caso 2:
--      - Jurel / Caribe: cuota con kg_restante deliberadamente bajo (12 kg)
--        para poder disparar fácilmente el escenario de "cuota insuficiente"
--        sin necesidad de insertar muchas capturas previas.

--      Caso 3:
--      - Mero guasa / nacional (cuenca_id NULL): coincide con la veda
--        nacional de mero guasa ya sembrada en la Unidad 4 (vigente todo
--        2026). Este caso permite probar que la validación de veda se
--        aplica antes que la de cuota en registrar_captura: una captura de
--        mero guasa debe rechazarse por veda sin siquiera llegar a
--        verificar la cuota.

--      Caso 4:
--      - Sierra / Caribe: cuota con margen amplio (100 kg), reservada como
--        escenario para la demostración de concurrencia en 03_isolation.sql,
--        donde se necesita un valor de kg_restante conocido y sin
--        interferencia de las otras pruebas de este script.

insert into cuotas_especies (especie_id, cuenca_id, periodo_inicio, periodo_fin, kg_autorizado, kg_restante)
select e.id, c.id, v.periodo_inicio, v.periodo_fin, v.kg_autorizado, v.kg_autorizado
from (values
    ('Bocachico',  'Magdalena', '2026-04-01'::date, '2026-05-31'::date, 200.00),
    ('Jurel',      'Caribe',    '2026-04-01'::date, '2026-05-31'::date,  12.00),
    ('Sierra',     'Caribe',    '2026-04-01'::date, '2026-05-31'::date, 100.00)
) as v (nombre_especie, nombre_cuenca, periodo_inicio, periodo_fin, kg_autorizado)
join especies e on e.nombre_comun = v.nombre_especie
join cuencas  c on c.nombre       = v.nombre_cuenca;

-- Cuota nacional de mero guasa (cuenca_id NULL), coincide con la veda
-- nacional ya sembrada en la Unidad 4.
insert into cuotas_especies (especie_id, cuenca_id, periodo_inicio, periodo_fin, kg_autorizado, kg_restante)
select e.id, null, '2026-01-01'::date, '2026-12-31'::date, 300.00, 300.00
from especies e
where e.nombre_comun = 'Mero guasa';


-- -----------------------------------------------------------------------------
-- Consultas de verificación
-- -----------------------------------------------------------------------------

-- Cuotas registradas, con especie y cuenca (NULL = nacional)
select
    e.nombre_comun as especie,
    coalesce(c.nombre, 'Nacional') as alcance,
    ce.periodo_inicio,
    ce.periodo_fin,
    ce.kg_autorizado,
    ce.kg_restante
from cuotas_especies ce
join especies e on e.id = ce.especie_id
left join cuencas c on c.id = ce.cuenca_id
order by ce.periodo_inicio;

-- Confirmar que la cuota de mero guasa coincide con su veda nacional
-- (ambas vigentes todo 2026, sin cuenca específica)
select
    'veda'  as tipo, v.fecha_inicio as inicio, v.fecha_fin as fin
from vedas v
join especies e on e.id = v.especie_id
where e.nombre_comun = 'Mero guasa'
union all
select
    'cuota' as tipo, ce.periodo_inicio, ce.periodo_fin
from cuotas_especies ce
join especies e on e.id = ce.especie_id
where e.nombre_comun = 'Mero guasa';

