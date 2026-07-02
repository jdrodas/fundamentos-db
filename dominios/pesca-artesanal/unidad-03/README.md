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

### Recursos de esta carpeta - unidad 3

| Recurso | Descripción |
|---------|-------------|
| [README.md](README.md) |  Este archivo |
| [DESCRIPCION_MODELO.md](DESCRIPCION_MODELO.md) |  descripción del dominio del problema |
| [pesca_artesanal_diagrama_relacional_unidad3.jpg](diagramas/pesca_artesanal_diagrama_relacional_unidad3.jpg) |  diagrama relacional de la unidad |
| [00_schema_postgreSQL.sql](scripts/00_schema_postgreSQL.sql) |  script de creación de tablas y restricciones |
| [01_seed_postgreSQL.sql](scripts/01_seed_postgreSQL.sql) |  datos de prueba |
| [02_joins_postgreSQL.sql](scripts/02_joins_postgreSQL.sql) |  consultas SQL usando JOINS |
| [03_subqueries_postgreSQL.sql](scripts/03_subqueries_postgreSQL.sql) |  subconsultas simples y correlacionadas |
| [04_ctes_postgreSQL.sql](scripts/04_ctes_postgreSQL.sql) |  CTEs simples y recursivass |
| [05_window_functions_postgreSQL.sql](scripts/05_window_functions_postgreSQL.sql) |  funciones de ventana y análisis avanzado |
| [06_views_postgreSQL.sql](scripts/06_views_postgreSQL.sql) |  vistas que encapsulan consultas de referencia |

### Glosario rápido

| Término | Significado |
|---|---|
| JOIN | Operación SQL que combina filas de dos o más tablas basándose en una condición de relación entre ellas. |
| Subconsulta | Consulta SQL anidada dentro de otra consulta principal, usada en `SELECT`, `WHERE` o `FROM`. |
| Subconsulta correlacionada | Subconsulta que referencia columnas de la consulta exterior y se ejecuta una vez por cada fila procesada. |
| CTE (Common Table Expression) | Expresión de tabla temporal definida con `WITH` que existe únicamente durante la ejecución de la consulta que la contiene. |
| Función de ventana | Función SQL que realiza cálculos sobre un conjunto de filas relacionadas con la fila actual sin colapsar el resultado en un único valor. |
| Vista | Consulta guardada bajo un nombre, que se ejecuta cada vez que se referencia. No almacena datos propios |