# Requerimientos por Perfil — Sprint 3 (real) y Propuesta Sprint 4

**Fecha:** 27 de agosto de 2026
**Fuente de datos:** `docs/AsyncDaily/Revision QA.xlsx` (hojas `TAREAS`, `BACKLOG`, `OBSERVACIONES` — la base real del AppScript de seguimiento), cruzado con el código fuente y con `docs/COMPARACION_FIGMA_CODIGO_DOCS.md`.
**Objetivo:** reorganizar los requerimientos de Sprint 3 **por perfil** (siguiendo el flujo real de Usuario/Chofer/Administrador/Presidente/Tickeador que existe en Figma), en vez de por rango numérico ciego de RQ — y a partir de eso, proponer un Sprint 4 que no vuelva a chocar con la numeración ya usada.
**Versión visual (Artifact):** https://claude.ai/code/artifact/89f44423-4f57-46d4-9ba2-b5678fff2af4 — el mismo contenido de este documento agrupado por perfil, con capturas reales de Figma y el nombre de quién trabajó cada RQ. Es privado por defecto: compártelo con el equipo desde el menú de la página (⋯ → Compartir) cuando lo necesites. Nodos de Figma usados para las capturas, en el Anexo (§6).

> Este documento asume como leídos `docs/INFORME_AVANCE_SPRINT.md` (diagnóstico de duplicidades) y `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` (comparación diseño↔código↔docs). Aquí se cruza todo eso con el **tracker real de tareas**, no solo con el código.

---

## 0. Aviso importante sobre el flujo de jerarquía que describiste

El flujo de roles que planteaste (Admin crea admins/gestiona usuarios/da privilegio de Presidente → Presidente aprueba choferes/asigna tickeadores → Usuario se registra como chofer) **no existe como requerimiento explícito en el backlog de Sprint 3** (`BACKLOG`, `TAREAS`). Lo que sí existe son piezas sueltas que se le parecen (RQ-71 a RQ-75 "Administración del Sistema", RQ-76/77/80 "Supervisión y Control de Rutas"), pero la cadena de privilegios completa que describes nunca fue un ítem del tracker — es una definición de producto que estás dando ahora. Por eso el código no la implementa (ver `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` §9): no es que se haya perdido, es que nunca se pidió así de explícito. Este documento la incorpora recién en la propuesta de Sprint 4 (§4).

---

## 1. Sprint 3 — Requerimientos reales, organizados por perfil

Los 30 tareas granulares de Sprint 3 en el tracker (`TAREAS`, IDs `TASK_1784908122720`…`TASK_1786162632221`) ya estaban agrupadas por `MODULO`, y esos módulos **coinciden 1:1 con los perfiles de Figma**. Aquí se listan tal cual están en el tracker, con su estado real.

### 1.1 Usuario — RQ-31 a RQ-60 (30 requerimientos, 6 módulos)

