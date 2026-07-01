-- =============================================================================
-- Scripts de clase - julio 2026  
-- Curso de Fundamentos de Bases de Datos Relacionales
-- Juan Dario Rodas - jdrodas@hotmail.com

-- Proyecto: Pesca artesanal en Colombia
-- Motor de Base de datos: PostgreSQL 15 o superior

-- Unidad 1 — Fundamentos y diseño de bases de datos relacionales
-- Archivo: 01_seed_postgreSQL.sql

-- Importante:
-- Este script no es para ejecutar de manera autónoma. 
-- El estudiante debe ejecutar cada grupo de instrucciones según la necesidad.

-- Prerequisito: 
-- ejecutar 00_schema_postgreSQL.sql antes de este script.

-- =============================================================================

-- -----------------------------------------------------------------------------
-- Inserción de datos semilla
-- -----------------------------------------------------------------------------

-- 1. cuencas
insert into cuencas (nombre, descripcion) values
    ('Caribe',
     'Cuenca que comprende los ríos y cuerpos de agua que desembocan en el mar caribe colombiano.'),
    ('Magdalena',
     'Cuenca del río magdalena, principal arteria fluvial de colombia y eje de la pesca artesanal continental.'),
    ('Pacífico',
     'Cuenca que comprende los ríos y cuerpos de agua que desembocan en el océano pacífico colombiano.'),
    ('Sinú',
     'Cuenca del río sinú, ubicada en la región caribe colombiana, con importante actividad pesquera artesanal.');

-- 2. departamentos
insert into departamentos (nombre) values
    ('Antioquia'),
    ('Atlántico'),
    ('Bolívar'),
    ('Caldas'),
    ('Cesar'),
    ('Chocó'),
    ('Córdoba'),
    ('Huila'),
    ('La Guajira'),
    ('Magdalena'),
    ('Santander'),
    ('Sucre');

-- 3. municipios
insert into municipios (nombre, departamento_id, cuenca_id)
values  ('Venecia', 1, 2),
        ('Turbo', 1, 1),
        ('San Juan De Urabá', 1, 1),
        ('Necoclí', 1, 1),
        ('Nechí', 1, 2),
        ('Caucasia', 1, 2),
        ('Malambo', 2, 2),
        ('Barranquilla', 2, 1),
        ('Simití', 3, 2),
        ('Santa Cruz De Mompox', 3, 2),
        ('Santa Catalina', 3, 1),
        ('San Jacinto Del Cauca', 3, 2),
        ('Pinillos', 3, 2),
        ('Montecristo', 3, 2),
        ('Magangué', 3, 2),
        ('Córdoba', 3, 2),
        ('Cicuco', 3, 2),
        ('Cartagena De Indias', 3, 1),
        ('Altos Del Rosario', 3, 2),
        ('Achí', 3, 2),
        ('La Dorada', 4, 2),
        ('Tamalameque', 5, 2),
        ('Pelaya', 5, 2),
        ('Chimichagua', 5, 2),
        ('Nuquí', 6, 3),
        ('Juradó', 6, 3),
        ('Bajo Baudó', 6, 3),
        ('Bahía Solano', 6, 3),
        ('Acandí', 6, 1),
        ('Tierralta', 7, 4),
        ('San Bernardo Del Viento', 7, 1),
        ('San Antero', 7, 1),
        ('Momil', 7, 4),
        ('Lorica', 7, 4),
        ('Buenavista', 7, 2),
        ('Ayapel', 7, 2),
        ('Yaguará', 8, 2),
        ('Hobo', 8, 2),
        ('Uribia', 9, 1),
        ('Riohacha', 9, 1),
        ('Manaure', 9, 1),
        ('Dibulla', 9, 1),
        ('Tenerife', 10, 2),
        ('Santa Marta', 10, 1),
        ('Puebloviejo', 10, 1),
        ('El Banco', 10, 2),
        ('Ciénaga', 10, 1),
        ('Puerto Wilches', 11, 2),
        ('Barrancabermeja', 11, 2),
        ('Sucre', 12, 2),
        ('Santiago De Tolú', 12, 1),
        ('San Onofre', 12, 1),
        ('San Marcos', 12, 2),
        ('San Benito Abad', 12, 2),
        ('Galeras', 12, 2),
        ('Caimito', 12, 2);

