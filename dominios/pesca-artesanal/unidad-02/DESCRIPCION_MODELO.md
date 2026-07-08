# Unidad 2: SQL básico y operaciones de manipulación de datos

## Dominio de problema

Extensión del modelo relacional de pesca artesanal. Esta unidad incorpora las
entidades operativas del dominio: el pescador que realiza la actividad y el método
de pesca utilizado, y la tabla de hechos central que registra cada captura.

Con esta extensión el modelo pasa de ser un conjunto de catálogos de referencia
a un sistema capaz de registrar y consultar actividad pesquera real.

---

## Modelo relacional

### Diagrama

El diagrama actualizado se encuentra en [`diagramas/pesca_artesanal_diagrama_relacional_unidad2.jpg`](diagramas/pesca_artesanal_diagrama_relacional_unidad2.jpg).

### Entidades heredadas de la Unidad 1

Las siguientes tablas se mantienen sin modificaciones estructurales:

- `cuencas`
- `departamentos`
- `municipios`
- `especies`
- `especies_cuencas`

### Entidades nuevas en esta unidad

#### `metodos_pesca`

Catálogo de métodos o artes de pesca utilizados en la actividad artesanal.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador del método |
| `nombre` | `varchar(100)` | `NOT NULL`, `UNIQUE` | Nombre del método de pesca |

#### `pescadores`

Representa a los pescadores artesanales registrados en el dominio. Se almacena
únicamente la información relevante para la actividad pesquera.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador del pescador |
| `municipio_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Municipio donde opera el pescador |

#### `capturas`

Tabla de hechos central del dominio. Registra cada evento de captura artesanal
con sus dimensiones: quién capturó, dónde, qué especie, con qué método, cuánto
y cuándo.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador de la captura |
| `pescador_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Pescador que realizó la captura |
| `municipio_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Municipio donde se realizó la captura |
| `especie_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Especie capturada |
| `metodo_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Método de pesca utilizado |
| `cantidad_kg` | `numeric(8,2)` | `NOT NULL` | Cantidad capturada en kilogramos |
| `fecha_hora` | `timestamp` | `NOT NULL` | Fecha y hora del evento de captura |
| `observaciones` | `varchar(500)` | | Notas opcionales sobre la captura |

---

## Decisiones de diseño

### 1. Pescador sin información personal

Se decidió almacenar únicamente el municipio de operación del pescador. 
No se incluyen atributos de identificación personal como nombre,
cédula, teléfono o fecha de nacimiento. Esta decisión refleja el enfoque del
dominio: el sistema registra actividad pesquera, no gestiona personas. El
pescador es relevante en la medida en que es el actor que realiza capturas.

### 2. Clave primaria subrogada en pescador

Se mantiene el patrón surrogate (`serial`) establecido en la Unidad 1. Aunque
la cédula podría ser una clave natural, no se almacena en este modelo por la
decisión anterior de no guardar información personal.

### 3. captura como tabla de hechos

La tabla `capturas` centraliza las referencias a todas las dimensiones del evento:
pescador, municipio, especie y método. Almacenar los nombres directamente en
`capturas` violaría la Tercera Forma Normal al introducir redundancia y anomalías
de actualización: si el nombre de una especie cambia, habría que actualizarlo
en cada fila de captura en lugar de en un único registro de la tabla `especies`.

### 4. municipio_id en capturas y en pescadores

Un pescador opera habitualmente desde un municipio base, pero puede realizar
capturas en municipios distintos. Por esta razón `municipio_id` aparece en
ambas tablas con semánticas diferentes:

- En `pescadores`: municipio donde opera habitualmente el pescador.
- En `capturas`: municipio donde ocurrió el evento de captura específico.

Esta distinción tiene implicaciones de consulta que se explotan en los ejercicios
de agrupamiento de la unidad.

### 5. cantidad_kg con tipo numeric(8,2)

Se usa `numeric(8,2)` en lugar de `float` o `real` para evitar errores de
redondeo en aritmética de punto flotante. Las capturas se expresan en kilogramos
con dos decimales de precisión, lo que es suficiente para el dominio y garantiza
resultados aceptables en sumas y promedios.

### 6. Decisión pendiente de refactorización: faena

En esta unidad `capturas` referencia directamente a `pescadores` y `municipios`.
Esta estructura es suficiente para los objetivos de la Unidad 2 pero tiene una
limitación conocida: no modela el hecho de que múltiples pescadores pueden
participar en una misma salida de pesca, ni agrupa las capturas por viaje.

Esta limitación se resuelve intencionalmente en la Unidad 3 con la introducción
de la entidad `faenas`, lo que implica refactorizar `capturas` eliminando
`pescador_id` y `municipio_id` directamente y reemplazándolos por `faena_id`.
Este ejercicio de refactorización tardía ilustra las consecuencias de decisiones
de diseño tomadas sin anticipar todos los requerimientos del dominio.

### 7. Normalización

Todas las tablas nuevas cumplen la Tercera Forma Normal (3FN):

- **metodos_pesca:** tabla de catálogo con un único atributo no clave. No hay
  dependencias transitivas posibles.
- **pescadores:** `municipio_id` depende directamente de `pescador_id`. No hay
  atributos que dependan de `municipio_id` en esta tabla.
- **capturas:** todos los atributos (`cantidad_kg`, `fecha_hora`, `observaciones`)
  describen el evento de captura identificado por `captura_id`. Las dimensiones
  se acceden a través de claves foráneas, no por atributos derivados almacenados.

---

## Glosario

| Término | Significado en este dominio |
|---|---|
| Tabla de hechos | Tabla central que registra eventos del dominio con referencias a todas sus dimensiones mediante claves foráneas |
| DML | Data Manipulation Language: conjunto de instrucciones SQL para insertar, actualizar y eliminar datos |
| Función agregada | Función que opera sobre un conjunto de filas y retorna un único valor resumen: SUM, AVG, COUNT, MAX, MIN |
| GROUP BY | Cláusula que agrupa filas según los valores de uno o más atributos para aplicar funciones agregadas por grupo |
| HAVING | Cláusula que filtra grupos resultantes de GROUP BY, equivalente a WHERE pero aplicado después de la agregación |
| numeric(p,s) | Tipo de dato de precisión exacta con p dígitos totales y s decimales, preferible a float para valores monetarios o de peso |