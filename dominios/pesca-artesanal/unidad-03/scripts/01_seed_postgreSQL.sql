-- =============================================================================
-- Scripts de clase - julio 2026 
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 3 — SQL avanzado
-- Archivo: 01_seed_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql de la unidad 3 antes de este script.
-- ejecutar todos los scripts de las unidades 1 y 2.

-- Propósito:
-- Este script inserta datos de prueba NUEVOS y representativos del dominio
-- extendido, distintos de las embarcaciones sintéticas 'MIG-XXXX' creadas
-- durante la refactorización. El objetivo es tener faenas reales con
-- múltiples pescadores y capturas variadas para ejercitar JOINs,
-- subconsultas y CTEs en los scripts 02, 03 y 04.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Inserción de datos semilla
-- -----------------------------------------------------------------------------

-- 1. tipos_embarcacion
insert into tipos_embarcacion (nombre, impulsion, capacidad_personas, capacidad_carga_kg) values
    ('Canoa artesanal',     'remo',  2, 80.00),
    ('Lancha pequeña',      'motor', 4, 250.00),
    ('Bote motor mediano',  'motor', 6, 500.00);

-- 2. embarcaciones
insert into embarcaciones (matricula, tipo_embarcacion_id, municipio_id)
select v.matricula, te.id, m.id
from (values
    ('CART-001', 'Lancha pequeña',     'Cartagena De Indias'),
    ('CART-002', 'Bote motor mediano', 'Cartagena De Indias'),
    ('STA-001',  'Canoa artesanal',    'Santa Marta'),
    ('STA-002',  'Lancha pequeña',     'Santa Marta'),
    ('MAG-001',  'Canoa artesanal',    'Magangué'),
    ('MAG-002',  'Lancha pequeña',     'Magangué'),
    ('LOR-001',  'Canoa artesanal',    'Lorica'),
    ('TUM-001',  'Canoa artesanal',    'Juradó'),
    ('NUQ-001',  'Lancha pequeña',     'Nuquí'),
    ('BSO-001',  'Bote motor mediano', 'Bahía Solano')
) as v (matricula, nombre_tipo, nombre_municipio)
join tipos_embarcacion te on te.nombre  = v.nombre_tipo
join municipios        m  on m.nombre   = v.nombre_municipio;

-- 3. faenas
insert into faenas (embarcacion_id, municipio_id, fecha_salida, fecha_retorno)
select e.id, e.municipio_id, v.fecha_salida, v.fecha_retorno
from (values
    ('CART-001', '2026-04-01 05:00:00'::timestamp, '2026-04-01 14:00:00'::timestamp),
    ('CART-002', '2026-04-02 04:30:00'::timestamp, '2026-04-04 18:00:00'::timestamp),
    ('STA-001',  '2026-04-01 06:00:00'::timestamp, '2026-04-01 13:30:00'::timestamp),
    ('STA-002',  '2026-04-03 05:15:00'::timestamp, '2026-04-03 16:45:00'::timestamp),
    ('MAG-001',  '2026-04-01 05:30:00'::timestamp, '2026-04-01 12:00:00'::timestamp),
    ('MAG-002',  '2026-04-04 06:00:00'::timestamp, '2026-04-05 10:00:00'::timestamp),
    ('LOR-001',  '2026-04-02 05:00:00'::timestamp, '2026-04-02 11:30:00'::timestamp),
    ('TUM-001',  '2026-04-01 04:45:00'::timestamp, '2026-04-01 12:15:00'::timestamp),
    ('NUQ-001',  '2026-04-03 05:00:00'::timestamp, '2026-04-03 17:00:00'::timestamp),
    ('BSO-001',  '2026-04-05 04:00:00'::timestamp, '2026-04-07 20:00:00'::timestamp),
    ('CART-001', '2026-04-08 05:00:00'::timestamp, '2026-04-08 14:30:00'::timestamp),
    ('STA-002',  '2026-04-09 05:30:00'::timestamp, '2026-04-09 15:00:00'::timestamp),
    ('MAG-001',  '2026-04-10 06:00:00'::timestamp, NULL),  -- faena en curso
    ('NUQ-001',  '2026-04-10 05:30:00'::timestamp, NULL),  -- faena en curso
    ('BSO-001',  '2026-04-11 04:30:00'::timestamp, NULL)   -- faena en curso
) as v (matricula, fecha_salida, fecha_retorno)
join embarcaciones e on e.matricula = v.matricula;