| RQ | Descripción | Estado | Prioridad |
|---|---|---|---|
| RQ-31 | Programación inteligente de viajes | EN_REVISION | Alta |
| RQ-32 | Reprogramación de un viaje planificado | EN_REVISION | Media |
| RQ-33 | Cancelación de un viaje programado | EN_PROCESO | Media |
| RQ-34 | Consulta del historial de viajes | EN_REVISION | Alta |
| RQ-35 | Visualización del detalle de un viaje | CERRADO | Media |
| RQ-36 | Consulta de próximas salidas | CERRADO | Alta |
| RQ-37 | Visualización de paradas cercanas | CERRADO | Alta |
| RQ-38 | Consulta de información de una parada | EN_REVISION | Media |
| RQ-39 | Visualización del tiempo estimado de llegada | EN_REVISION | Alta |
| RQ-40 | Actualización dinámica del recorrido | EN_REVISION | Alta |
| RQ-41 | Consulta de notificaciones recibidas | EN_PROCESO | Alta |
| RQ-42 | Marcar notificaciones como leídas | EN_REVISION | Media |
| RQ-43 | Eliminación de notificaciones | EN_REVISION | Baja |
| RQ-44 | Recepción automática de alertas operativas | EN_REVISION | Alta |
| RQ-45 | Configuración de preferencias de notificación | EN_REVISION | Media |
| RQ-46 | Consulta del estado de beneficios | EN_REVISION | Alta |
| RQ-47 | Renovación de solicitud de beneficio | EN_REVISION | Media |
| RQ-48 | Cancelación de solicitud de beneficio | CERRADO | Baja |
| RQ-49 | Consulta del historial de beneficios | EN_REVISION | Media |
| RQ-50 | Descarga de comprobantes digitales | CERRADO | Media |
| RQ-51 | Configuración de preferencias de usuario | EN_REVISION | Baja |
| RQ-52 | Visualización de Términos/Condiciones/Privacidad | EN_PROCESO | Baja |
| RQ-53 | Configuración de tema claro/oscuro | EN_REVISION | Baja |
| RQ-54 | Sincronización automática de datos | EN_REVISION | Alta |
| RQ-55 | Actualización automática del perfil | EN_REVISION | Media |
| RQ-56 | Manejo de pérdida de conexión | EN_REVISION | Alta |
| RQ-57 | Recuperación automática al restablecer conexión | EN_REVISION | Alta |
| RQ-58 | Validación integral del módulo Usuario | EN_REVISION | Alta |
| RQ-59 | Corrección de incidencias del Sprint 2 | CERRADO | Alta |
| RQ-60 | Integración de módulos 4, 7 y 8 | EN_REVISION | Alta |

**Balance:** 6 CERRADO, 3 EN_PROCESO, 21 EN_REVISION.

**Observaciones QA relevantes abiertas/sin cerrar del lado Usuario:**
- **RQ-47** (`OBS_1785795118766`): *"Todavía no se cuenta con el rol para recibir la autorización del beneficio"* — bloqueado porque, igual que con las recargas (`docs/COMPARACION_FIGMA_CODIGO_DOCS.md` §10.4), **tampoco existe pantalla de admin para aprobar `benefit_requests`** (confirmado: `grep` de "benefit"/"beneficio" en `lib/features/admin` no da resultados).
- **RQ-58** (`OBS_1785795844900`, ALTA, abierta): el botón mantiene el texto "confirmar destino" cuando debería decir "confirmar origen" según el contexto.
- **Recarga QR** (`OBS_1785877419847`): permite ingresar un monto sin límite — el saldo llega a mostrarse como `1e+39`. Bug de validación de formulario, no de lógica de negocio.
- Cobertura de pantallas vs Figma: ver `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` §2 — buena cobertura, huecos en calificación al conductor y estadísticas del pasajero.

### 1.2 Chofer — RQ-61 a RQ-70 ("Operación del Chofer", 10 requerimientos)

| RQ | Descripción | Estado | Prioridad |
|---|---|---|---|
| RQ-61 | Inicio del servicio de transporte por parte del chofer | CERRADO | Alta |
| RQ-62 | Detención del servicio de transporte por parte del chofer | EN_REVISION | Alta |
| RQ-63 | Visualización de rutas asignadas al chofer | EN_REVISION | Alta |
| RQ-64 | Gestión de unidades de transporte | EN_REVISION | Alta |
| RQ-65 | Cobro de viaje mediante el módulo del chofer | EN_REVISION | Alta |
| RQ-66 | Notificación de llegada o parada durante el servicio | CERRADO | Media |
| RQ-67 | Consulta del historial de viajes realizados por el chofer | EN_REVISION | Media |
| RQ-68 | Consulta del rendimiento del chofer | EN_REVISION | Media |
| RQ-69 | Consulta del historial de ingresos del chofer | EN_REVISION | Alta |
| RQ-70 | Descarga de información del historial del chofer | CERRADO | Baja |

**Balance:** 3 CERRADO, 7 EN_REVISION.

