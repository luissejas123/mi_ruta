# Informe de avance — Sprint (Admin / Presidente / Chofer / Usuario)

**Fecha:** 26 de agosto de 2026
**Rama analizada:** `dev-jesus-villarroel` (integra ~25 ramas personales vía merges manuales)
**Fuentes:** código fuente, `git log --merges`, y `docs/AsyncDaily/Revision QA.xlsx` (hojas `USUARIOS`, `DAILY_SCRUM`, `TAREAS`, `OBSERVACIONES`, `BACKLOG`) — la base de datos del AppScript de seguimiento del equipo.
**Objetivo del sprint (dado):** completar los perfiles Admin, Presidente, Chofer y Usuario. Tickeador queda para el final.

## 1. Resumen ejecutivo

- **Usuario** y **Admin** son los módulos más maduros: datos reales (Firestore/SQLite), sin datos hardcodeados de por medio.
- **Chofer** tiene casi todas sus piezas construidas, pero además carga funcionalidad de supervisión que en realidad pertenece a **Presidente** (ver §4).
- **Presidente** es el rol menos maduro de los cuatro objetivo del sprint: existen **dos paneles distintos** construidos por separado, y dos de sus tres secciones muestran datos vacíos o hardcodeados en producción. El propio QA lo señaló el 17 de agosto ("reutiliza la interfaz de chofer, no es necesario para este perfil") y el propio dev lo confirmó el 24 de agosto ("lo que sigue, pruebas reales no datos ficticios").
- **Tickeador**, que se suponía debía esperar, ya tiene **dos implementaciones completas corriendo en paralelo**, ambas registradas en el inyector de dependencias al mismo tiempo. Esto no es solo un hallazgo de código: el propio desarrollador lo relata en su daily del 20 de agosto, al notar que una versión "perdió" funcionalidad de la otra durante un merge.
- Encontramos la causa raíz de la mezcla Sprint 3/Sprint 4 que reportaste: el `BACKLOG` oficial reutiliza los IDs **RQ-61 a RQ-90** para el trabajo de integración final de Sprint 4, pero esos mismos IDs ya se usaron durante Sprint 3 (en `TAREAS`, en los dailies y en los commits de git) para features completamente distintas de Chofer/Tickeador/Presidente. Detalle en §5.
- De las 83 tareas de Sprint 3 en el tracker, **59% siguen en `EN_REVISION`** (no cerradas); de las 76 observaciones de QA, **54% siguen abiertas** en algún estado. El bloqueo más repetido, transversal a devs y RQs, es la falta de acceso a Firebase/Firestore para validar contra datos reales (§7).
- El problema de fondo no es "falta de código": es integración. ~25 ramas personales se fusionaron a mano sin una tabla de ruteo por rol compartida, así que distintas personas construyeron su propia pantalla de destino sin saber que ya existía una equivalente — y sin visibilidad cruzada, porque no todo el equipo reportaba dailies (§2).

## 2. Quiénes reportaron y cómo

El tracker registra 23 cuentas activas (`USUARIOS`, columna `Activo`), con roles DEV, QA, PM, `LIDER_DEV` (Luis Zurita) y `LIDER_QA` (Nicolas Uchani). De esas 23, solo **19 llegaron a escribir al menos un daily**; **Sejas Sánchez, Cristian Claros, Susana Rodríguez y Carlos Ugarte nunca reportaron uno**. Esto importa porque **Susana Rodríguez** es autora del commit `4b0724b` ("perfil Administrativo", el último merge en la rama) que construyó una versión del panel de Presidente — sin daily de por medio, nadie tuvo visibilidad de que ya se estaba construyendo un segundo panel para ese rol.

Participación desigual: **Pedro Chucamani** concentra 15 de los 85 dailies registrados (18%) y es quien más carga de Chofer/Tickeador/Notificaciones lleva; le siguen Wili Chambi (9) y Humberto Aponte (7). La mayoría del resto del equipo reportó 2–3 veces en todo el periodo. Algunos dailies de los líderes son de una sola palabra ("Revise" / "Entender" — Nicolás Uchani, `LIDER_QA`; "Nada" / "Rezar" — Luis Zurita, `LIDER_DEV`, ambos el 10 de agosto), lo que sugiere un día particularmente pesado para el equipo, no necesariamente falta de trabajo real ese día.

