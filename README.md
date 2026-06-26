# Fundamentos de Bases de Datos Relacionales   
# Recursos del Curso

Repositorio de recursos de apoyo para el curso. Contiene los materiales de cada dominio de problema trabajado a lo largo de las
cohortes del curso: modelos relacionales, scripts SQL y diagramas ER organizados
por unidad y con evolución progresiva del esquema.



---

## Estructura del repositorio

Cada dominio crece unidad a unidad. El modelo de la unidad anterior se extiende
en la siguiente, acumulando entidades y complejidad de forma progresiva.

```
fundamentos-db/
├── dominios/
│   └── <nombre-dominio>/
│       ├── unidad-01/
│       │   ├── README.md
│       │   ├── DESCRIPCION_MODELO.md
│       │   ├── diagramas/
│       │   │   └── modelo-er.svg
│       │   └── scripts/
│       │       ├── 00_schema.sql
│       │       └── 01_seed.sql
│       ├── unidad-02/
│       ├── unidad-03/
│       ├── unidad-04/
│       └── unidad-05/
└── README.md
```

---

## Estructura de unidades del curso

Cada unidad contiene la descripción de competencias, propósitos de aprendizaje y criterios de evaluación que se esperan lograr con su ejecución. Ubica el respectivo archivo **`README.md`** para más detalles.   


| Carpeta | Unidad | Contenido |
|---|---|---|
| unidad 1 | Fundamentos y diseño relacional | Esquema base, datos semilla, diagrama ER inicial |
| unidad 2 | SQL básico | Scripts DML, consultas de referencia |
| unidad 3 | SQL avanzado | JOINs, CTEs, funciones de ventana |
| unidad 4 | Lógica almacenada | Procedimientos, funciones, triggers |
| unidad 5 | Transacciones y pruebas | Scripts ACID, casos de prueba |


## Dominios

| Dominio | Período | Estado |
|---|---|---|
| [Pesca artesanal](dominios/pesca-artesanal/) | 2026-20 | En curso |

---
