## Unidad 3: SQL avanzado

## Dominio de problema

Extensión del modelo relacional de pesca artesanal. Esta unidad incorpora el
contexto operativo de cada captura: la embarcación que realiza el viaje, el tipo
de embarcación con sus capacidades, la faena como unidad de organización del
trabajo pesquero, y la participación de múltiples pescadores en cada faena.

Con esta extensión el modelo refleja la realidad del trabajo artesanal: una
captura no ocurre de forma aislada sino en el marco de un viaje organizado,
con una embarcación específica, desde un municipio determinado, y con la
participación de uno o más pescadores.

---

### Diagrama

El diagrama actualizado se encuentra en [`diagramas/pesca_artesanal_diagrama_relacional_unidad3.jpg`](diagramas/pesca_artesanal_diagrama_relacional_unidad3.jpg).


### Entidades heredadas sin modificaciones

- `cuencas`
- `departamentos`
- `especies`
- `especies_cuencas`
- `metodos_pesca`
- `pescadores`

### Entidad refactorizada

#### `capturas`

La tabla `capturas` pierde `municipio_id` y gana `faena_id`. El municipio donde
ocurrió la captura se obtiene ahora a través de `faena`. El `pescador_id` se
mantiene para preservar la trazabilidad de quién ejecutó cada captura específica.

**Antes (Unidad 2):**

| Columna | Tipo | Restricciones |
|---|---|---|
| `id` | `serial` | `PRIMARY KEY` |
| `pescador_id` | `integer` | `FK NOT NULL` |
| `municipio_id` | `integer` | `FK NOT NULL` ← **se retira** |
| `especie_id` | `integer` | `FK NOT NULL` |
| `metodo_id` | `integer` | `FK NOT NULL` |
| `cantidad_kg` | `numeric(8,2)` | `NOT NULL CHECK > 0` |
| `fecha_hora` | `timestamp` | `NOT NULL` |
| `observaciones` | `varchar(500)` | |

**Después (Unidad 3):**

| Columna | Tipo | Restricciones | Cambio |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | — |
| `faena_id` | `integer` | `FK NOT NULL` | ← **nuevo** |
| `pescador_id` | `integer` | `FK NOT NULL` | — |
| `especie_id` | `integer` | `FK NOT NULL` | — |
| `metodo_id` | `integer` | `FK NOT NULL` | — |
| `cantidad_kg` | `numeric(8,2)` | `NOT NULL CHECK > 0` | — |
| `fecha_hora` | `timestamp` | `NOT NULL` | — |
| `observaciones` | `varchar(500)` | | — |

### Entidades nuevas en esta unidad

#### `tipos_embarcacion`

Catálogo de tipos de embarcación utilizados en la pesca artesanal. Registra
las características operativas que determinan la capacidad de cada tipo.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador del tipo de embarcación| |
| `nombre` | `varchar(100)` | `NOT NULL`, `UNIQUE` | Nombre del tipo de embarcación |
| `impulsion` | `varchar(20)` | `NOT NULL` | Forma de impulsión: `motor` o `remo` |
| `capacidad_personas` | `integer` | `NOT NULL CHECK > 0` | Número máximo de personas a bordo |
| `capacidad_carga_kg` | `numeric(8,2)` | `NOT NULL CHECK > 0` | Capacidad máxima de carga en kilogramos |

#### `embarcaciones`

Representa las embarcaciones individuales registradas en el dominio. Cada
embarcación pertenece a un tipo y opera desde un municipio base.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador surrogate autoincremental |
| `matricula` | `varchar(50)` | `NOT NULL`, `UNIQUE` | Matrícula oficial de la embarcación |
| `tipo_embarcacion_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Tipo de embarcación |
| `municipio_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Municipio donde opera habitualmente |

#### `faenas`

Representa un viaje de pesca organizado. Una faena parte desde un municipio
en una embarcación específica y puede incluir múltiples pescadores y capturas.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador surrogate autoincremental |
| `embarcacion_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Embarcación utilizada |
| `municipio_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Municipio de salida de la faena |
| `fecha_salida` | `timestamp` | `NOT NULL` | Fecha y hora de inicio de la faena |
| `fecha_retorno` | `timestamp` | | Fecha y hora de retorno (NULL si aún en curso) |

#### `faenas_pescadores`

Tabla puente que resuelve la relación N:M entre `faenas` y `pescadores`. Registra
qué pescadores participaron en cada faena.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `faena_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Referencia a la faena |
| `pescador_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Referencia al pescador participante |

La clave primaria compuesta es `(faena_id, pescador_id)`.

---

## Decisiones de diseño

### 1. Refactorización de captura; retiro de municipio_id

En la Unidad 2 `capturas` almacenaba directamente `municipio_id` para registrar
dónde ocurrió el evento. Con la introducción de `faenas`, el municipio es un
atributo de la faena, no de cada captura individual: todas las capturas de una
misma faena ocurren en el mismo municipio de salida.

Mantener `municipio_id` en `capturas` introduciría redundancia y la posibilidad
de inconsistencias: una captura podría registrar un municipio distinto al de su
faena. La refactorización elimina esa anomalía.

La estrategia de refactorización utiliza `ALTER TABLE` para preservar todos los
datos existentes. Ver `00_schema.sql` para el detalle del proceso paso a paso.

### 2. Retención de pescador_id en captura