## 3. Estado por rol

| Rol | Datos | UI | Ruteo real al iniciar sesión | Tracker (Sprint 3) | Veredicto |
|---|---|---|---|---|---|
| Usuario | Firestore + SQLite (GTFS) real | 25+ páginas: mapa, wallet, QR, beneficios, notificaciones, historial | Consistente en los 3 flujos | RQ-31 a RQ-60, mayoría `CERRADO`/`EN_REVISION` avanzado | Completo funcionalmente |
| Admin | Datasources reales para usuarios, rutas, privilegios, reportes | Dashboard, gestión de usuarios/rutas, privilegios | Consistente en los 3 flujos | RQ-71 (gestión de usuarios) `EN_PROCESO`, ALTA: "faltan opciones para la gestión completa" | Casi completo — falta 1 enlace y cerrar RQ-71 (ver §4, §6) |
| Chofer | Vehículo, ingresos, rutas asignadas, historial, operaciones de tickeador — todo con datasource real | `driver_home_page.dart` + 6 páginas más | **Inconsistente entre los 3 flujos** (§4) | 10 tareas en "Operación del Chofer", mayoría `EN_REVISION`; RQ-69 (ingresos) marcado "solo está la pantalla principal" | Funcionalmente avanzado, pero mezclado con Presidente y con varias tareas sin cierre confirmado por QA |
| Presidente | Servicio propio solo lee SQLite de rutas; el resto es mock o depende de servicios de Admin | **Dos paneles distintos** compitiendo (§4) | **Inconsistente y distinto según el flujo** (§4) | RQ-76/77/80 "Supervisión y Control de Rutas", `EN_PROCESO`/`EN_REVISION`, sin comentarios de cierre | El más débil de los cuatro objetivo del sprint |
| Tickeador (fuera de alcance) | Dos datasources/servicios paralelos | Dos features completas | — | RQ-78/79 "Gestión de Tickeador", `EN_REVISION`; QA: "nomás está el scanner, falta todo" (11 ago) → dev: "finalicé la integración" (21 ago) | Duplicado activamente; ya tuvo una regresión real por el duplicado (§4) |

## 4. Bug crítico: tres tablas de ruteo por rol que no coinciden

Hay **tres** lugares distintos que deciden a qué pantalla va un usuario según su `role`, y **ninguno coincide con los otros dos**:

| Origen | Archivo | admin | presidente | driver | resto |
|---|---|---|---|---|---|
| Reapertura de la app / sesión restaurada | `lib/main.dart` (`_AuthGate`) | `AdminHomePage` | `MiRutaScreen` (pantalla de pasajero) | `MiRutaScreen` | `MiRutaScreen` |
| Registro / recuperación de acceso | `lib/core/navigation/home_router.dart` (`homeScreenForRole`) | `AdminPrivilegesPage` | `PresidenteHomePage` | `MiRutaScreen` | `MiRutaScreen` |
| Login manual | `lib/features/auth/presentation/pages/iniciar_sesion_page.dart` | `AdminHomePage` | `AdminHomePage` | `DriverHomePage` | `MiRutaScreen` |

Consecuencias concretas:
- Un chofer o presidente que **cierra y vuelve a abrir la app con sesión activa** cae en la pantalla de pasajero normal, no en la suya.
- Un presidente que **inicia sesión manualmente** cae en `AdminHomePage` (la pantalla de perfil administrativo), no en ningún panel de presidente.
- Solo el flujo de **registro** lleva a un presidente a `PresidenteHomePage`, que además no es el panel que `DriverHomePage` y `SuperAdminSwitcherPage` esperan (ver más abajo).
- `home_router.dart` incluso trae un comentario que dice *"Usar siempre que se navegue a la pantalla principal tras login/registro, para no duplicar el criterio de enrutamiento por rol"* — pero `main.dart` y `iniciar_sesion_page.dart` no lo usan.

