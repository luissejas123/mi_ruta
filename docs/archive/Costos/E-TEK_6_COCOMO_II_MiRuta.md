# E-TEK 6 — Costos de Software: COCOMO II (Post-Architecture) aplicado a Mi Ruta

**Carrera:** Sistemas Informáticos — **Asignatura:** Gestión y Mejoramiento de la Calidad de Software — **Docente:** Ing. Carolina Aguilar
**Ejercicio:** E-TEK 6 · Unidad temática: Costos de Software — **Turno:** Noche
**Proyecto:** Mi Ruta — app de planificación y pago de transporte público (Cochabamba, Bolivia)
**Fecha de entrega:** 09/07/2026

> **Nota metodológica:** a diferencia de un COCOMO clásico (estimar *antes* de programar), este ejercicio se resuelve sobre un proyecto que ya tiene código real y un tracker de seguimiento real (`docs/AsyncDaily/Revision QA.xlsx`, `docs/INFORME_AVANCE_SPRINT.md`). Eso permite dos cosas que un ejercicio de aula normalmente no tiene: (1) medir el tamaño real en vez de adivinarlo, y (2) en la Parte 5, comparar la predicción del modelo contra lo que el equipo realmente hizo. Los valores marcados **(medido)** vienen directo del repositorio; los marcados **(aproximado)** son estimaciones razonables donde no existe un dato exacto (costo por persona-mes, calificación exacta de cada driver), tal como se pidió.

---

## Parte 1 — Tamaño del proyecto en KSLOC

En vez de estimar por juicio experto "a ciegas", se **midió directamente** el código fuente (`lib/**/*.dart`, líneas no vacías y sin contar líneas que son solo comentario `//`), descompuesto por módulo — el mismo criterio de descomposición que pide el ejercicio, aplicado sobre datos reales:

| Módulo (Clean Architecture) | SLOC medido |
|---|---:|
| `features/user` (usuario: mapa, wallet, QR, beneficios, notificaciones, historial) | 18,762 |
| `features/driver` (chofer: vehículo, ingresos, rutas, operaciones) | 4,906 |
| `features/admin` (administración: usuarios, rutas, privilegios, reportes) | 4,451 |
| `features/routes` (GTFS, planificador multi-tramo, SQLite) | 2,454 |
| `features/tickeador` | 1,751 |
| `features/auth` | 1,655 |
| `core/` (DI, ruteo, tema, utilidades) | 1,340 |
| `features/stops` | 517 |
| `features/presidente` | 415 |
| `services/` (raíz) + `main.dart` | ~187 |
| `features/payment`, `features/shared` (stubs sin implementar) | 0 |
| **Total medido (`lib/`)** | **36,822** |

**Tamaño usado en el cálculo: Size = 37 KSLOC** (36,822 redondeado). No se incluyen tests ni archivos generados por plugins, siguiendo el criterio estándar de COCOMO de contar solo código fuente entregado.

---

## Parte 2 — Factores de escala y exponente E

Los 5 factores de escala se calificaron con criterio específico al proyecto real, no genérico — cada uno respaldado por evidencia del propio historial del equipo (`git log --merges`, `docs/INFORME_AVANCE_SPRINT.md`):

| Factor | Nivel elegido | SFj | Justificación específica al proyecto |
|---|---|---:|---|
| **PREC** — Precedentedness | Bajo | 4.96 | Es la primera vez que este equipo construye este producto exacto (transporte + GTFS + pagos + 5 roles). Prueba directa: dos personas distintas reconstruyeron el mismo módulo (Tickeador) sin saber que el otro ya lo había hecho — señal de que no había un precedente organizacional claro a seguir. |
| **FLEX** — Development Flexibility | Alto | 2.03 | No hubo gobernanza rígida de requisitos: el mismo ID de requerimiento (p. ej. RQ-65, RQ-78, RQ-80) terminó significando cosas distintas en el backlog "oficial" vs. lo que cada dev interpretó y construyó, sin proceso de aprobación previo. Mucha libertad de interpretación = FLEX alto. |
| **RESL** — Architecture/Risk Resolution | Bajo | 5.65 | Riesgos arquitectónicos centrales quedaron sin resolver hasta el final del sprint: 3 tablas de ruteo por rol coexistiendo e inconsistentes entre sí, reglas de Firestore completamente abiertas (`allow read, write: if true`) hasta los últimos commits, mecanismo de superadmin duplicado con dos listas de emails distintas. |
| **TEAM** — Team Cohesion | Bajo | 4.38 | 27 personas registradas, pero solo 19 llegaron a reportar un daily y 4 nunca lo hicieron — incluida la autora de uno de los dos paneles de Presidente duplicados. Coordinación real por debajo de lo que sugiere el tamaño nominal del equipo. |
| **PMAT** — Process Maturity | Bajo | 6.24 | Existe *algo* de proceso (tracker de tareas/observaciones con estados, dailies, un PM y dos líderes), pero no se aplicó de forma consistente: ~25 ramas se fusionaron manualmente sin rama de integración intermedia, sin gate de revisión antes del merge, y un archivo con credenciales reales llegó a quedar commiteado pese a tener reglas de seguridad documentadas. |