**Observaciones QA relevantes:**
- **RQ-68** (`OBS_1786400466893`, 2026): QA lo dice explícitamente — *"Aún no existe una opción que permita cambiar el rol de Pasajero a Chofer"*. Esto es exactamente el hueco que ya habíamos confirmado en código (`register_page.dart:92` fija `role: 'user'` a fuego) — **QA ya lo había detectado de forma independiente**, antes de que lo pidieras como requisito de jerarquía.
- **RQ-65** (Cobro de viaje mediante módulo del chofer) es la raíz de la duplicidad de Tickeador: la implementación real vive repartida entre `features/tickeador/` y `features/driver/*tickeador_operations*` (ver `docs/INFORME_AVANCE_SPRINT.md` §4.1).
- **RQ-64** (Gestión de unidades): el dominio de vehículos existe (`VehicleEntity`, `driver_vehicle_bloc.dart`) pero, como se documentó en `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` §3, **no hay pantalla de alta de vehículo/verificación de documentos** — coincide con que este RQ sigue EN_REVISION.

### 1.3 Administrador — RQ-71 a RQ-75 ("Administración del Sistema", 5 requerimientos)

| RQ | Descripción | Estado | Prioridad |
|---|---|---|---|
| RQ-71 | Gestión de usuarios por parte del administrador | EN_PROCESO | Alta |
| RQ-72 | Aprobación o bloqueo de usuarios | EN_REVISION | Alta |
| RQ-73 | Gestión de administradores del sistema | EN_PROCESO | Alta |
| RQ-74 | Configuración de privilegios de administrador | EN_REVISION | Alta |
| RQ-75 | Consulta de unidades activas | EN_REVISION | Alta |

**Balance:** 0 CERRADO, 2 EN_PROCESO, 3 EN_REVISION — es el módulo con **mayor proporción de tareas sin cerrar** de los cinco perfiles, pese a que `docs/INFORME_AVANCE_SPRINT.md` lo describe como el rol "casi completo" en términos de código real (Firestore, sin mocks).

**Observación QA relevante:**
- **RQ-71** (`OBS_1786993058385`, ALTA, aún abierta): *"Se tiene la lectura de la base de datos y se puede manipular quiénes tienen acceso [...]"* — funcional pero incompleto; coincide con la observación ya citada en `docs/INFORME_AVANCE_SPRINT.md` §8 ("aún faltan opciones para la gestión completa").
- Ninguno de estos 5 RQ menciona explícitamente "promover a Presidente" ni "aprobar choferes desde Admin" — confirma el §0: la jerarquía completa nunca fue parte del alcance original.

### 1.4 Presidente — RQ-76, RQ-77, RQ-80 ("Supervisión y Control de Rutas", 3 requerimientos)

| RQ | Descripción | Estado | Prioridad |
|---|---|---|---|
| RQ-76 | Control de rutas desde el perfil administrativo/presidente | EN_PROCESO | Alta |
| RQ-77 | Consulta de reportes operativos | EN_REVISION | Media |
| RQ-80 | Consulta consolidada de información desde el perfil Presidente | EN_REVISION | Alta |

**Balance:** 0 CERRADO — es, junto con Tickeador, el perfil con **cero requerimientos cerrados** en todo Sprint 3.

**Observaciones QA relevantes:**
- **RQ-77** (`OBS_1786992928164`): *"sería recomendable modificar la descripción del requisito"* — el propio QA marca que el RQ tal como está redactado ya no describe bien lo que se construyó.
- **RQ-80** (`OBS_1786993447887`, la más importante de todo el perfil): *"Cambiar el título a Presidente. Aunque reutiliza la interfaz de chofer no es necesario para este perfil [...]"* — QA detectó en producto, el mismo día, exactamente lo que el código confirma: Presidente hereda `DriverHomePage`, y hay dos paneles compitiendo (`PresidenteHomePage` vs `PresidentePanelPage`, ver `docs/INFORME_AVANCE_SPRINT.md` §4.3).

### 1.5 Tickeador — RQ-78, RQ-79 ("Gestión de Tickeador", 2 requerimientos)

