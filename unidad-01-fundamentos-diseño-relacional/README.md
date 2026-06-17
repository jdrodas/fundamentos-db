# Fundamentos de Bases de Datos Relacionales

## Unidad 1: Fundamentos y diseño de bases de datos relacionales

### Descripción

En esta unidad construyes una comprensión sólida de los fundamentos conceptuales
del modelo relacional. A través del estudio del álgebra relacional y el proceso de
normalización, desarrollas los criterios esenciales para tomar decisiones de diseño
estructuradas y justificadas. La unidad cierra con la construcción de un diagrama
relacional propio y su implementación en SQL.


### Competencia

Diseña modelos de datos relacionales aplicando principios de normalización y buenas
prácticas de estructuración.


### Propósitos de aprendizaje

- P1.1. Identificar los componentes del modelo relacional y su rol en el diseño de
  bases de datos.
- P1.2. Construir un diagrama relacional normalizado para un dominio de problema dado, aplicando las formas normales estudiadas.
- P1.3. Implementar en SQL el modelo relacional diseñado, definiendo correctamente
  tipos de datos, restricciones y relaciones entre tablas.
- P1.4. Validar la integridad estructural de la base de datos mediante la inserción
  de datos de prueba.


### Criterios de evaluación

| Componente | Criterio |
|---|---|
| Diagrama relacional | Refleja correctamente entidades, atributos, claves primarias, claves foráneas y relaciones. Las tablas cumplen al menos con la 3FN. Las decisiones de diseño están justificadas con base en los conceptos estudiados. |
| Script SQL | Ejecuta sin errores y crea la estructura definida en el diagrama. Usa tipos de datos apropiados (énfasis en `varchar` y `timestamp`). Las restricciones (`PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`) están correctamente definidas. Se incluyen datos de prueba que validan las relaciones. |


### Contenidos de la unidad

1. Conceptos básicos y modelo relacional — tipos de bases de datos, álgebra relacional, estructura del modelo: tablas, tuplas, atributos, claves primarias y foráneas.
2. Proceso de diseño de bases de datos — fases conceptual, lógica y física.
3. Normalización y optimización de estructuras — formas normales 1FN, 2FN y 3FN,
   y criterios para desnormalizar.


### Recursos de esta carpeta

```
unit-01-fundamentos-diseno-relacional/
├── README.md          ← este archivo
├── diagrams/
│   └── modelo-er.svg  ← diagrama relacional de referencia
├── scripts/
│   ├── 00_schema.sql  ← creación de tablas y restricciones
│   └── 01_seed.sql    ← datos de prueba
└── data/

```


### Glosario rápido

| Término | Significado |
|---|---|
| Modelo relacional | Paradigma que estructura la información en tablas relacionadas mediante claves. |
| Normalización | Proceso para eliminar redundancias y anomalías de inserción, actualización y eliminación. |
| Clave primaria | Atributo que identifica de manera única cada fila de una tabla. |
| Clave foránea | Atributo que referencia la clave primaria de otra tabla, garantizando integridad referencial. |
| Forma normal | Nivel de organización estructural que debe cumplir una tabla para considerarse correctamente normalizada. |