Esto probablemente pasó desapercibido en QA porque existe `SuperAdminSwitcherPage` (`lib/features/admin/presentation/pages/super_admin_switcher_page.dart`), una herramienta de super-admin que navega directo a cada pantalla de rol saltándose el login real — útil para demos, pero enmascara que el ruteo real por rol está roto.

**Recomendación:** unificar en un único punto (`home_router.dart` ya es el candidato correcto por diseño) y hacer que `main.dart` e `iniciar_sesion_page.dart` lo usen en vez de mantener su propia copia del switch.

### Duplicidades relacionadas

1. **Tickeador implementado dos veces, con una regresión real de por medio.** `lib/features/tickeador/**` (Clean Architecture completa) y `lib/features/driver/**tickeador_operations**` (subset dentro de Chofer) están **ambas activas en `dependency_injection.dart`** al mismo tiempo. Esto no quedó solo en el código: el propio Pedro Chucamani lo narra en su daily del **20 de agosto**: *"Identifiqué funcionalidades que se habían perdido, como la validación mediante QR, historial de verificaciones y navegación"* al comparar la versión que encontró contra "la versión original del proyecto" — es decir, un merge posterior sobrescribió trabajo de Tickeador ya hecho, y tuvo que reconstruirlo. El comentario de cierre de la tarea RQ-78 (21 ago, `TASK_1786162632219`) describe exactamente la reconstrucción de la versión que hoy vive en `lib/features/tickeador/**`, mientras que la versión dentro de `driver/` (rama `katy`, RQ-79/63/74) sigue sin retirarse.
2. **`VehicleEntity` definida dos veces**: `lib/features/driver/domain/entities/vehicle_entity.dart` y `lib/features/tickeador/domain/entities/vehicle_entity.dart`.
3. **Panel de Presidente construido dos veces, y QA ya lo notó.** `PresidenteHomePage` (pestañas Rutas/Unidades/Reportes) solo muestra datos en Unidades/Reportes si el usuario es el UID de prueba estático `testPresidenteUid` (datos hardcodeados de `static_test_accounts.dart`, no Firestore). `PresidentePanelPage`, en cambio, usa `AdminService`/`RouteService` reales y es al que navegan `DriverHomePage` y el switcher de super-admin. La observación **OBS_1786993447887** (David Villarroel, QA, 17 ago, sobre RQ-80) dice textualmente: *"Aunque reutiliza la interfaz de chofer no es necesario para este perfil. Complementar opciones de verificación de documentación para 'Aprobar choferes'"* — QA detectó en producto exactamente lo que el código confirma: Presidente hereda la pantalla de Chofer (`DriverHomePage` con `isSupervisor = role == 'presidente'`) en vez de tener una propia consolidada. El daily de **Humberto Aponte** (24 ago, autor de RQ-80) lo resume así: *"se realizó que el rol presidente pueda entrar y ver el estado de las rutas, unidades y reportes, solo es vista no edita nada [...] lo que sigue, pruebas reales no datos ficticios"* — confirmando en primera persona que hoy usa datos ficticios.
4. **"Aprobar choferes" vive dentro de Chofer, no de Admin (ni de Presidente).** `driver_approval_page.dart` solo se referencia desde `driver_home_page.dart` y desde el switcher de super-admin. Ni el panel de Admin ni el de Presidente tienen un enlace hacia esa pantalla, pese a que QA pidió explícitamente conectarla desde el flujo de Presidente (ver punto 3).

## 5. La colisión de numeración: por qué Sprint 3 y Sprint 4 se ven mezclados

Esta es la causa concreta detrás de la sensación de "inconsistencia entre Sprint 3 y 4": la hoja `BACKLOG` define Sprint 4 (RQ-61 a RQ-90) como una segunda ronda de **integración y optimización** ("Integración Usuario–Conductor", "Integración Usuario–Tickeador", "Integración Administración–Presidente", "Pruebas de regresión", "Validación final"...). Pero esos mismos números de RQ **ya se usaron durante Sprint 3** — en `TAREAS`, en los dailies y en los commits de git — para features completamente distintas de Chofer, Tickeador y Presidente. El mismo ID significa dos cosas distintas según qué hoja se mire:

| RQ | `BACKLOG` (oficial, Sprint 4) | Lo que realmente se rastreó como "RQ-xx" en Sprint 3 (`TAREAS`/dailies/commits) |
|---|---|---|
| RQ-61 | Inicio de jornada del conductor | *(coincide en tema, pero `TAREAS` ya lo cerró en Sprint 3.0, no 4.0)* |
| RQ-63 | Consulta de rutas asignadas (dev: Uchani Nicolás) | Visualización de rutas asignadas al chofer, Sprint 3.0 (dev real: Wili Chambi / Katerine Pinto) |
| RQ-65 | Registro de incidencias del recorrido (dev: Huarachi Nayeli) | **Cobro de viaje mediante el módulo del chofer**, Sprint 3.0 (dev real: Jheymi Alex Villca, commit `53f7f73` "RQ-65 Cobro del viaje mediante el código de chofer") — requisito totalmente distinto bajo el mismo número |
| RQ-66 | Validación de pago mediante QR (Tickeador) (dev: Torrico Eddy) | Notificación de llegada o parada durante el servicio, Sprint 3.0 (dev real: Dago Uribe) |
| RQ-76 | Integración Usuario–Conductor | **Control de rutas desde el perfil administrativo/presidente**, Sprint 3.0 — la base del panel de Presidente |
| RQ-77 | Integración Usuario–Tickeador | Consulta de reportes operativos, Sprint 3.0 |
| RQ-78 | Integración Administración–Presidente | **Operación del modo Tickeador para validación de viajes**, Sprint 3.0 — la feature Tickeador duplicada de §4 |
| RQ-80 | Optimización del rendimiento general | Consulta consolidada de información desde el perfil Presidente, Sprint 3.0 (dev real: Humberto Aponte) |

En otras palabras: el trabajo de Chofer/Tickeador/Presidente que el equipo ya construyó y siguió en Sprint 3 tomó prestados los IDs RQ-61 a RQ-80 del backlog de Sprint 4, sin que el backlog se haya actualizado para reflejarlo. Esto es exactamente el terreno donde aparece la duplicidad de Tickeador y de Presidente (§4): dos personas trabajando bajo el mismo número de RQ pero interpretando dos requisitos distintos (uno "real" ejecutado en Sprint 3, otro "oficial" planeado para Sprint 4) tenían muy pocas probabilidades de encontrarse.

**Recomendación:** renumerar el trabajo ya hecho en Sprint 3 con IDs propios (o formalizar que RQ-61…RQ-80 quedaron "adelantados" desde Sprint 4) antes de arrancar la siguiente ronda, para que el backlog de Sprint 4 no vuelva a chocar con trabajo que ya existe.

## 6. Bloqueo transversal: falta de acceso a Firebase/Firestore

En los dailies, 6 de 85 entradas mencionan explícitamente Firebase/Firestore como bloqueo, y 28 de 85 (33%) tienen algo distinto de "No" en `NECESITO_AYUDA_DE`. El patrón se repite en RQs de distintos módulos y por distintos devs — no es un caso aislado:

- **RQ-36** (próximas salidas, Pedro Chucamani, 4 ago): *"Mi cuenta no tiene acceso al proyecto Firebase existente [...] Solicito acceso al proyecto Firebase de MiRuta"*.
- **RQ-44** (alertas push, Pedro Chucamani, 8 y 23 ago, dos veces): *"No cuento con permisos de acceso a la consola Firebase [...] no tengo acceso a Firebase Console ni a un emisor FCM para realizar pruebas de envío"*.
- **RQ-67** (historial de viajes del chofer, Pedro Chucamani, 21 y 24 ago): *"No se dispone actualmente de una cuenta de prueba con rol conductor ni acceso a Firebase [...] Se necesita acceso actualmente a una cuenta de chofer para realizar la prueba funcional"*.
- **RQ-78** (Tickeador, Pedro Chucamani, 8 y 21 ago): *"No tengo acceso a Firebase Console/Firestore ni a las credenciales necesarias [...] la validación completa contra datos reales de Firebase no pudo finalizar"*.
- **Cierre general** (Pedro Chucamani, 24 ago): *"No fue posible realizar una validación visual completa desde la aplicación debido a la falta de accesos a las cuentas y servicios necesarios"*.