| RQ | Descripción | Estado | Prioridad |
|---|---|---|---|
| RQ-78 | Operación del modo Tickeador para validación de viajes | EN_REVISION | Alta |
| RQ-79 | Consulta del historial de operaciones del Tickeador | EN_REVISION | Media |

**Balance:** 0 CERRADO. El perfil con **menos requerimientos asignados** (solo 2), y aun así terminó **duplicado en dos implementaciones completas** (`features/tickeador/` vs `features/driver/*tickeador_operations*`), ambas activas en `dependency_injection.dart` — ver `docs/INFORME_AVANCE_SPRINT.md` §4.1 para el detalle de la regresión real que esto causó el 20 de agosto.

---

## 2. Resumen cuantitativo por perfil

| Perfil | RQs Sprint 3 | Cerrados | En proceso | En revisión | Observaciones ALTA/CRÍTICA aún abiertas |
|---|---|---|---|---|---|
| Usuario | 30 | 6 (20%) | 3 | 21 | RQ-58 (botón), RQ-32 (CRÍTICA, retroceder al reprogramar) |
| Chofer | 10 | 3 (30%) | 0 | 7 | — |
| Administrador | 5 | 0 (0%) | 2 | 3 | RQ-71 (gestión incompleta) |
| Presidente | 3 | 0 (0%) | 1 | 2 | RQ-80 (paneles duplicados) |
| Tickeador | 2 | 0 (0%) | 0 | 2 | — |
| **Total (perfiles)** | **50** | **9 (18%)** | **6** | **35** | |

**Lectura:** entre más "abajo" en la jerarquía de roles (Admin → Presidente → Tickeador), **menos requerimientos se le asignaron y ninguno se cerró** — coincide exactamente con el veredicto de `docs/INFORME_AVANCE_SPRINT.md` ("Presidente es el más débil de los cuatro objetivo del sprint", "Tickeador ya tuvo una regresión real"). No es percepción: es lo que dice el propio tracker.

---

## 3. La colisión de numeración — recordatorio y cómo se resuelve aquí

`docs/INFORME_AVANCE_SPRINT.md` §5 ya documentó que la hoja `BACKLOG` define oficialmente **RQ-61 a RQ-90 como Sprint 4** (una segunda ronda de integración/optimización: "Integración Usuario–Conductor", "Integración Administración–Presidente", etc.) — pero esos mismos números **ya se usaron en Sprint 3** para los requerimientos reales de Chofer/Admin/Presidente/Tickeador listados en §1.2-§1.5. Si el Sprint 4 se planea reusando el rango RQ-61…RQ-90 tal como está en `BACKLOG`, **va a volver a chocar** con el trabajo real ya hecho.

**Solución aplicada en este documento:** a partir de aquí, todo lo nuevo de Sprint 4 usa un **esquema de ID por perfil** que nunca puede confundirse con un `RQ-NN` plano:

```
RQ4-<PERFIL>-NN
```
donde `<PERFIL>` es `USR` (Usuario), `CHO` (Chofer), `ADM` (Administrador), `PRE` (Presidente), `TIC` (Tickeador) o `SYS` (transversal/infraestructura, sin dueño único de perfil).

---

## 4. Propuesta de requerimientos Sprint 4 (por perfil)

Cada ítem indica su origen: **[Gap Figma]** (diseñado, sin código, de `COMPARACION_FIGMA_CODIGO_DOCS.md`), **[Arrastre S3]** (RQ de Sprint 3 sin cerrar), **[Jerarquía]** (tu flujo de roles de este chat), **[Operativo]** (tus 4 puntos de la conversación anterior), o **[QA]** (observación abierta del tracker).

### 4.1 Usuario (`RQ4-USR`)

