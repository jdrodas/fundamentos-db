# Unidad 5: Transacciones, concurrencia y pruebas
## Dominio de problema

Extensión final del modelo relacional de pesca artesanal. Esta unidad incorpora
el control de cuotas de captura por especie y período: un límite de kg
autorizados que debe respetarse incluso cuando múltiples inspectores o sistemas
intentan registrar capturas simultáneamente contra el mismo límite.

Este es el escenario transaccional de cierre del curso: verificar cuota
disponible y descontarla debe ser una operación atómica, protegida contra
condiciones de carrera. El modelo estructural crece con una sola tabla nueva;
el trabajo central de la unidad está en las propiedades ACID, el control de
concurrencia y las pruebas que validan ambos.

---

## Modelo relacional

### Diagrama

El diagrama completo se encuentra en [`diagramas/pesca_artesanal_diagrama_relacional_unidad5.jpg`](diagramas/pesca_artesanal_diagrama_relacional_unidad5.jpg).


### Entidades heredadas sin modificaciones estructurales

Todo el modelo de las Unidades 1 a 4: `cuencas`, `departamentos`, `municipios`,
`especies`, `especiess_cuencas`, `metodos_pesca`, `pescadores`, `capturas`,
`tipos_embarcacion`, `embarcaciones`, `faenas`, `faenas_pescadores`, `vedas`,
`auditoria_capturas`.

### Entidad nueva en esta unidad

#### `cuotas_especies`

Registra el límite de kg autorizados para capturar una especie durante un
período determinado, a nivel nacional o restringido a una cuenca.

| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `id` | `serial` | `PRIMARY KEY` | Identificador de la cuota |
| `especie_id` | `integer` | `NOT NULL`, `FOREIGN KEY` | Especie sujeta a la cuota |
| `cuenca_id` | `integer` | `FOREIGN KEY`, nullable | Cuenca donde aplica la cuota. `NULL` indica cuota nacional |
| `periodo_inicio` | `date` | `NOT NULL` | Fecha de inicio del período de la cuota |
| `periodo_fin` | `date` | `NOT NULL` | Fecha de fin del período de la cuota |
| `kg_autorizado` | `numeric(10,2)` | `NOT NULL CHECK > 0` | Límite total de kg autorizados para el período |
| `kg_restante` | `numeric(10,2)` | `NOT NULL CHECK >= 0` | Kg disponibles antes de alcanzar el límite |

---

## Decisiones de diseño

### 1. kg_restante como columna almacenada: una denormalización deliberada

A diferencia del resto del modelo, que evita atributos derivados almacenados
en favor de calcularlos mediante consultas (por ejemplo, el total capturado
por faena nunca se almacena; se calcula con `SUM` sobre `captura`), `kg_restante`
sí se almacena físicamente y se decrementa activamente cada vez que se registra
una captura que aplica a esa cuota.

Esta es una denormalización deliberada con un propósito pedagógico específico:
el problema de concurrencia que esta unidad busca demostrar (dos sesiones
descontando la misma cuota simultáneamente, ambas viendo cupo disponible,
ambas insertando) **solo existe si hay un valor almacenado que se lee y luego
se actualiza en pasos separados**. Si `kg_restante` se calculara con `SUM()`
en cada consulta, no habría condición de carrera que demostrar: el cálculo
siempre sería consistente porque se derivaría directamente de las capturas
ya confirmadas en ese momento.

En un sistema real, esta decisión de denormalizar por control y rendimiento
frente a mantener todo calculado y normalizado es una tensión de diseño
genuina, no exclusiva de este ejercicio académico.

### 2. Relación entre cuotas_especies y capturas: coincidencia computada, no FK

`cuotas_especies` no tiene una clave foránea hacia `captura`, siguiendo el mismo
patrón ya usado en `vedas` visto en la Unidad 4. Una captura "afecta" una cuota cuando
coinciden tres condiciones simultáneamente:

1. `capturas.especie_id` = `cuotas_especies.especie_id`
2. La fecha de la captura cae dentro de `[periodo_inicio, periodo_fin]` de la cuota.
3. La cuenca de la captura (obtenida vía `captura → faena → municipio → cuenca`)
   coincide con `cuotas_especies.cuenca_id`, o la cuota es nacional (`cuenca_id IS NULL`)

Esta es la misma lógica de coincidencia implementada en la función `f_esta_en_veda`
de la Unidad 4, aplicada ahora a cuotas en lugar de vedas.

### 3. Evolución de p_registra_captura en lugar de un procedimiento nuevo

El procedimiento `p_registra_captura` se modifica directamente en esta unidad,
en lugar de crear un procedimiento paralelo. Esta decisión refleja el mismo
principio de evolución aplicado al modelo estructural a lo largo del curso
(como la refactorización de `captura` en la Unidad 3): la lógica almacenada
evoluciona junto con los requerimientos del dominio, no se acumula en
versiones paralelas.

**Antes (Unidad 4):**

`p_registra_captura` validaba, en orden: existencia de la faena, participación
del pescador en la faena, veda vigente, capacidad de carga disponible de la
embarcación. Luego insertaba la captura.

**Después (Unidad 5):**

Se agrega una quinta validación (cuota disponible) y un paso posterior al
`INSERT`: el descuento de `kg_restante`. La validación de cuota usa
`SELECT ... FOR UPDATE` sobre la fila de `cuotas_especies` para bloquearla
durante la transacción, evitando que otra sesión concurrente lea el mismo
valor de `kg_restante` antes de que la primera transacción confirme su
descuento. Ver la sección "Transacciones y concurrencia" más abajo para el
detalle de por qué este bloqueo es necesario.

| Validación | Unidad 4 | Unidad 5 |
|---|---|---|
| Faena existe | Si | Si |
| Pescador pertenece a la faena | Si | Si |
| Especie no está en veda | Si | Si |
| Capacidad de carga disponible | Si | Si |
| Cuota disponible (con bloqueo `FOR UPDATE`) |  | nueva |
| Descuento de `kg_restante` tras el INSERT |  | nueva |

### 4. cuenca_id en cuotas_especies: mismo patrón que veda

Al igual que en `vedas`, `cuenca_id` es nullable para representar cuotas de
alcance nacional (`NULL`) o restringidas a una cuenca específica. No se
modela una tabla de intersección porque, igual que con las vedas, no existe
en este dominio el caso de una cuota que aplique a un subconjunto arbitrario
de varias cuencas: es nacional o es de una cuenca puntual.

### 5. Restricciones CHECK sobre kg_autorizado y kg_restante

`kg_autorizado > 0` garantiza que toda cuota tenga un límite positivo con
sentido. `kg_restante >= 0` es la restricción más importante de la tabla:
impide que el saldo quede negativo por cualquier vía, incluyendo errores en
la lógica de descuento. Esta restricción actúa como una segunda línea de
defensa además de la validación explícita en el procedimiento
`p_registra_captura`; incluso si el procedimiento tuviera un error, 
la base de datos rechazaría el `UPDATE` que dejara `kg_restante` en negativo.

### 6. Normalización

`cuotas_especies` cumple la Tercera Forma Normal (3FN) con la excepción
consciente y documentada de `kg_restante`, que es un valor derivado
almacenado por las razones expuestas en la decisión 1. Todos los demás
atributos dependen directamente de `id` sin dependencias transitivas.

---

## Transacciones y concurrencia

### Propiedades ACID en el escenario de cuotas

- **Atomicidad:** verificar cuota disponible, insertar la captura y descontar
  `kg_restante` ocurren dentro de una misma transacción. Si cualquier paso
  falla, la transacción completa se revierte y ningún cambio parcial queda
  registrado.
- **Consistencia:** la restricción `CHECK (kg_restante >= 0)` garantiza que
  la base de datos nunca queda en un estado que viole la regla de negocio
  fundamental de la cuota, incluso ante errores de la lógica de aplicación.
