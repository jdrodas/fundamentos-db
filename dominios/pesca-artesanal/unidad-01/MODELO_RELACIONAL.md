# Unidad 1 — Fundamentos y diseño de bases de datos relacionales

## Dominio de problema

Este repositorio modela la gestión de información de la **pesca artesanal en Colombia**.
El dominio abarca las cuencas hidrográficas del país, los municipios donde se desarrolla
la actividad, las especies capturadas y su distribución geográfica.

Los datos de referencia provienen de registros reales de actividad pesquera en las
cuencas Caribe, Magdalena, Pacífico y Sinú.

---

## Modelo relacional

### Diagrama

El diagrama completo se encuentra en [`diagrams/modelo-er.svg`](diagrams/modelo-er.svg).

### Entidades y atributos

#### `cuenca`

Representa las cuencas hidrográficas donde se desarrolla la pesca artesanal.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `cuenca_id` | `serial` | `PRIMARY KEY` | Identificador surrogate autoincremental |
| `nombre` | `varchar(100)` | `NOT NULL`, `UNIQUE` | Nombre de la cuenca |
| `descripcion` | `varchar(500)` | | Descripción opcional de la cuenca |
| `registrado_en` | `timestamp` | `NOT NULL`, `DEFAULT now()` | Fecha y hora de creación del registro |

#### `departamento`

Representa los departamentos de Colombia presentes en el dominio.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `departamento_id` | `serial` | `PRIMARY KEY` | Identificador surrogate autoincremental |
| `nombre` | `varchar(100)` | `NOT NULL`, `UNIQUE` | Nombre del departamento |
| `registrado_en` | `timestamp` | `NOT NULL`, `DEFAULT now()` | Fecha y hora de creación del registro |

#### `municipio`

Representa los municipios con actividad pesquera artesanal registrada.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `municipio_id` | `serial` | `PRIMARY KEY` | Identificador surrogate autoincremental |
| `nombre` | `varchar(150)` | `NOT NULL` | Nombre del municipio |
| `departamento_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Referencia al departamento |
| `cuenca_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Referencia a la cuenca principal |
| `registrado_en` | `timestamp` | `NOT NULL`, `DEFAULT now()` | Fecha y hora de creación del registro |

#### `especie`

Representa las especies de peces capturadas en la actividad pesquera artesanal.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `especie_id` | `serial` | `PRIMARY KEY` | Identificador surrogate autoincremental |
| `nombre_comun` | `varchar(150)` | `NOT NULL` | Nombre común de la especie |
| `nombre_cientifico` | `varchar(200)` | `NOT NULL`, `UNIQUE` | Nombre científico en notación binomial |
| `registrado_en` | `timestamp` | `NOT NULL`, `DEFAULT now()` | Fecha y hora de creación del registro |

#### `especie_cuenca`

Tabla puente que resuelve la relación muchos a muchos entre `especie` y `cuenca`.
Una especie puede habitar múltiples cuencas y una cuenca alberga múltiples especies.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `especie_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Referencia a la especie |
| `cuenca_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Referencia a la cuenca |
| `es_nativa` | `boolean` | `NOT NULL`, `DEFAULT true` | Indica si la especie es nativa de esa cuenca |
| `registrado_en` | `timestamp` | `NOT NULL`, `DEFAULT now()` | Fecha y hora de creación del registro |

La clave primaria compuesta es `(especie_id, cuenca_id)`.

---

## Decisiones de diseño

### 1. Claves primarias: surrogate keys en todas las tablas

Se eligió `serial` (entero autoincremental) como clave primaria en todas las tablas
en lugar de claves naturales, por las siguientes razones:

- Los nombres de cuencas, departamentos y municipios pueden cambiar por decisiones
  administrativas o correcciones ortográficas. Una clave natural basada en el nombre
  obligaría a actualizar todas las tablas que la referencian.
- El nombre científico de una especie puede ser revisado taxonómicamente. Aunque se
  agregó una restricción `UNIQUE` sobre `nombre_cientifico`, no se usó como PK por
  la misma razón de estabilidad.