Es decir: buena parte de lo que en `TAREAS` figura como implementado está **completo en código pero sin validar contra datos reales**, no porque falte trabajo de desarrollo sino porque quien lo construyó no tiene las credenciales para probarlo de punta a punta. Esto explica en parte por qué el 59% de las tareas de Sprint 3 sigue en `EN_REVISION`.

**Recomendación:** el `LIDER_DEV`/PM debería auditar y otorgar accesos de Firebase Console (o cuentas de prueba con roles específicos: chofer, tickeador, presidente) a quienes lo han solicitado repetidamente, en particular a Pedro Chucamani, antes de pedir más features nuevas — es el cuello de botella más citado del sprint.

## 7. Conflicto de pruebas: Chrome/navegador vs. dispositivo móvil

La suite en `test/` tiene 5 archivos, todos unit/widget tests puros con `mocktail` (sin Firebase, sin plugins nativos, sin carpeta `integration_test/`) — por sí sola no explica el conflicto que describes; no encontramos en el tracker de QA observaciones que mencionen Chrome explícitamente. El conflicto real está en la validación manual, donde varios plugins tienen comportamiento **fundamentalmente distinto** entre Chrome de escritorio y un dispositivo real:

| Plugin / flujo | En Chrome | En dispositivo móvil |
|---|---|---|
| `sqflite` (caché GTFS local, `RouteDataSyncService`) | Sin soporte web real sin `sqflite_common_ffi_web`; puede fallar silenciosamente o comportarse distinto | Camino de código real de producción |
| `mobile_scanner` (QR: `pago_qr_page`, `qr_scanner_page`, `recarga_qr_page`) | Usa `getUserMedia` del navegador | Usa la cámara nativa; permisos y latencia distintos |
| `geolocator` | Geolocation API del navegador, un solo prompt | Permisos runtime de Android/iOS (ya documentado como gotcha del proyecto en `CLAUDE.md`) |
| `image_picker` (subir foto de documento) | Selector de archivos del SO de escritorio | Cámara/galería nativa |

Vale la pena notar que el daily de **Pedro Chucamani (RQ-36, 4 ago)** confirma el mismo tipo de fricción por el lado opuesto: *"Actualmente no puedo ejecutar la aplicación en Chrome porque falta la configuración Firebase Web (firebase_options.dart)"* — algunos devs no pueden validar en absoluto en Chrome y trabajan solo contra dispositivo, mientras otros (como Mario Bráñez, RQ-38/43/70) sí documentan explícitamente *"se dejó probada la aplicación corriendo directamente en un teléfono físico Android"* como buena práctica ya adoptada por al menos parte del equipo.

**Recomendación priorizada:** tratar los casos de QR, caché GTFS offline, geolocalización y subida de foto como bugs de alta prioridad "por solucionar" en este sprint, y establecer que la validación manual final de estos flujos se haga siempre en un dispositivo/emulador real — Chrome queda solo para iteración rápida de UI durante el desarrollo, no como criterio de aceptación.

## 8. Salud del tablero de QA (observaciones de higiene, no de producto)