-- 4. faenas_pescadores
--
-- Participación de pescadores en cada faena. Se distribuyen entre 1 y 4
-- pescadores por faena, usando pescadores cuyo municipio base coincide
-- con el municipio de la faena cuando es posible; cuando el municipio no
-- tiene pescadores propios, se usan pescadores de municipios de la misma
-- cuenca.


-- Faena 1 (cartagena, 2026-04-01): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-01 05:00:00';

-- Faena 2 (Cartagena, 2026-04-02 a 04): 1 pescador (faena larga, tripulación mínima)
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'CART-002' and f.fecha_salida = '2026-04-02 04:30:00'
limit 1;

-- Faena 3 (Santa Marta, 2026-04-01): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'STA-001' and f.fecha_salida = '2026-04-01 06:00:00'
limit 1;

-- Faena 4 (Santa Marta, 2026-04-03): 3 pescadores
-- Santa Marta no tiene pescadores propios en el seed de la Unidad 2,
-- por lo que se asignan pescadores de municipios de la misma cuenca (Caribe).
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join municipios fm on fm.id = f.municipio_id
join municipios pm on pm.cuenca_id    = fm.cuenca_id
join pescadores  p  on p.municipio_id  = pm.id
where f.fecha_salida = '2026-04-03 05:15:00'
order by p.id
limit 3;

-- Faena 5 (Magangué, 2026-04-01): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'MAG-001' and f.fecha_salida = '2026-04-01 05:30:00'
limit 2;

-- Faena 6 (Magangué, 2026-04-04 a 05): 4 pescadores
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join municipios fm on fm.id = f.municipio_id
join municipios pm on pm.cuenca_id    = fm.cuenca_id
join pescadores  p  on p.municipio_id  = pm.id
where f.fecha_salida = '2026-04-04 06:00:00'
order by p.id
limit 4;

-- Faena 7 (Lorica, 2026-04-02): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'LOR-001' and f.fecha_salida = '2026-04-02 05:00:00'
limit 1;

-- Faena 8 (Juradó, 2026-04-01): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.id   = e.municipio_id
where e.matricula = 'TUM-001' and f.fecha_salida = '2026-04-01 04:45:00'
limit 2;

-- Faena 9 (Nuquí, 2026-04-03): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'NUQ-001' and f.fecha_salida = '2026-04-03 05:00:00'
limit 2;

-- Faena 10 (Bahía Solano, 2026-04-05 a 07): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'BSO-001' and f.fecha_salida = '2026-04-05 04:00:00'
limit 3;

-- Faena 11 (Cartagena, 2026-04-08): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'CART-001' and f.fecha_salida = '2026-04-08 05:00:00'
limit 1;

-- Faena 12 (Santa Marta, 2026-04-09): 2 pescadores
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join municipios fm on fm.id = f.municipio_id
join municipios pm on pm.cuenca_id    = fm.cuenca_id
join pescadores  p  on p.municipio_id  = pm.id
where f.fecha_salida = '2026-04-09 05:30:00'
order by p.id
limit 2;

-- Faena 13 (Magangué, en curso desde 2026-04-10): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'MAG-001' and f.fecha_salida = '2026-04-10 06:00:00'
limit 2;

-- Faena 14 (Nuquí, en curso desde 2026-04-10): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'NUQ-001' and f.fecha_salida = '2026-04-10 05:30:00'
limit 1;

-- Faena 15 (Bahía Solano, en curso desde 2026-04-11): 1 pescador
insert into faenas_pescadores (faena_id, pescador_id)
select f.id, p.id
from faenas f
join embarcaciones e on e.id = f.embarcacion_id
join pescadores    p on p.municipio_id   = e.municipio_id
where e.matricula = 'BSO-001' and f.fecha_salida = '2026-04-11 04:30:00'
limit 3;

-- 5. capturas
--
-- Capturas asociadas a las faenas anteriores. Para ilustrar que distintos
-- pescadores de una misma faena pueden capturar especies y usar métodos
-- diferentes, cada captura se inserta como una sentencia independiente
-- que identifica explícitamente la faena, el pescador (mediante OFFSET
-- sobre la lista ordenada de participantes) y los datos de la captura.
--
-- Convención: cuando una faena tiene varios pescadores, se selecciona
-- cada uno con:
--   SELECT pescador_id FROM faena_pescador
--   WHERE faena_id = <id de la faena>
--   ORDER BY pescador_id
--   OFFSET <posición, empezando en 0> LIMIT 1
--
-- Esto asigna de forma determinística el primer, segundo, tercer (etc.)
-- pescador de la faena a cada captura, sin usar funciones de ventana.
-- -----------------------------------------------------------------------------