- Las claves surrogate son más eficientes en joins al ser enteros de tamaño fijo.

### 2. Relación municipio → cuenca: clave foránea directa (N:1)

Un municipio pertenece a una sola cuenca principal. Esta decisión refleja la forma
en que se recolectan los datos de actividad pesquera: cada registro de captura se
asocia a un municipio y, a través de él, a una cuenca.

**Caso especial — San Bernardo del Viento:** en los datos fuente este municipio
aparece en dos entradas diferenciadas por zona (continental/Sinú y marino/Caribe).
Se decidió mantenerlo como un único municipio con su cuenca asignada a **Caribe**,
que corresponde a la zona marino donde se concentra la actividad pesquera costera.
La distinción de zona no se modela en esta unidad.

### 3. Relación especie ↔ cuenca: tabla puente `especie_cuenca` (N:M)

Las especies pueden habitar múltiples cuencas. Por ejemplo, el bocachico
(*Prochilodus magdalenae*) está presente en las cuencas Magdalena, Sinú y Caribe.
Almacenar esta información directamente en la tabla `especie` violaría la Primera
Forma Normal al requerir atributos multivaluados.

La tabla `especie_cuenca` resuelve esta relación con una clave primaria compuesta
`(especie_id, cuenca_id)` que garantiza que no se duplique la misma combinación.
El atributo `es_nativa` enriquece la relación con información propia del vínculo
entre especie y cuenca, lo que justifica su existencia como tabla independiente y
no como simple tabla de cruce.

### 4. Normalización

Todas las tablas cumplen la Tercera Forma Normal (3FN):

- **1FN:** todos los atributos son atómicos. No hay grupos repetidos ni atributos
  multivaluados.
- **2FN:** en las tablas con clave primaria simple, todos los atributos dependen
  funcionalmente de la clave completa. En `especie_cuenca`, el atributo `es_nativa`
  depende de la clave compuesta `(especie_id, cuenca_id)`, no de una sola parte.
- **3FN:** no existen dependencias transitivas. El nombre del departamento no se
  almacena en `municipio`; se accede a través de la clave foránea `departamento_id`.

### 5. Tipos de datos

- `varchar` con longitud razonada según el dominio: nombres de municipios hasta 150
  caracteres para acomodar nombres compuestos como "San Bernardo del Viento",
  nombres científicos hasta 200 caracteres.
- `timestamp` con `DEFAULT now()` en todas las tablas como campo de auditoría base.
  Este patrón se consolida en unidades posteriores.
- `boolean` en `especie_cuenca.es_nativa` en lugar de `char(1)` o `integer`
  para expresar semántica binaria con claridad.

---

## Archivos del repositorio

```
unit-01-fundamentos-diseno-relacional/
├── README.md               ← este archivo
├── diagrams/
│   └── modelo-er.svg       ← diagrama relacional
└── scripts/
    ├── 00_schema.sql       ← creación de tablas y restricciones
    └── 01_seed.sql         ← datos de prueba
```

---

## Instrucciones de ejecución

Los scripts están escritos para **PostgreSQL 15 o superior**.

```bash
# Crear la base de datos
createdb pesca_artesanal

# Ejecutar el esquema
psql -d pesca_artesanal -f scripts/00_schema.sql

# Cargar los datos de prueba
psql -d pesca_artesanal -f scripts/01_seed.sql
```

---

## Glosario

| Término | Significado en este dominio |
|---|---|
| Cuenca | Territorio drenado por un río principal y sus afluentes donde se desarrolla la pesca artesanal |
| Especie nativa | Especie que evolucionó naturalmente en una cuenca sin intervención humana en su introducción |
| Nombre científico | Denominación binomial en latín que identifica unívocamente una especie a nivel taxonómico |
| Tabla puente | Tabla que resuelve una relación muchos a muchos entre dos entidades mediante claves foráneas compuestas |
| Clave surrogate | Clave primaria artificial generada por el sistema, sin significado en el dominio del problema |