| ID | Requerimiento | Origen | Prioridad sugerida |
|---|---|---|---|
| RQ4-USR-01 | Sistema de calificación al conductor post-viaje (pantalla + guardado en Firestore; la colección `ratings` ya existe pero sin código) | Gap Figma | Alta |
| RQ4-USR-02 | Pantalla de estadísticas del pasajero ("Mis gastos", "Rutas frecuentes") | Gap Figma | Media |
| RQ4-USR-03 | Habilitar "Registrarme como chofer" desde registro o perfil, creando `role: 'driver'` real (hoy hardcodeado a `'user'`) | Jerarquía | Alta |
| RQ4-USR-04 | Corregir texto del botón "confirmar destino"/"confirmar origen" que no cambia según contexto | Arrastre S3 (RQ-58) | Alta |
| RQ4-USR-05 | Límite de monto válido en formulario de recarga (bug: acepta monto sin límite, saldo llega a `1e+39`) | QA (recarga) | Alta |
| RQ4-USR-06 | Corregir error crítico al retroceder durante reprogramación de viaje | Arrastre S3 (RQ-32, CRÍTICA) | Crítica |
| RQ4-USR-07 | Actualizar `PAGES_GUIDE.md` con las ~10 páginas de Usuario no documentadas (`planificar_viaje_page.dart`, `notificaciones_page.dart`, etc.) | Gap Figma/docs | Baja |

### 4.2 Chofer (`RQ4-CHO`)

| ID | Requerimiento | Origen | Prioridad sugerida |
|---|---|---|---|
| RQ4-CHO-01 | Pantallas de alta de vehículo + verificación de documentos (el dominio `VehicleEntity`/`driver_vehicle_bloc` ya existe, falta la UI) | Gap Figma | Alta |
| RQ4-CHO-02 | Sistema de calificación al pasajero (espejo de RQ4-USR-01) | Gap Figma | Media |
| RQ4-CHO-03 | Pantalla de rendimiento del chofer — cierra RQ-68, que sigue EN_REVISION desde Sprint 3 | Arrastre S3 + Gap Figma | Media |
| RQ4-CHO-04 | Cerrar RQ-64 (Gestión de unidades) una vez exista RQ4-CHO-01 | Arrastre S3 | Alta |
| RQ4-CHO-05 | Reubicar/enlazar "Aprobar choferes" fuera de `driver_home_page.dart` — hoy un chofer accede a la pantalla de aprobar choferes, lo cual no tiene sentido de negocio | QA + código | Alta |

### 4.3 Administrador (`RQ4-ADM`)

| ID | Requerimiento | Origen | Prioridad sugerida |
|---|---|---|---|
| RQ4-ADM-01 | Acción "Promover a Presidente" en Gestión de privilegios (hoy solo existe "Promover a administrador") | Jerarquía | Alta |
| RQ4-ADM-02 | Extender `AdminAccessService` para reconocer permisos del rol `presidente` (hoy `if (user.role != 'admin') return false` bloquea cualquier permiso a Presidente por diseño) | Jerarquía (bloqueante) | Alta |
| RQ4-ADM-03 | Pantalla de revisión manual de recargas pendientes (`recharges`) — hoy no existe ninguna, y el código aprueba automáticamente cada recarga | Operativo (punto 4) | Crítica |
| RQ4-ADM-04 | Pantalla de revisión de `benefit_requests` pendientes — mismo problema que RQ4-ADM-03, y es la causa raíz de que RQ-47 (Usuario) siga bloqueado | QA (RQ-47) | Alta |
| RQ4-ADM-05 | Cerrar RQ-71: completar las opciones de gestión de usuarios que QA marcó como incompletas | Arrastre S3 | Alta |
| RQ4-ADM-06 | Unificar los 3 mecanismos de superadmin (`DevAdminBootstrap`, `SuperAdminConfig.superAdminEmails`, `kSuperAdminEmail`) en uno solo, y documentar el procedimiento real para crear el primer admin en producción | Operativo (punto 2) | Alta |

### 4.4 Presidente (`RQ4-PRE`)