A diferencia de `municipio_id`, `pescador_id` se mantiene en `capturas` porque
la autoría de cada captura es información propia del evento: dentro de una misma
faena, pescadores distintos pueden capturar especies distintas con métodos
distintos. Sin `pescador_id` en `capturas` sería imposible saber quién atrapó qué.

La tabla `faenas_pescadores` registra quiénes participaron en el viaje; `capturas`
registra quién ejecutó cada acción específica. Son semánticas distintas y
complementarias.

### 3. Validación de capacidades diferida a Unidad 4

`tipo_embarcacion` incluye `capacidad_personas` y `capacidad_carga_kg`. La
validación de que una faena no supera estas capacidades (número de pescadores
en `faena_pescador` ≤ `capacidad_personas`, suma de `cantidad_kg` en `captura`
≤ `capacidad_carga_kg`) requiere lógica que va más allá de restricciones
declarativas simples.

Estas validaciones se implementarán en la Unidad 4 mediante triggers, que es
el mecanismo apropiado para reglas de negocio que involucran múltiples tablas.
En esta unidad el modelo es estructuralmente completo; las reglas se harán
cumplir en la siguiente.

### 4. municipio_id en faena y en embarcacion

Al igual que en la Unidad 2 con `pescador` y `captura`, `municipio_id` aparece
en dos tablas con semánticas distintas:

- En `embarcacion`: municipio donde opera habitualmente la embarcación (puerto base).
- En `faena`: municipio desde donde partió la faena específica.

Una embarcación puede realizar faenas desde municipios distintos a su puerto base,
por lo que ambos atributos son necesarios y no redundantes.

### 5. fecha_retorno nullable en faena

`fecha_retorno` acepta `NULL` para representar faenas en curso. Una faena se
registra al momento de la salida y se actualiza con la fecha de retorno cuando
la embarcación vuelve al puerto. Este patrón es habitual en sistemas de
seguimiento de operaciones con duración variable.

### 6. Normalización

Todas las tablas nuevas cumplen la Tercera Forma Normal (3FN):

- **tipo_embarcacion:** todos los atributos describen el tipo. No hay dependencias
  transitivas.
- **embarcacion:** `matricula`, `tipo_embarcacion_id` y `municipio_id` dependen
  directamente de `embarcacion_id`.
- **faena:** `embarcacion_id`, `municipio_id` y las fechas describen el viaje.
  El municipio de la embarcación no se repite aquí; se accede por JOIN.
- **faena_pescador:** tabla puente con PK compuesta. `registrado_en` es el único
  atributo no clave y depende de la combinación completa `(faena_id, pescador_id)`.

---

## Preguntas de negocio habilitadas por el modelo extendido

```sql
-- ¿Qué faenas tuvieron más de 3 pescadores?
-- ¿Cuántos kg totales cargó cada embarcación en el período?
-- ¿Qué pescador acumula más kg capturados en todas sus faenas?
-- ¿Qué municipios no han registrado ninguna faena?
-- ¿Cuál es el promedio de duración de las faenas por tipo de embarcación?
-- ¿Qué especie es la más capturada en faenas con embarcaciones de motor?
```

Estas preguntas requieren JOINs entre 3 o más tablas, subconsultas correlacionadas
y CTEs, que son los conceptos centrales de esta unidad.

---

## Vistas

Como cierre de la unidad, las consultas más representativas construidas en los
scripts anteriores se encapsulan como vistas (`CREATE VIEW`). Una vista es una
consulta guardada bajo un nombre: no almacena datos propios, sino que ejecuta
su definición cada vez que se consulta. Esto permite reutilizar lógica de JOIN,
subconsultas y CTEs ya validada sin reescribirla en cada análisis nuevo.

Nota de alcance: las vistas de esta unidad son vistas simples. Las vistas
materializadas —que sí almacenan físicamente el resultado y requieren una
estrategia de actualización— se abordan en la Unidad 5, junto con las demás
consideraciones de rendimiento y producción del curso.

### Vistas creadas

| Vista  | Propósito |
|---|---|
| `v_faenas_detalle` | Faena con embarcación, tipo, municipio, departamento y cuenca en una sola consulta |
| `v_productividad_pescador` | Total de capturas y kg por pescador, listo para análisis de ranking |
| `v_ranking_especies_cuenca` | Posición de cada especie dentro de su cuenca según kg capturado |

---

## Glosario

| Término | Significado en este dominio |
|---|---|
| Faena | Viaje de pesca organizado que parte desde un municipio en una embarcación, con uno o más pescadores, y produce una o más capturas |
| Puerto base | Municipio donde opera habitualmente una embarcación, que puede diferir del municipio de salida de cada faena |
| JOIN | Operación SQL que combina filas de dos o más tablas basándose en una condición de relación entre ellas |
| Subconsulta correlacionada | Subconsulta que referencia columnas de la consulta exterior y se ejecuta una vez por cada fila procesada |
| CTE | Common Table Expression: expresión de tabla temporal definida con WITH que existe únicamente durante la ejecución de la consulta que la contiene |
| Función de ventana | Función SQL que realiza cálculos sobre un conjunto de filas relacionadas con la fila actual sin colapsar el resultado en un único valor. |
| Vista | Consulta guardada bajo un nombre, que se ejecuta cada vez que se referencia. No almacena datos propios |