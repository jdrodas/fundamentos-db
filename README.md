# Fundamentos de Bases de Datos Relacionales — Recursos del Curso

Repositorio de recursos de apoyo para el curso. Aquí encontrarás los scripts SQL
de referencia, los datasets de prueba y los diagramas relacionales para cada unidad.

## Estructura del repositorio

| Carpeta | Unidad | Contenido |
|---|---|---|
| [`unidad-01-fundamentos-diseño-relacional`](unidad-01-fundamentos-diseño-relacional/) | Fundamentos y diseño relacional | Esquema base, datos semilla, diagrama ER inicial |
| [`unidad-02-sql-basico`](unidad-02-sql-basico/) | SQL básico | Scripts DML, consultas de referencia |
| [`unidad-03-sql-avanzado`](unidad-03-sql-avanzado/) | SQL avanzado | JOINs, CTEs, funciones de ventana |
| [`unidad-04-logica-almacenada`](unidad-04-logica-almacenada/) | Lógica almacenada | Procedimientos, funciones, triggers |
| [`unidad-05-transacciones-y-pruebas`](unidad-05-transacciones-y-pruebas/) | Transacciones y pruebas | Scripts ACID, casos de prueba |

## Cómo usar estos recursos

1. Clona el repositorio o descarga la carpeta de la unidad que estás trabajando.
2. Cada unidad tiene su propio `README.md` con los objetivos y criterios de evaluación.
3. Los scripts están numerados en orden de ejecución: `00_schema.sql` primero,
   luego `01_seed.sql`, luego las consultas.

## Motor de base de datos

Los scripts están escritos para **PostgreSQL 15+**. Si usas otro motor, revisa
las notas de compatibilidad en el README de cada unidad.

## Licencia

MIT — puedes usar, adaptar y distribuir libremente con atribución.