-- Faena 1 (Cartagena, 1 pescador):
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Bocachico')              as especie_id,
    (select id from metodos_pesca where nombre = 'Chinchorro')              as metodo_id,
    12.50                                                                   as cantidad_kg, 
    '2026-04-01 09:00:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-01 05:00:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'CART-001');

-- Faena 2 (Cartagena, 1 pescador, faena larga): múltiples capturas del mismo pescador
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Pargo lunarejo')         as especie_id,
    (select id from metodos_pesca where nombre = 'Palangre')                as metodo_id,
    15.20                                                                   as cantidad_kg,
    '2026-04-02 09:00:00'                                                   as fecha_hora
from faenas f       
where f.fecha_salida = '2026-04-02 04:30:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'CART-002');

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Mero guasa')             as especie_id,
    (select id from metodos_pesca where nombre = 'Palangre')                as metodo_id,
    18.40                                                                   as cantidad_kg, 
    '2026-04-03 08:30:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-02 04:30:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'CART-002');

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Cojinoa')                as especie_id,
    (select id from metodos_pesca where nombre = 'Red')                     as metodo_id,
    11.10                                                                   as cantidad_kg, 
    '2026-04-04 07:45:00'                                                   as fecha_hora
from faenas f       
where f.fecha_salida = '2026-04-02 04:30:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'CART-002');  

-- Faena 3 (Santa Marta, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Sierra')                 as especie_id,
    (select id from metodos_pesca where nombre = 'Chinchorro')              as metodo_id,
    9.80                                                                    as cantidad_kg, 
    '2026-04-01 09:30:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-01 06:00:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'STA-001');

-- Faena 4 (Santa Marta, 3 pescadores): cada uno captura especie distinta
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Lisa')                   as especie_id,
    (select id from metodos_pesca where nombre = 'Buceo')                   as metodo_id,
    6.70                                                                    as cantidad_kg, 
    '2026-04-03 09:00:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-03 05:15:00';

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 1 limit 1),
    (select id from especies where nombre_comun = 'Mero guasa')             as especie_id,
    (select id from metodos_pesca where nombre = 'Linea de mano')           as metodo_id,
    9.50                                                                    as cantidad_kg, 
    '2026-04-03 10:00:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-03 05:15:00';

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 2 limit 1),
    (select id from especies where nombre_comun = 'Bocachico')              as especie_id,
    (select id from metodos_pesca where nombre = 'Atarraya')                as metodo_id,
    7.20                                                                    as cantidad_kg, 
    '2026-04-03 11:00:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-03 05:15:00'; 


-- Faena 5 (Magangué, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Bagre rayado')           as especie_id,
    (select id from metodos_pesca where nombre = 'Linea de mano')           as metodo_id,
    10.30                                                                   as cantidad_kg, 
    '2026-04-01 08:00:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-01 05:30:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'MAG-001');

-- Faena 6 (Magangué, 4 pescadores, faena larga)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Mojarra amarilla')       as especie_id,
    (select id from metodos_pesca where nombre = 'Chinchorro')              as metodo_id,
    14.20                                                                   as cantidad_kg, 
    '2026-04-04 09:00:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-04 06:00:00';

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 1 limit 1),
    (select id from especies where nombre_comun = 'Arenca')                 as especie_id,
    (select id from metodos_pesca where nombre = 'Nasa')                    as metodo_id,
    6.80                                                                    as cantidad_kg, 
    '2026-04-04 09:30:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-04 06:00:00';

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 2 limit 1),
    (select id from especies where nombre_comun = 'Capaz')                  as especie_id,
    (select id from metodos_pesca where nombre = 'Atarraya')                as metodo_id,
    8.90                                                                    as cantidad_kg, 
    '2026-04-04 10:15:00'                                                   as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-04 06:00:00';

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 3 limit 1),
    (select id from especies where nombre_comun = 'Doncella')           as especie_id,
    (select id from metodos_pesca where nombre = 'Palangre')            as metodo_id,
    11.40                                                               as cantidad_kg, 
    '2026-04-05 07:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-04 06:00:00';  