- **Aislamiento:** `SELECT ... FOR UPDATE` bloquea la fila de `cuota_especie`
  en el momento de la lectura, antes de cualquier `INSERT`, adelantando el
  rechazo de una captura sin cuota suficiente a un punto temprano del
  procedimiento y con un mensaje de negocio claro. Sin este bloqueo
  explícito, PostgreSQL igual serializa los `UPDATE` concurrentes sobre la
  misma fila y la restricción `CHECK (kg_restante >= 0)` seguiría evitando
  la corrupción del dato, pero el rechazo ocurriría más tarde y con un
  mensaje de error genérico. Ver la sección siguiente para el detalle
  completo de esta distinción.
- **Durabilidad:** una vez que `COMMIT` se confirma, el descuento de cuota
  persiste incluso ante una falla del sistema inmediatamente después.


### Reproducción manual del escenario en dos sesiones psql

Esta unidad no automatiza la demostración de concurrencia en un solo script,
porque la concurrencia genuina requiere procesos separados que se entrelacen
en el tiempo real. En su lugar, se documentan instrucciones para reproducir
el escenario manualmente abriendo dos sesiones `psql` en paralelo.

Ver `03_isolation_postgreSQL.sql` para el procedimiento paso a paso, que incluye:

1. Preparar una cuota de prueba con `kg_restante` conocido.
2. En la Sesión A: iniciar una transacción, leer `kg_restante`, pausar antes
   del `UPDATE` (sin hacer `COMMIT` todavía).
3. En la Sesión B: intentar la misma operación mientras la Sesión A está
   pausada, y observar el comportamiento según el nivel de aislamiento activo.
4. Comparar el comportamiento bajo `READ COMMITTED` (nivel por defecto en
   PostgreSQL, donde el problema puede manifestarse sin `FOR UPDATE`) contra
   el comportamiento con `SELECT ... FOR UPDATE` (donde la Sesión B queda
   bloqueada hasta que la Sesión A confirma o revierte).

---

## Casos de prueba unitaria

| Caso | Escenario | Resultado esperado |
|---|---|---|
| Éxito | Captura dentro de cuota disponible | `kg_restante` se descuenta correctamente, captura registrada |
| Cuota insuficiente | Captura supera `kg_restante` disponible | `ROLLBACK` implícito vía `RAISE EXCEPTION`, `kg_restante` sin cambios |
| Veda vigente | Captura de especie en veda (reutiliza validación de U4) | Rechazada, `kg_restante` sin cambios |
| Especie fuera de cuenca | Captura de especie sin distribución en la cuenca de la faena | Rechazada por integridad del dominio, `kg_restante` sin cambios |
| Concurrencia | Dos sesiones intentan descontar la misma cuota simultáneamente | Ambas variantes (con y sin `FOR UPDATE`) terminan rechazando la segunda operación; difieren en el momento del rechazo y en si el mensaje es de negocio o un error de restricción genérico |

Ver `04_unit_tests_postgreSQL.sql` para la implementación de cada caso, incluyendo
verificación explícita del estado de `kg_restante` antes y después de cada
prueba.
---

## Glosario

| Término | Significado en este dominio |
|---|---|
| Cuota de captura | Límite de kg autorizados para capturar una especie durante un período, a nivel nacional o por cuenca |
| Propiedades ACID | Atomicidad, Consistencia, Aislamiento y Durabilidad: las cuatro garantías de confiabilidad de una transacción |
| Condición de carrera | Situación en que el resultado de operaciones concurrentes depende del orden impredecible en que se ejecutan, pudiendo violar reglas de negocio que cada operación individual respetaba |
| SELECT FOR UPDATE | Cláusula que bloquea las filas seleccionadas hasta que la transacción actual termina, impidiendo que otra transacción las modifique mientras tanto |
| Nivel de aislamiento | Configuración que determina el grado en que una transacción está protegida de los efectos de otras transacciones concurrentes |
| Denormalización deliberada | Decisión consciente de almacenar un valor derivado en lugar de calcularlo en cada consulta, documentando explícitamente el motivo y el trade-off asumido |