| ID | Requerimiento | Origen | Prioridad sugerida |
|---|---|---|---|
| RQ4-PRE-01 | Decidir cuál de los dos paneles (`PresidenteHomePage` vs `PresidentePanelPage`) es el definitivo y retirar el otro | Arrastre S3 (RQ-80) | Alta |
| RQ4-PRE-02 | Enlazar "Aprobar choferes" desde el panel de Presidente elegido — pedido explícito de QA en RQ-80 | QA (OBS_1786993447887) | Alta |
| RQ4-PRE-03 | Acción "Asignar tickeador" desde el panel de Presidente (no existe hoy en ninguna parte) | Jerarquía | Alta |
| RQ4-PRE-04 | Reemplazar los datos hardcodeados de `testPresidenteUid` en pestañas Unidades/Reportes por datos reales de Firestore | Arrastre S3 (dev ya lo reconoció pendiente el 24 ago) | Media |
| RQ4-PRE-05 | Unificar en Figma el diseño de "vista presidente" (hoy dos frames casi idénticos sin resolver) **antes** de tocar el código de RQ4-PRE-01, para no repetir la duplicación desde el origen | Gap Figma | Alta (bloqueante de RQ4-PRE-01) |

### 4.5 Tickeador (`RQ4-TIC`)

| ID | Requerimiento | Origen | Prioridad sugerida |
|---|---|---|---|
| RQ4-TIC-01 | Decidir cuál implementación es la base (`features/tickeador/` vs `features/driver/*tickeador_operations*`) y congelar/eliminar la otra — bloqueante de todo lo demás | Arrastre S3 (`docs/INFORME_AVANCE_SPRINT.md` §4.1) | Crítica |
| RQ4-TIC-02 | Pantalla "Gestión de personal/tickeadores" (Figma la diseña, no existe en ninguna de las dos implementaciones) | Gap Figma | Alta |
| RQ4-TIC-03 | Cerrar RQ-78 y RQ-79 sobre la implementación elegida en RQ4-TIC-01 | Arrastre S3 | Alta |

### 4.6 Transversal / Sistema (`RQ4-SYS`)

| ID | Requerimiento | Origen | Prioridad sugerida |
|---|---|---|---|
| RQ4-SYS-01 | Unificar el ruteo por rol en `home_router.dart` — hoy `main.dart`, `home_router.dart` e `iniciar_sesion_page.dart` tienen 3 tablas de ruteo distintas que no coinciden | Arrastre S3 (`docs/INFORME_AVANCE_SPRINT.md` §4) | Alta |
| RQ4-SYS-02 | Auditar usos de `Platform.is*`/plugins nativos sin guard `kIsWeb` (caso confirmado: `recarga_qr_page.dart:90`) | Operativo (punto 3) | Media |
| RQ4-SYS-03 | Medir con `Stopwatch` el costo real de `MultiRoutePlanner` en release/dispositivo vs. Chrome antes de optimizar — descartar primero que sea un problema de Firestore | Operativo (punto 1) | Media |
| RQ4-SYS-04 | Normalizar el esquema de `users` (`snake_case` vs `camelCase`) — riesgo transversal ya documentado en `FIRESTORE_COLLECTIONS_GUIDE.md` | Deuda técnica | Media |
| RQ4-SYS-05 | Adoptar formalmente el esquema `RQ4-<PERFIL>-NN` de este documento para todo Sprint 4 en el tracker (`BACKLOG`/`TAREAS`), y marcar RQ-61…RQ-90 de `BACKLOG` como obsoletos/renombrados para que no se vuelvan a asignar | Proceso | Alta |
| RQ4-SYS-06 | Verificación de comprobantes de recarga con IA como apoyo a `RQ4-ADM-03` (no antes — depende de que exista la cola de revisión) | Operativo (punto 4, viabilidad ya evaluada en `COMPARACION_FIGMA_CODIGO_DOCS.md` §10.4) | Baja (depende de RQ4-ADM-03) |

---

## 5. Cómo evitar que esto se repita en Sprint 5