**Cálculo de E:**

```
Σ SFj = 4.96 + 2.03 + 5.65 + 4.38 + 6.24 = 23.26
E = B + 0.01 × Σ SFj = 0.91 + 0.01 × 23.26 = 0.91 + 0.2326 = 1.1426 ≈ 1.14
```

Un E de 1.14 (por encima de 1.0) indica **deseconomías de escala**: al crecer el tamaño del sistema, el esfuerzo crece más que proporcionalmente — consistente con un proyecto donde, en la práctica, duplicar el número de personas no duplicó el avance (se duplicó, literalmente, el trabajo de Tickeador y de Presidente en vez de sumarse).

---

## Parte 3 — Multiplicadores de esfuerzo (EM)

Se eligieron **9 de los 17 drivers** (más de los 6 mínimos pedidos), priorizando los que mejor describen el proyecto real; el resto se deja en Nominal (= 1.00, no afecta el producto):

| Driver | Nivel elegido | EM | Justificación específica al proyecto |
|---|---|---:|---|
| **RELY** — Confiabilidad requerida | Alto | 1.10 | Maneja dinero real de los usuarios (saldo de billetera, cobro de viaje por QR, recargas). Una falla no pone en riesgo vidas (no es Muy Alto), pero sí genera pérdida financiera directa si falla. |
| **CPLX** — Complejidad del producto | Alto | 1.17 | Planificador de viajes multi-tramo (`MultiRoutePlanner`, hasta 3 tramos en bus + caminata, con deduplicación por `ref|directionId`), ingestión GTFS, navegación en tiempo real, y un modelo de permisos con 5 roles distintos. |
| **DATA** — Tamaño de base de datos | Alto | 1.14 | Firestore con ~10+ colecciones activas (`users`, `routes`, `routes_bbox`, `wallets`, `trip_history`, `benefit_requests`, `notifications`, etc.) más una caché SQLite local espejada (`routes_meta`, `app_config`). |
| **PCON** — Continuidad del personal | Bajo | 1.12 | Participación muy despareja: un solo dev concentra 15 de 85 dailies (18%) mientras 4 colaboradores activos nunca reportaron ninguno — baja continuidad efectiva pese al headcount nominal. |
| **ACAP** — Capacidad de analistas | Bajo | 1.19 | Equipo de estudiantes de pregrado en su primer proyecto de este tamaño; evidenciado por decisiones de diseño que se tuvieron que revertir (dos paneles de Presidente, dos Tickeador). |
| **PCAP** — Capacidad de programadores | Bajo | 1.15 | Coherente con ACAP: se encontraron errores de compilación básicos sin resolver por varios días (marcadores de merge sin cerrar, registros duplicados en el inyector de dependencias, argumento nombrado repetido en `MaterialApp`). |
| **TOOL** — Uso de herramientas | Alto | 0.90 | El equipo sí cuenta con tooling por encima del mínimo: un tracker propio (AppScript) para dailies/tareas/observaciones, y asistencia de IA (Claude Code) para refactors y diagnóstico, lo que reduce esfuerzo respecto a un flujo 100% manual. |
| **SCED** — Compresión del cronograma | Bajo | 1.14 | Sprint académico de calendario fijo (turno noche, entregas quincenales) — el tiempo disponible está comprimido respecto a lo que el alcance real hubiera necesitado. |
| **SITE** — Desarrollo multi-sitio | Bajo | 1.09 | Equipo 100% remoto/distribuido, coordinado por WhatsApp + un tracker propio — sin la infraestructura de colaboración "wideband" que premia la tabla (video, herramientas compartidas en tiempo real), lo que explica en parte el trabajo duplicado. |

**Cálculo de ΠEM:**

```
Π EMi = 1.10 × 1.17 × 1.14 × 1.12 × 1.19 × 1.15 × 0.90 × 1.14 × 1.09 ≈ 2.5149
```

---

## Parte 4 — Esfuerzo, cronograma, personal y presupuesto

Constantes del modelo Post-Architecture: **A = 2.94, B = 0.91, C = 3.67, D = 0.28**.

### 4.1 Esfuerzo (PM)

```
PM = A × (Size)^E × Π EMi
PM = 2.94 × (37)^1.1426 × 2.5149
PM = 2.94 × 61.92 × 2.5149
PM ≈ 457.8 persona-mes
```

### 4.2 Exponente de cronograma (F)

