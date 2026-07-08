# Fundamentos de Bases de Datos Relacionales

## Unidad 5: Transacciones, concurrencia y pruebas

### Descripción

En esta unidad de cierre integras los conocimientos acumulados durante el curso
para abordar los aspectos críticos que garantizan la confiabilidad de una base de
datos en entornos de producción. A través del estudio de las propiedades ACID, los
mecanismos de control de concurrencia y las técnicas de prueba, desarrollas la
capacidad de diseñar e implementar bases de datos no solo funcionales, sino robustas
y verificables. El diseño relacional se aborda con plena confianza y autonomía,
enfocándote en modelar escenarios donde la integridad transaccional y el acceso
concurrente son requisitos críticos del dominio.


### Competencia

Diseña e implementa bases de datos relacionales confiables mediante el uso de
transacciones, control de concurrencia y pruebas unitarias que garantizan su
integridad en entornos de producción.


### Propósitos de aprendizaje

- P5.1. Diseñar un modelo relacional orientado a escenarios donde la integridad
  transaccional y el acceso concurrente son requisitos críticos del dominio de
  problema.
- P5.2. Demostrar dominio pleno de las decisiones de diseño: nomenclatura,
  normalización, restricciones y relaciones aplicadas con criterio experto.
- P5.3. Implementar transacciones que garanticen las propiedades ACID ante escenarios de éxito y fallo en el dominio trabajado.
- P5.4. Diseñar y ejecutar casos de prueba unitaria que validen el comportamiento de las operaciones de la base de datos bajo condiciones normales y de concurrencia.


### Criterios de evaluación

| Componente | Criterio |
|---|---|
| Diagrama relacional | Modela con precisión un escenario transaccional del dominio de la cohorte. Las entidades y relaciones identificadas justifican el uso de transacciones y control de concurrencia. El diseño refleja el nivel de madurez y autonomía esperado al cierre del curso. |
| Script SQL | Implementa transacciones con `BEGIN`, `COMMIT` y `ROLLBACK` para escenarios de éxito y fallo. Gestiona situaciones de error mediante reversión controlada. Analiza implicaciones de los niveles de aislamiento. Incluye casos de prueba unitaria que validan el comportamiento esperado bajo condiciones normales y de concurrencia. |


### Contenidos de la unidad

1. Fundamentos de transacciones — propiedades ACID; ciclo completo de `BEGIN`,
   `COMMIT` y `ROLLBACK`; manejo de errores y niveles de aislamiento disponibles.
2. Concurrencia y control de acceso — problemas de acceso simultáneo (lecturas
   sucias, lecturas no repetibles, lecturas fantasma); mecanismos de bloqueo;
   identificación y resolución de deadlocks.
3. Pruebas unitarias para bases de datos — diseño de casos de prueba para operaciones
   de base de datos; herramientas y frameworks aplicables al motor del curso; énfasis
   en pruebas de transacciones y concurrencia.


### Recursos de esta carpeta - unidad 5

| Recurso | Descripción |
|---------|-------------|
| [README.md](README.md) |  Este archivo |
| [DESCRIPCION_MODELO.md](DESCRIPCION_MODELO.md) |  descripción del dominio del problema |
| [pesca_artesanal_diagrama_relacional_unidad5.jpg](diagramas/pesca_artesanal_diagrama_relacional_unidad5.jpg) |  diagrama relacional de la unidad |
| [00_schema_postgreSQL.sql](scripts/00_schema_postgreSQL.sql) |  tabla cuota_especie |
| [01_seed_postgreSQL.sql](scripts/01_seed_postgreSQL.sql) |  cuotas de prueba |
| [02_transactions_postgreSQL.sql](scripts/02_transactions_postgreSQL.sql) |  registrar_captura evolucionado, BEGIN/COMMIT/ROLLBACK |
| [03_isolation_postgreSQL.sql](scripts/03_isolation_postgreSQL.sql) |  instrucciones de reproducción manual en dos sesiones |
| [04_unit_tests_postgreSQL.sql](scripts/04_unit_tests_postgreSQL.sql) |  casos de prueba unitaria |


### Glosario rápido

| Término | Significado |
|---|---|
| Propiedades ACID | Atomicidad, Consistencia, Aislamiento y Durabilidad: las cuatro características que garantizan la confiabilidad de las transacciones en una base de datos. |
| Nivel de aislamiento | Configuración que determina el grado en que una transacción está protegida de los efectos de otras transacciones concurrentes. |
| Deadlock | Situación de bloqueo mutuo en que dos o más transacciones se esperan indefinidamente entre sí para liberar recursos. |
| Lectura fantasma | Problema de concurrencia que ocurre cuando una transacción ejecuta la misma consulta dos veces y obtiene conjuntos de filas diferentes por inserciones o eliminaciones concurrentes. |
| Prueba unitaria de base de datos | Caso de prueba que verifica el comportamiento esperado de una operación específica (procedimiento, función o transacción) de forma aislada y reproducible. |