- **83 tareas** de Sprint 3 en el tracker: 49 `EN_REVISION` (59%), 21 `CERRADO`, 13 `EN_PROCESO`. **76 observaciones** de QA: 35 `CERRADO`, 20 `ABIERTO`, 12 `EN_PROCESO`, 9 `EN_REVISION` — 54% aún sin cerrar.
- Solo **3 observaciones ALTA/CRÍTICA siguen abiertas**: RQ-32 (reprogramar viaje, error al retroceder — CRÍTICA), RQ-58 (texto de botón "confirmar destino" no cambia a "confirmar origen"), y **RQ-71 (gestión de usuarios del administrador — "aún faltan opciones para la gestión completa")**, que corrobora directamente el hallazgo de código de que Admin está casi completo pero no del todo.
- **Comentarios duplicados/espejo:** varias tareas tienen el mismo comentario repetido 2–4 veces en segundos (p. ej. RQ-67 tres veces idéntico de Pedro Chucamani, RQ-69 cuatro veces "Solo está la pantalla principal" de Nataly Mallea) — probablemente un doble-envío del formulario del AppScript, no información nueva. No afecta el contenido de este informe, pero conviene limpiarlo para que las métricas de actividad del tablero no queden infladas.
- **Cierres sin verificación aparente:** varias tareas ALTA (p. ej. RQ-64, RQ-65) se mueven a `EN_REVISION` con un comentario de una palabra del dev ("hecho", "ya lo hice") y sin comentario de QA de vuelta — no hay evidencia en el tracker de que alguien haya re-probado antes de considerarlas avanzadas.
- **Taxonomía de `MODULO` inconsistente:** existen variantes duplicadas del mismo módulo por errores de tipeo ("Modulo Registro e inicio de secion" vs "Modulo registro e inicio de sesión" vs "Modulo De Registro Inicio De Sesion Y Recuperacion De Contraseña"), lo que dificulta agregar métricas reales de avance por módulo sin normalizar el campo primero.

## 9. Por qué pasó esto (observación de proceso)

`git log --merges` muestra 25+ ramas personales fusionadas manualmente, una por una, hacia `dev-jesus-villarroel`, sin una rama de integración intermedia donde se hubiera detectado el ruteo duplicado o el Tickeador duplicado antes de llegar aquí. Cada duplicidad encontrada en este informe corresponde exactamente a un par de personas/ramas que resolvieron el mismo problema por separado, sin visibilidad cruzada — reforzado por el hecho de que 4 de 23 colaboradores activos (incluida Susana Rodríguez, autora de uno de los dos paneles de Presidente) nunca reportaron un daily, y por la colisión de numeración RQ de §5 que hizo que Sprint 3 y Sprint 4 compitieran por los mismos identificadores.

## 10. Recomendaciones priorizadas

1. **(Alta)** Unificar el ruteo por rol en `home_router.dart` y usarlo desde `main.dart`, login y registro — hoy son 3 tablas distintas.
2. **(Alta)** Decidir cuál de los dos paneles de Presidente es el definitivo (`PresidenteHomePage` vs `PresidentePanelPage`) y retirar el otro; conectar "Aprobar choferes" desde ahí, como pidió QA en RQ-80.
3. **(Alta)** Decidir cuál implementación de Tickeador es la base (`features/tickeador` vs `features/driver/*tickeador_operations*`) y congelar/eliminar la otra antes de retomarlo, para no volver a perder funcionalidad en un merge como ya ocurrió el 20 de agosto.
4. **(Alta)** Otorgar accesos de Firebase Console / cuentas de prueba por rol a los devs bloqueados (Pedro Chucamani en particular) — es el cuello de botella más repetido y está frenando el cierre de tareas ya codificadas.
5. **(Alta)** Renumerar o formalizar el traslape de RQ-61 a RQ-80 entre Sprint 3 (ya ejecutado) y Sprint 4 (planeado en `BACKLOG`) antes de arrancar la siguiente ronda.
6. **(Media)** Cerrar las 3 observaciones ALTA/CRÍTICA abiertas: RQ-32, RQ-58, RQ-71.
7. **(Media)** Definir protocolo de QA: los casos con cámara, GPS o almacenamiento local se validan en dispositivo real, no solo en Chrome.
8. **(Media)** Higiene del tablero: deduplicar comentarios repetidos, normalizar el campo `MODULO`, y exigir un comentario de QA (no solo del dev) antes de mover una tarea ALTA fuera de `EN_REVISION`.
9. **(Baja)** Completar las pestañas "Unidades" y "Reportes" del panel de Presidente elegido con datos reales de Firestore, hoy dependen del UID de prueba estático.