-- 4. especies
insert into especies (nombre_comun, nombre_cientifico) values
    ('Pargo rojo',      'Lutjanus colorado'),
    ('Corvina',         'Cynoscion reticulatus'),
    ('Jurel',           'Caranx hippos'),
    ('Mero',            'Epinephelus analogus'),
    ('Róbalo',          'Centropomus viridis'),
    ('Sierra',          'Scomberomorus sierra'),
    ('Pargo lunarejo',  'Lutjanus guttatus'),
    ('Cojinoa',         'Caranx crysos'),
    ('Mero guasa',      'Epinephelus itajara'),
    ('Lisa',            'Mugil incilis'),
    ('Bocachico',       'Prochilodus magdalenae'),
    ('Bagre rayado',    'Pseudoplatystoma striatum'),
    ('Nicuro',          'Pimelodus blochii'),
    ('Blanquillo',      'Sorubim lima'),
    ('Mojarra amarilla','Caquetaia kraussii'),
    ('Arenca',          'Triportheus magdalenae'),
    ('Capaz',           'Pimelodus grosskopfii'),
    ('Moncholo',        'Hoplias malabaricus'),
    ('Doncella',        'Ageneiosus pardalis'),
    ('Mapalé',          'Lycengraulis batesii');


-- 5. especies_cuencas
insert into especies_cuencas (especie_id, cuenca_id, es_nativa)
values  (11, 1, false),
        (10, 1, true),
        (9, 1, true),
        (8, 1, true),
        (7, 1, true),
        (6, 1, true),
        (3, 1, true),
        (20, 2, true),
        (19, 2, true),
        (17, 2, true),
        (16, 2, true),
        (15, 2, true),
        (14, 2, true),
        (13, 2, true),
        (12, 2, true),
        (11, 2, true),
        (5, 3, true),
        (4, 3, true),
        (3, 3, true),
        (2, 3, true),
        (1, 3, true),
        (20, 4, true),
        (19, 4, true),
        (18, 4, true),
        (17, 4, true),
        (15, 4, true),
        (13, 4, true),
        (11, 4, true),
        (10, 4, true);

-- -----------------------------------------------------------------------------
-- Validación de restricciones

-- Los siguientes bloques verifican que las restricciones del esquema funcionan
-- correctamente. Cada sentencia debe fallar con un error de integridad.
-- Ejecutar de forma independiente, no dentro de una transacción activa.
-- -----------------------------------------------------------------------------

-- Prueba 1: nombre_cientifico duplicado debe violar especie_nombre_cientifico_uk
-- Resultado esperado: ERROR - duplicate key value violates unique constraint

insert into especies (nombre_comun, nombre_cientifico)
values ('Bocachico de río', 'Prochilodus magdalenae');


-- Prueba 2: municipio con departamento inexistente debe violar municipio_departamento_fk
-- Resultado esperado: ERROR - insert or update on table violates foreign key constraint

insert into municipios (nombre, departamento_id, cuenca_id)
values ('Municipio Ficticio', 9999, 1);


-- Prueba 3: especie_cuenca duplicada debe violar especies_cuencas_pk
-- Resultado esperado: ERROR - duplicate key value violates unique constraint

insert into especies_cuencas (especie_id, cuenca_id)
select especie_id, cuenca_id
from especies_cuencas
limit 1;

-- Prueba 4: municipio con nombre duplicado en el mismo departamento
--           debe violar municipio_nombre_departamento_uk
-- Resultado esperado: ERROR - duplicate key value violates unique constraint

insert into municipios (nombre, departamento_id, cuenca_id)
select nombre, departamento_id, cuenca_id
from municipios
where nombre = 'Turbo';

-- -----------------------------------------------------------------------------
-- Consultas de verificación
--
-- Ejecutar después de la inserción de los datos semilla para confirmar que los datos quedaron correctos.
-- -----------------------------------------------------------------------------

-- ¿Cuántos municipios hay por cuenca?
select c.nombre as cuenca, count(*) as total_municipios
from municipios m
join cuencas c on c.id = m.cuenca_id
group by c.nombre
order by total_municipios desc;

-- ¿En qué cuencas habita el bocachico y es nativa?
select e.nombre_comun, e.nombre_cientifico, c.nombre as cuenca, ec.es_nativa
from especies_cuencas ec
join especies e on e.id = ec.especie_id
join cuencas  c on c.id  = ec.cuenca_id
where e.nombre_cientifico = 'Prochilodus magdalenae'
order by c.nombre;

-- ¿Qué municipios pertenecen a la cuenca del Sinú?
select m.nombre as municipio, d.nombre as departamento
from municipios m
join departamentos d on d.id = m.departamento_id
join cuencas       c on c.id       = m.cuenca_id
where c.nombre = 'Sinú'
order by m.nombre;
