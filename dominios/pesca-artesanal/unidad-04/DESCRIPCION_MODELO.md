# Unidad 4 — Lógica almacenada

## Dominio de problema

Extensión del modelo relacional de pesca artesanal. Esta unidad incorpora la
capacidad de encapsular reglas de negocio directamente en la base de datos:
vedas de especies por cuenca y período, control de capacidad operativa de las
embarcaciones, y trazabilidad automática de cambios sobre las capturas.

El modelo estructural crece con dos tablas nuevas. El grueso del trabajo de
esta unidad, sin embargo, está en la lógica programable: funciones escalares
y de tabla, procedimientos almacenados que orquestan validaciones antes de
insertar, actualizar o eliminar datos, y triggers de auditoría automática.

---

## Modelo relacional

### Diagrama

El diagrama actualizado se encuentra en [`diagramas/pesca_artesanal_diagrama_relacional_unidad4.jpg`](diagramas/pesca_artesanal_diagrama_relacional_unidad4.jpg).

### Entidades heredadas sin modificaciones estructurales

- `cuencas`, `departamentos`, `municipios`, `especies`, `especies_cuenca` (U1)
- `metodos_pesca`, `pescadores`, `capturas` (U2)
- `tipos_embarcacion`, `embarcaciones`, `faenas`, `faenas_pescadores` (U3)

### Entidades nuevas en esta unidad

#### `vedas`

Registra los períodos en que una especie no puede capturarse, ya sea a nivel
nacional o restringido a una cuenca específica.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador de la veda |
| `especie_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Especie sujeta a veda |
| `cuenca_id` | `integer` | `FOREIGN KEY`, nullable | Cuenca donde aplica la veda. `NULL` indica veda nacional |
| `fecha_inicio` | `date` | `NOT NULL` | Fecha de inicio del período de veda |
| `fecha_fin` | `date` | `NOT NULL` | Fecha de fin del período de veda |
| `descripcion` | `varchar(300)` | | Motivo o contexto de la veda |

#### `auditoria_capturas