1. **Un solo documento de asignación por perfil** (este archivo, o su sucesor) como fuente de verdad, en vez de que cada dev interprete un rango de RQ sin ver qué construyeron los demás.
2. **Nunca reusar un rango de RQ ya cerrado en un sprint anterior** — de aquí en adelante, todo ID nuevo lleva el prefijo de perfil (`RQ4-...`, y en Sprint 5 `RQ5-...`), nunca un número plano que pueda colisionar con `BACKLOG`.
3. **Daily obligatorio, aunque sea una palabra** — la duplicidad de Presidente (§1.4) y de Tickeador (§1.5) ocurrieron, en parte, porque quien las construyó no reportó daily (`docs/INFORME_AVANCE_SPRINT.md` §2); sin visibilidad cruzada, dos personas resuelven el mismo problema sin saberlo.
4. **Antes de crear un RQ nuevo para Presidente/Tickeador/Admin, revisar §1 de este documento** para confirmar que no exista ya una pantalla o servicio que cubra lo mismo.

---

## 6. Anexo — capturas de Figma usadas en el Artifact

Todas del archivo `Proyecto-Design-Su`, fileKey `VEgf3Hb8pe4CVkT07DG7Xi`. Si se necesita regenerar o cambiar alguna imagen del Artifact, estos son los `node-id` exactos (formato `id:id`, hay que pasarlo como `id-id` en una URL de Figma):

| Perfil | Pantalla | node-id |
|---|---|---|
| Usuario | Ventana principal | `3238:9887` |
| Chofer | 3.3 Inicio Servicio | `3238:7752` |
| Administrador | ADMIN - GESTION GRAL | `3412:9511` |
| Administrador | 7.1.1 Privilegios de administrador | `3412:9146` |
| Presidente | "vista presidente" — versión A | `3412:9656` |
| Presidente | "vista presidente" — versión B (casi idéntica a A) | `3412:9732` |
| Presidente | control de ruta | `3412:9790` |
| Tickeador | Modo Tickeador | `3412:9992` |
| Tickeador | Personal (gestión de tickeadores, sin código) | `3412:9949` |

Estos nodos viven dentro del contenedor "corregido" de Administrador-Presidente-Tickeador (`node-id=3412-8748` en la URL que se conectó originalmente) — ver §1 de `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` para los 4 links completos y el resto del inventario de pantallas (56 Usuario, 44 Chofer, 58 Administrador corregido) que no se llegaron a capturar como imagen.

---

## 7. Continuidad — retomar en otra máquina

Este documento, `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` y el Artifact de §0 son la fuente de verdad para retomar el trabajo. Antes de seguir en una PC nueva:

1. **Reconectar el MCP de Figma** — la conexión (plugin + autenticación OAuth) vive en la instalación local de Claude Code, no en el repo ni en este chat. En la PC nueva:
   ```bash
   claude plugin install figma@claude-plugins-official
   ```
   Si el marketplace oficial no está registrado, primero: `claude plugin marketplace add anthropics/claude-plugins-official`. Luego, dentro de una sesión de Claude Code, escribe `/mcp` → selecciona `figma` → **Authenticate** → **Allow Access** en el navegador. Confirma con `/mcp` que diga `✓ connected`.
2. **Leer en este orden:** `docs/INFORME_AVANCE_SPRINT.md` (diagnóstico de duplicidades) → `docs/COMPARACION_FIGMA_CODIGO_DOCS.md` (diseño↔código↔docs) → este documento (requerimientos por perfil + Sprint 4).
3. **Próximo paso inmediato sugerido:** empezar por los dos ítems que bloquean todo lo demás de su perfil — `RQ4-TIC-01` (decidir qué implementación de Tickeador es la base) y `RQ4-PRE-01`/`RQ4-PRE-05` (retirar el panel de Presidente duplicado, y antes que nada unificar en Figma cuál "vista presidente" es la definitiva). Resolver estos dos primero evita seguir construyendo sobre una base que de todos modos se va a descartar.
4. **`docs/PAGES_GUIDE.md` y `FIRESTORE_COLLECTIONS_GUIDE.md` siguen desactualizados** (ver `COMPARACION_FIGMA_CODIGO_DOCS.md` §5) — no son fuente confiable todavía para saber qué páginas/colecciones existen; usa el código real o estos dos documentos en su lugar hasta que se actualicen.