```
F = D + 0.2 × (E − B)
F = 0.28 + 0.2 × (1.1426 − 0.91)
F = 0.28 + 0.2 × 0.2326
F = 0.28 + 0.0465
F ≈ 0.3265
```

### 4.3 Tiempo de desarrollo (TDEV)

```
TDEV = C × (PM)^F
TDEV = 3.67 × (457.8)^0.3265
TDEV ≈ 3.67 × 7.393
TDEV ≈ 27.1 meses
```

### 4.4 Personal promedio

```
Personal = PM / TDEV = 457.8 / 27.1 ≈ 16.9 ≈ 17 personas
```

### 4.5 Presupuesto estimado

Costo por persona-mes **(aproximado)**: se usa **Bs 5,000/persona-mes**, una aproximación razonable para un equipo mixto junior/estudiante en Bolivia (no hay dato real de nómina porque el equipo no es remunerado).

```
Presupuesto = PM × costo_persona_mes
Presupuesto = 457.8 × 5,000 Bs
Presupuesto ≈ Bs 2,289,100
```

| Resultado | Valor |
|---|---:|
| Esfuerzo (PM) | ≈ 458 persona-mes |
| Exponente de cronograma (F) | ≈ 0.33 |
| Tiempo de desarrollo (TDEV) | ≈ 27.1 meses |
| Personal promedio | ≈ 17 personas |
| Presupuesto estimado | ≈ Bs 2,289,100 |

---

## Parte 5 — Análisis y reflexión

COCOMO II predice que un sistema del tamaño real de Mi Ruta (37 KSLOC medidos, no estimados) requeriría **≈458 persona-mes**, **≈27 meses** de calendario y un equipo promedio de **≈17 personas** trabajando de forma sostenida y profesional. La comparación con lo que realmente pasó es reveladora, no solo académica: el tracker de seguimiento del propio equipo (`docs/AsyncDaily/Revision QA.xlsx`) muestra que Sprint 3 —donde se construyó la mayor parte de este código— corrió entre el 1 y el 24 de agosto, es decir, **menos de un mes de calendario**, con 27 personas registradas trabajando en paralelo, a tiempo parcial (turno noche, estudiantes) y sin remuneración. En vez de extender el cronograma hacia los ~27 meses que sugiere COCOMO, el equipo comprimió el tiempo agregando gente en paralelo por encima de cualquier curva de incorporación razonable —el número de ramas simultáneas (~25) superó incluso el personal promedio que el propio modelo calcula como sostenible (17)—. Esa es, casi con seguridad, la causa directa de los problemas que documentamos en este mismo proyecto: dos implementaciones completas de Tickeador construidas en paralelo sin saber una de la otra, dos paneles de Presidente compitiendo, tres tablas de ruteo por rol contradictorias entre sí, y hasta un archivo con credenciales reales commiteado por accidente. COCOMO II lo anticipa indirectamente: los factores de escala más bajos que elegimos (RESL, TEAM, PMAT) son exactamente los que penalizan un equipo grande, mal coordinado y con procesos débiles — y el resultado real coincide con lo que esos factores predicen que puede salir mal, aunque el modelo no capture explícitamente el costo de "reconstruir dos veces la misma funcionalidad".

El **factor de mayor impacto potencial** es **PMAT** (madurez de proceso): tiene el rango más amplio de los 5 factores de escala (7.80 puntos, de Muy Bajo a Extra Alto), más que RESL (7.07) o PREC (6.20), y actúa multiplicando el esfuerzo de forma exponencial a través de E, no linealmente. A nivel de multiplicadores de esfuerzo, **CPLX** tiene el rango más amplio (0.73–1.74, un factor de 2.4× entre el mejor y el peor caso), lo cual es coherente con que la complejidad real del planificador de viajes y el modelo de 5 roles es, objetivamente, la parte más difícil de construir bien del sistema.

La limitación más honesta de este ejercicio es que se aplicó **después** de escribir el código, no antes: se midió el tamaño real en vez de proyectarlo, así que esto funciona como una calibración retrospectiva del modelo contra la realidad, no como una predicción a ciegas. COCOMO II tampoco modela bien un equipo voluntario, part-time y radicalmente sobre-paralelizado como este — sus constantes están calibradas contra proyectos industriales con ingenieros de tiempo completo, así que el presupuesto de ~Bs 2.29 millones no representa lo que este proyecto costó realmente (cero, en términos de nómina), sino lo que costaría construirlo de forma profesional y disciplinada. Frente a una estimación intuitiva —contar horas reportadas por persona en los dailies, que darían un número mucho menor, quizás 10-20 persona-mes reales—, COCOMO II aporta lo que la intuición no puede: una cifra objetiva, reproducible y comparable con otros proyectos, aunque a costa de asumir un contexto de ejecución que este proyecto, al ser académico y voluntario, no tuvo.

*(Palabras: ~430)*