Registra automáticamente cada inserción y actualización sobre `captura`,
permitiendo reconstruir el historial de cambios.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador del evento de auditoría |
| `captura_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Captura afectada |
| `operacion` | `varchar(10)` | `NOT NULL`, `CHECK IN ('INSERT','UPDATE')` | Tipo de operación registrada |
| `cantidad_kg_anterior` | `numeric(8,2)` | | Valor previo de `cantidad_kg`. `NULL` en INSERT |
| `cantidad_kg_nueva` | `numeric(8,2)` | `NOT NULL` | Valor de `cantidad_kg` después de la operación |
| `modificado_en` | `timestamp` | `NOT NULL`, `DEFAULT now()` | Fecha y hora del cambio |
| `usuario_bd` | `varchar(100)` | `NOT NULL` | Usuario de PostgreSQL que ejecutó la operación |

---

## Decisiones de diseño

### 1. Veda regional mediante cuenca_id nullable

En Colombia las vedas pesqueras suelen tener alcance regional: por ejemplo, la
veda del bagre rayado en la cuenca del Magdalena rige del 1 al 30 de mayo y del
15 de septiembre al 15 de octubre, pero no necesariamente aplica igual en otras
cuencas. Se modela `cuenca_id` como columna nullable en lugar de crear una tabla
de intersección `veda_cuenca`, porque en este dominio una veda aplica a una sola
cuenca a la vez o a todas (nacional); no existe el caso de una veda que aplique
a un subconjunto específico de varias cuencas.

### 2. Separación de responsabilidades: procedimientos vs. triggers

Esta unidad distingue deliberadamente dos mecanismos de lógica almacenada con
propósitos distintos:

- **Procedimientos almacenados** encapsulan las reglas de negocio que dependen
  de la operación que se está realizando: verificar veda vigente, capacidad de
  carga disponible, o pertenencia del pescador a la faena. Estas validaciones
  se invocan explícitamente al llamar al procedimiento, lo que hace visible en
  el código de la aplicación que la validación está ocurriendo.

- **Triggers** se reservan para la auditoría, que por definición debe ser
  automática e inevitable: sin importar si el cambio sobre `capturas` llega a
  través del procedimiento `p_actualizar_captura` o mediante un `UPDATE` directo,
  el trigger `AFTER UPDATE` garantiza que quede registro. Esta es la diferencia
  conceptual clave entre ambos mecanismos, pues mientras los procedimientos son invocación
  explícita y opcional, los triggers son reacción automática e inevitable.

Esta separación es una decisión de diseño real en la industria, donde se evidencia
que hay sistemas que centralizan toda la validación en triggers `BEFORE` para 
hacerla inevitable incluso ante accesos directos a la tabla, mientras que otros 
la centralizan en procedimientos para mantenerla visible y testeable. 
Ambos enfoques tienen trade-offs válidos.

### 3. Funciones de tabla como complemento a las funciones escalares

Además de funciones escalares (que retornan un único valor), esta unidad
introduce funciones de tabla, que retornan un conjunto de filas y pueden
usarse en la cláusula `FROM` como si fueran una tabla. Se incluyen dos
funciones de tabla con propósitos distintos:

- `f_capturas_de_faena(faena_id)`: retorna el detalle de capturas de una faena.
  Encapsula un JOIN que de otro modo se repetiría en múltiples reportes.
- `f_pescadores_disponibles_para_faena(faena_id)`: retorna los pescadores que
  aún podrían sumarse a una faena sin exceder `capacidad_personas`. Es una
  función de tabla con lógica de negocio propia, no solo un JOIN simple.

Las funciones de tabla se diferencian de las vistas (Unidad 3) en que aceptan
parámetros: una vista siempre representa la misma consulta, mientras que una
función de tabla puede parametrizar su resultado según los argumentos recibidos.

### 4. auditoria_captura no registra DELETE

La auditoría de esta unidad cubre `INSERT` y `UPDATE` mediante trigger
automático. El procedimiento `p_eliminar_captura` maneja el caso de `DELETE` de
forma distinta: en lugar de permitir el borrado físico y auditarlo, valida si
la faena ya tiene `fecha_retorno` registrada (faena cerrada) y, de ser así,
rechaza la eliminación sugiriendo una corrección mediante `UPDATE` en su lugar.
Esta decisión refleja una práctica común en sistemas de trazabilidad: preferir
la corrección auditable sobre el borrado, cuando el dato ya forma parte de un
registro cerrado.

### 5. usuario_bd en auditoria_captura

Se registra el usuario de PostgreSQL que ejecuta la operación (`current_user`)
en lugar de un `pescador_id` o identificador de aplicación, porque en este
dominio la auditoría busca trazabilidad técnica de quién tocó la base de datos,
no trazabilidad de negocio de quién capturó el pez (esa información ya vive en
`capturas.pescador_id`).

---

## Lógica almacenada implementada

### Funciones escalares

| Función | Firma | Retorna | Propósito |
|---|---|---|---|
| `f_esta_en_veda` | `(especie_id integer, cuenca_id integer, fecha date)` | `boolean` | Determina si una especie está vedada en una cuenca en una fecha dada |
| `f_calcula_capacidad_disponible` | `(faena_id integer)` | `numeric` | Kg disponibles antes de alcanzar el límite de carga de la embarcación |

### Funciones de tabla

| Función | Firma | Retorna | Propósito |
|---|---|---|---|
| `f_capturas_de_faena` | `(faena_id integer)` | tabla de capturas con detalle | Reporta las capturas de una faena con especie, método y pescador |
| `f_pescadores_disponibles_para_faena` | `(faena_id integer)` | tabla de pescadores | Pescadores que podrían sumarse sin exceder la capacidad de la embarcación |

### Procedimientos almacenados

| Procedimiento | Orquesta | Validaciones antes de actuar |
|---|---|---|
| `p_registra_captura` | `INSERT` en `captura` | Veda vigente, capacidad de carga disponible, pescador pertenece a la faena |
| `p_actualiza_captura` | `UPDATE` en `captura` | Si cambia `cantidad_kg`: capacidad de carga. Si cambia `especie_id`: veda vigente |
| `p_elimina_captura` | `DELETE` en `captura` | Rechaza si la faena ya tiene `fecha_retorno` (faena cerrada) |

### Triggers (auditoría automática)

| Trigger | Evento | Tabla | Acción |
|---|---|---|---|
| `tr_auditoria_captura_insert` | `AFTER INSERT` | `captura` | Inserta registro en `auditoria_captura` con `operacion = 'INSERT'` |
| `tr_auditoria_captura_update` | `AFTER UPDATE` | `captura` | Inserta registro en `auditoria_captura` con `operacion = 'UPDATE'`, capturando `cantidad_kg` anterior y nueva |

---

## Normalización

`veda` y `auditoria_capturas` cumplen la Tercera Forma Normal (3FN):

- **vedas:** todos los atributos (`fecha_inicio`, `fecha_fin`, `descripcion`)
  dependen directamente de `veda_id`. `especie_id` y `cuenca_id` son
  referencias, no datos derivados de otras columnas.
- **auditoria_capturas:** todos los atributos describen el evento de auditoría
  identificado por `id`. No hay dependencias transitivas.

---

## Glosario

| Término | Significado en este dominio |
|---|---|
| Veda | Período durante el cual está prohibido capturar una especie determinada, ya sea a nivel nacional o en una cuenca específica |
| Función escalar | Función que retorna un único valor, integrable directamente en expresiones SQL |
| Función de tabla | Función que retorna un conjunto de filas, utilizable en la cláusula FROM como si fuera una tabla, y que a diferencia de una vista acepta parámetros |
| Procedimiento almacenado | Objeto de base de datos que encapsula una secuencia de instrucciones y lógica de control bajo un nombre reutilizable, invocado explícitamente |
| Trigger | Objeto de base de datos que se ejecuta automáticamente ante eventos de inserción, actualización o eliminación, sin invocación explícita |
| Auditoría | Registro automático e inevitable de los cambios realizados sobre una tabla, independiente del mecanismo que originó el cambio |