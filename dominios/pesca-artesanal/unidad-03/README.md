# Fundamentos de Bases de Datos Relacionales

## Unidad 3: SQL avanzado

### Descripción

En esta unidad amplías tu dominio del lenguaje SQL hacia técnicas de consulta
avanzada, trabajando con relaciones entre múltiples tablas, subconsultas,
expresiones de tabla comunes y funciones de ventana. El modelo relacional acumulado
durante las unidades anteriores se convierte en el escenario ideal para formular
consultas de mayor complejidad que responden a preguntas de negocio más elaboradas.
La unidad continúa fortaleciendo las habilidades de diseño al incorporar al modelo
relaciones que soporten estos patrones de consulta avanzada.


### Competencia

Diseña e implementa consultas SQL avanzadas que explotan las relaciones entre
entidades del modelo para responder preguntas de negocio complejas.


### Propósitos de aprendizaje

- P3.1. Enriquecer el modelo relacional incorporando relaciones entre entidades que
  habiliten consultas con múltiples JOINs y análisis agregado avanzado.
- P3.2. Demostrar consolidación en las decisiones de diseño: nomenclatura,
  normalización y restricciones aplicadas con autonomía y criterio.
- P3.3. Implementar consultas con JOINs entre múltiples tablas que recuperen
  información integrada del dominio de problema.
- P3.4. Utilizar subconsultas, CTEs y funciones de ventana para resolver preguntas
  de análisis que no son posibles con consultas simples.


### Criterios de evaluación

| Componente | Criterio |
|---|---|
| Diagrama relacional | Incorpora relaciones que justifican el uso de JOINs y subconsultas. Es coherente con las entregas anteriores y evidencia madurez creciente en las decisiones de diseño. Las nuevas entidades y relaciones están correctamente normalizadas. |
| Script SQL | Incluye al menos un ejemplo de cada tipo de JOIN trabajado. Implementa subconsultas correlacionadas y al menos una CTE. Las funciones de ventana se aplican para cálculos de ranking o acumulados sobre el dominio. Las consultas responden a preguntas de negocio claramente enunciadas. |


### Contenidos de la unidad

1. JOINs y relaciones entre tablas — tipos `INNER`, `LEFT`, `RIGHT`, `FULL` y
   `CROSS JOIN`, con técnicas para escribir JOINs eficientes.
2. Subconsultas y expresiones de tabla comunes (CTE) — subconsultas en contextos
   `SELECT`, `WHERE` y `FROM`; subconsultas correlacionadas; CTEs simples y
   recursivas.
3. Funciones de ventana y análisis avanzado — ranking, numeración de filas,
   cálculos móviles y acumulativos; manejo avanzado de `varchar` y `timestamp`
   en análisis temporal y textual.


### Recursos de esta carpeta

```
unit-03-sql-avanzado/
├── README.md                  ← este archivo
├── diagrams/
│   └── modelo-er.svg          ← diagrama relacional enriquecido de referencia
├── scripts/
│   ├── 00_schema.sql          ← extensión del esquema con nuevas relaciones
│   ├── 01_seed.sql            ← datos de prueba representativos del dominio
│   ├── 02_joins.sql           ← ejemplos de cada tipo de JOIN
│   ├── 03_subqueries.sql      ← subconsultas simples y correlacionadas
│   ├── 04_ctes.sql            ← CTEs simples y recursivas
│   └── 05_window_functions.sql← funciones de ventana y análisis avanzado
└── data/

```


### Glosario rápido

| Término | Significado |
|---|---|
| JOIN | Operación SQL que combina filas de dos o más tablas basándose en una condición de relación entre ellas. |
| Subconsulta | Consulta SQL anidada dentro de otra consulta principal, usada en `SELECT`, `WHERE` o `FROM`. |
| Subconsulta correlacionada | Subconsulta que referencia columnas de la consulta exterior y se ejecuta una vez por cada fila procesada. |
| CTE (Common Table Expression) | Expresión de tabla temporal definida con `WITH` que existe únicamente durante la ejecución de la consulta que la contiene. |
| Función de ventana | Función SQL que realiza cálculos sobre un conjunto de filas relacionadas con la fila actual sin colapsar el resultado en un único valor. |