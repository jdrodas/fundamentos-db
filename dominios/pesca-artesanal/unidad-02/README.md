# Fundamentos de Bases de Datos Relacionales

## Unidad 2: Fundamentos de SQL y operaciones básicas

### Descripción

Partiendo del modelo relacional construido en la unidad anterior, profundizas en el
lenguaje SQL como herramienta fundamental para interactuar con bases de datos
relacionales. A través del estudio de la sintaxis básica, las operaciones de
manipulación de datos y las funciones de agrupamiento, desarrollas la capacidad de
formular consultas precisas y transformar datos en información útil. La unidad
consolida las habilidades de diseño iniciadas en la Unidad 1 mediante la extensión
del modelo con nuevas entidades.


### Competencia

Implementa operaciones SQL sobre modelos relacionales, aplicando criterios de
precisión, integridad y eficiencia en la manipulación y consulta de datos.


### Propósitos de aprendizaje

- P2.1. Extender el modelo relacional existente incorporando nuevas entidades y
  relaciones que soporten operaciones de consulta y agrupamiento sobre el dominio
  de problema.
- P2.2. Aplicar criterios de nomenclatura, restricciones y decisiones de diseño con
  mayor autonomía respecto a la unidad anterior.
- P2.3. Implementar en SQL la extensión del modelo diseñado, incorporando operaciones de inserción, actualización y eliminación de datos.
- P2.4. Formular consultas con filtrado, ordenamiento y funciones de agrupamiento que respondan a preguntas de negocio del dominio trabajado.


### Criterios de evaluación

| Componente | Criterio |
|---|---|
| Diagrama relacional | Extiende coherentemente el modelo de la Actividad 1. Las nuevas entidades están correctamente normalizadas. Se evidencia progreso en la calidad de las decisiones de diseño respecto a la entrega anterior. |
| Script SQL | Implementa correctamente la extensión del modelo. Incluye operaciones `INSERT`, `UPDATE` y `DELETE` con manejo básico de transacciones. Las consultas hacen uso de `GROUP BY`, `HAVING` y funciones agregadas. Se evidencia uso apropiado de tipos `varchar` y `timestamp` en consultas y funciones de fecha-hora. |


### Contenidos de la unidad

1. Introducción a SQL y tipos de datos — sintaxis fundamental, énfasis en `varchar`
   para texto y `timestamp` para registro de eventos y fechas.
2. Consultas básicas y filtrado — `SELECT`, `WHERE`, `ORDER BY` y `LIMIT` aplicados
   al dominio de la cohorte.
3. Manipulación de datos — `INSERT`, `UPDATE` y `DELETE` con introducción a
   transacciones básicas.
4. Funciones y agrupamiento — funciones agregadas (`SUM`, `AVG`, `COUNT`, `MAX`,
   `MIN`), `GROUP BY` y `HAVING`, y funciones de cadena y fecha-hora.


### Recursos de esta carpeta - unidad 2

| Recurso | Descripción |
|---------|-------------|
| [README.md](README.md) |  Este archivo |
| [DESCRIPCION_MODELO.md](DESCRIPCION_MODELO.md) |  descripción del dominio del problema |
| [pesca_artesanal_diagrama_relacional_unidad2.jpg](diagramas/pesca_artesanal_diagrama_relacional_unidad2.jpg) |  diagrama relacional de la unidad |
| [00_schema_postgreSQL.sql](scripts/00_schema_postgreSQL.sql) |  script de creación de tablas y restricciones |
| [01_seed_postgreSQL.sql](scripts/01_seed_postgreSQL.sql) |  datos de prueba |
| [02_queries_postgreSQL.sql](scripts/02_queries_postgreSQL.sql) |  consultas SQL |



### Glosario rápido

| Término | Significado |
|---|---|
| DDL (Data Definition Language) | Subconjunto de SQL para definir y modificar la estructura de la base de datos: `CREATE`, `ALTER`, `DROP`. |
| DML (Data Manipulation Language) | Subconjunto de SQL para manipular el contenido de las tablas: `INSERT`, `UPDATE`, `DELETE`. |
| Función agregada | Función que opera sobre un conjunto de filas y retorna un único valor resumen: `SUM`, `AVG`, `COUNT`, `MAX`, `MIN`. |
| Cláusula GROUP BY | Agrupa las filas de un resultado según los valores de uno o más atributos, permitiendo aplicar funciones agregadas por grupo. |
| Transacción básica | Unidad lógica de trabajo compuesta por una o más operaciones SQL que se ejecutan de forma conjunta o no tienen efecto. |