-- Faena 7 (Lorica, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Lisa')               as especie_id,
    (select id from metodos_pesca where nombre = 'Ballestilla')         as metodo_id,
    7.40                                                                as cantidad_kg, 
    '2026-04-02 08:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-02 05:00:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'LOR-001');

-- Faena 8 (juradó, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Pargo rojo')         as especie_id,
    (select id  from metodos_pesca where nombre = 'Buceo')              as metodo_id,
    9.10                                                                as cantidad_kg,
    '2026-04-01 07:30:00'                                               as fecha_hora 
from faenas f
where f.fecha_salida = '2026-04-01 04:45:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'TUM-001');  

-- Faena 9 (Nuquí, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Mero')               as especie_id,
    (select id from metodos_pesca where nombre = 'Palangre')            as metodo_id,
    10.60                                                               as captura_kg, 
    '2026-04-03 09:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-03 05:00:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'NUQ-001'); 

-- Faena 10 (Bahía Solano, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Corvina')            as especie_id,
    (select id from metodos_pesca where nombre = 'Arpón')               as metodo_id,
    12.80                                                               as cantidad_kg, 
    '2026-04-05 08:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-05 04:00:00';  

-- Faena 11 (Cartagena, 1 pescador)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Sierra')             as especie_id,
    (select id from metodos_pesca where nombre = 'Chinchorro')          as metodo_id,
    8.90                                                                as cantidad_kg, 
    '2026-04-08 09:15:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-08 05:00:00';

-- Faena 12 (Santa Marta, 2 pescadores)
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Jurel')              as especie_id,
    (select id from metodos_pesca where nombre = 'Palangre')            as metodo_id,
    9.70                                                                as cantidad_kg, 
    '2026-04-09 09:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-09 05:30:00';

insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 1 limit 1),
    (select id from especies where nombre_comun = 'Mero guasa')         as especie_id,
    (select id from metodos_pesca where nombre = 'Atarraya')            as metodo_id,
    11.20                                                               as cantidad_kg, 
    '2026-04-09 10:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-09 05:30:00';

-- Faena 13 (Magangué, en curso): captura parcial registrada
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id as faena_id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Doncella')           as especie_id,
    (select id from metodos_pesca where nombre = 'Nasa')                as metodo_id,
    6.30                                                                as cantidad_kg, 
    '2026-04-10 09:00:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-10 06:00:00'
  and f.embarcacion_id = (select id from embarcaciones where matricula = 'MAG-001');

-- Faena 14 (Nuquí, en curso): sin capturas registradas todavía.
-- Caso intencional: representa una faena recién iniciada sin actividad
-- aún reportada. Es un dato real del dominio, no un faltante del script.  

-- Faena 15 (Bahía Solano, en curso): captura parcial registrada
insert into capturas (faena_id, pescador_id, especie_id, metodo_id, cantidad_kg, fecha_hora)
select
    f.id,
    (select pescador_id from faenas_pescadores
     where faena_id = f.id order by pescador_id offset 0 limit 1),
    (select id from especies where nombre_comun = 'Mero')               as especie_id,
    (select id  from metodos_pesca where nombre = 'Arpón')              as metodo_id,
    8.10                                                                as cantidad_kg, 
    '2026-04-11 08:30:00'                                               as fecha_hora
from faenas f
where f.fecha_salida = '2026-04-11 04:30:00';

-- -----------------------------------------------------------------------------
-- consultas de verificación
-- -----------------------------------------------------------------------------
 
-- ¿cuántas faenas tiene cada embarcación?
select emb.matricula, count(*) as total_faenas
from faenas f
join embarcaciones emb on emb.id = f.embarcacion_id
where emb.matricula not like 'MIG-%'
group by emb.matricula
order by total_faenas desc;

-- ¿qué faenas tienen más de un pescador participante?
select f.id as faena_id, count(*) as total_pescadores
from faenas_pescadores fp
join faenas f on f.id = fp.faena_id
group by f.id
having count(*) > 1
order by total_pescadores desc;
 
-- ¿qué faenas están actualmente en curso (sin fecha_retorno)?
select f.id as faena_id, emb.matricula, m.nombre as municipio, f.fecha_salida
from faenas f
join embarcaciones emb on emb.id = f.embarcacion_id
join municipios   m   on m.id     = f.municipio_id
where f.fecha_retorno is null
order by f.fecha_salida;
