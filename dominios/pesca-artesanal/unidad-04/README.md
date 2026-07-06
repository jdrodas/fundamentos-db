# Fundamentos de Bases de Datos Relacionales

## Unidad 4: Lógica almacenada

### Descripción

En esta unidad das un paso hacia la programabilidad de las bases de datos,
aprendiendo a encapsular lógica de negocio directamente en el motor mediante
procedimientos almacenados, funciones definidas por el usuario y triggers.
Habiendo consolidado tus habilidades de diseño en las unidades anteriores,
abordas esta unidad con autonomía en la construcción del modelo relacional y
concentras tu atención en cómo la lógica almacenada complementa y fortalece
la integridad y el comportamiento de la base de datos.


### Competencia

Implementa lógica almacenada en bases de datos relacionales para encapsular
reglas de negocio, automatizar procesos y garantizar la integridad de los datos.


### Propósitos de aprendizaje

- P4.1. Diseñar un modelo relacional que incorpore entidades y relaciones orientadas a soportar procesos automatizables mediante lógica almacenada.
- P4.2. Aplicar con plena autonomía los criterios de nomenclatura, normalización y
  restricciones aprendidos a lo largo del curso.
- P4.3. Implementar procedimientos almacenados y funciones definidas por el usuario
  que encapsulen lógica de negocio reutilizable del dominio trabajado.
- P4.4. Crear triggers que respondan automáticamente a eventos de datos, garantizando la integridad y consistencia del modelo.


### Criterios de evaluación

| Componente | Criterio |
|---|---|
| Diagrama relacional | Refleja un diseño maduro y autónomo, coherente con el dominio de problema. Las entidades y relaciones identificadas justifican la implementación de procedimientos, funciones y triggers. Las decisiones de diseño están correctamente sustentadas. |
| Script SQL | Incluye al menos un procedimiento almacenado con parámetros de entrada y salida y manejo de errores. Implementa al menos una función definida por el usuario (escalar o de tabla). Crea triggers para al menos dos tipos de eventos (`INSERT`, `UPDATE` o `DELETE`). La lógica implementada responde a necesidades reales del dominio de problema. |


### Contenidos de la unidad

1. Procedimientos almacenados — creación y ejecución, manejo de parámetros,
   estructuras de control de flujo y estrategias de manejo de errores.
2. Funciones definidas por el usuario — diferencia entre funciones escalares y
   funciones de tabla; consideraciones de rendimiento según el tipo utilizado.
3. Triggers y manejo de eventos — triggers `AFTER` e `INSTEAD OF` para los eventos
   `INSERT`, `UPDATE` y `DELETE`; escenarios de uso y consideraciones de rendimiento.


### Recursos de esta carpeta - unidad 4

| Recurso | Descripción |
|---------|-------------|
| [README.md](README.md) |  Este archivo |
| [DESCRIPCION_MODELO.md](DESCRIPCION_MODELO.md) |  descripción del dominio del problema |
| [pesca_artesanal_diagrama_relacional_unidad4.jpg](diagramas/pesca_artesanal_diagrama_relacional_unidad4.jpg) |  diagrama relacional de la unidad |
| [00_schema_postgreSQL.sql](scripts/00_schema_postgreSQL.sql) |  script de creación de tablas y restricciones |
| [01_seed_postgreSQL.sql](scripts/01_seed_postgreSQL.sql) |  datos de prueba |


### Glosario rápido

| Término | Significado |
|---|---|
| Procedimiento almacenado | Objeto de base de datos que encapsula una secuencia de instrucciones SQL y lógica de control bajo un nombre reutilizable, con parámetros de entrada y salida. |
| Función definida por el usuario | Objeto de base de datos que encapsula lógica reutilizable y retorna un valor escalar o un conjunto de filas, integrable directamente en consultas SQL. |
| Trigger | Objeto de base de datos que se ejecuta automáticamente ante eventos de inserción, actualización o eliminación sobre una tabla. |
| Control de flujo | Estructuras de programación dentro de la lógica almacenada —condicionales y ciclos— que dirigen la ejecución según condiciones evaluadas dinámicamente. |
| Manejo de errores | Mecanismo que permite interceptar y gestionar de forma controlada situaciones de fallo durante la ejecución de procedimientos, funciones o triggers. |