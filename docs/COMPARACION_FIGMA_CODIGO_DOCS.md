# Comparación Figma ↔ Código ↔ Documentación

**Fecha:** 27 de agosto de 2026
**Fuente Figma:** archivo `Proyecto-Design-Su` (fileKey `VEgf3Hb8pe4CVkT07DG7Xi`), vía Figma MCP (Dev Mode)
**Nodos analizados:**

| Rol | node-id | Frames/pantallas |
|---|---|---|
| Usuario | `3238-9773` | 56 |
| Chofer | `3246-6005` | 44 |
| Administrador-Presidente-Tickeador (original) | `3896-3668` | 71 |
| Administrador-Presidente-Tickeador (**corregido**) | `3412-8748` | 58 |

> La versión "corregido" reduce 71→58 frames (elimina duplicados de "Gestion de usuarios" y de "1.3 Registrar usuario", y agrega estados nuevos: `cambiar contraseña`, `admin sin privilegios`, `image 1..13`). Se trata como la versión vigente; la original queda como historial.

**Documentos relacionados:** `docs/REQUERIMIENTOS_POR_PERFIL_SPRINT3_SPRINT4.md` (los requerimientos de Sprint 3/4 organizados con estos mismos hallazgos, más nombres de responsables) y su [Artifact visual](https://claude.ai/code/artifact/89f44423-4f57-46d4-9ba2-b5678fff2af4) con capturas de estas mismas pantallas. Para reconectar el MCP de Figma en otra máquina, ver `REQUERIMIENTOS_POR_PERFIL_SPRINT3_SPRINT4.md` §7.

Este análisis es de **inventario de pantallas** (nombre de frame + primer texto visible), cruzado contra los archivos `*_page.dart` reales y contra `PAGES_GUIDE.md` / `docs/INFORME_AVANCE_SPRINT.md`. No es todavía una comparación pixel-a-pixel de estilos (colores, spacing, tokens) — eso se puede hacer pantalla por pantalla bajo demanda con `get_design_context`/`get_screenshot`.

---

## 1. Resumen ejecutivo

- **Usuario**: la mejor cobertura de las cuatro. La mayoría de los 56 frames de Figma tienen una página `.dart` equivalente. Los huecos reales son **calificación al conductor** y **estadísticas de gastos/rutas frecuentes** — ninguna existe en código.
- **Chofer**: el flujo de negocio (ingresos, historial, tickeador) está cubierto, pero **todo el flujo de alta de vehículo y verificación de documentos que Figma diseñó no tiene página propia** — el dominio (`VehicleEntity`, `driver_vehicle_bloc`, `vehicle_usecases`) existe, la UI no. La **calificación al pasajero** (espejo de la de Usuario) tampoco existe en código.
- **Administrador**: buena cobertura funcional (gestión de usuarios, rutas, privilegios, reportes).
- **Presidente / Tickeador**: el propio Figma "corregido" **todavía conserva dos frames `vista presidente` casi idénticos** — el archivo de diseño arrastra la misma ambigüedad que ya causó los dos paneles duplicados en código (`PresidenteHomePage` vs `PresidentePanelPage`, documentado en `docs/INFORME_AVANCE_SPRINT.md` §4). Esto no es un problema de implementación: **el diseño en sí nunca se resolvió a una sola versión**.
- **`PAGES_GUIDE.md` está desactualizado**: dice textualmente que `driver/` y `admin/` "están en desarrollo (carpeta vacía)". Falso — hay 7 páginas de Chofer y 9 de Admin ya escritas, más 2 de Presidente y 1 de Tickeador que ni siquiera se mencionan porque esas features no existían cuando se escribió la guía.

---

## 2. Usuario — Figma (56) vs `lib/features/user/` (34) + `auth/` (3)

| Grupo Figma | Página(s) en código | Estado |
|---|---|---|
| 1.1 Iniciar/Recuperar/Registrar sesión | `iniciar_sesion_page.dart`, `insertar_correo_page.dart`, `register_page.dart`, `recuperar_acceso_page.dart`, `registration_success_page.dart` | ✅ |
| Editar perfil / Editar teléfono / Editar correo | `editar_perfil_page.dart`, `perfil_page.dart` | ✅ |
| VENTANA PRINCIPAL | `mi_ruta_screen.dart` | ✅ |
| Visualización saldo / Recarga / Recarga QR / Cargando / Éxito | `wallet_page.dart`, `recarga_saldo_page.dart`, `recarga_qr_page.dart`, `confirmacion_recarga_page.dart` | ✅ |
| Historial / Movimientos | `movimientos_page.dart`, `historial_viajes_page.dart` | ✅ |
| Pago QR / Confirmación de pago | `pago_qr_page.dart`, `qr_scanner_page.dart` | ✅ |
| Tarifas especiales / Solicitud de beneficio | `solicitud_beneficio_page.dart`, `confirmacion_beneficio_page.dart`, `estado_beneficios_page.dart`, `historial_beneficios_page.dart`, `mis_solicitudes_beneficio_page.dart` | ✅ (código tiene **más** pantallas de beneficios que las que documenta `PAGES_GUIDE.md`) |
| Escanear/Tomar fotografía | `subir_fotografia_page.dart` | ✅ |
| 4.2/4.4/4.8 Planificación de ruta (multi-opción) | `planificar_viaje_page.dart`, `plan_detalle_page.dart`, `rutas_sugerencias_page.dart`, `rutas_inicio_page.dart`, `rutas_seleccion_page.dart`, `ruta_linea_page.dart` | ✅ (`planificar_viaje_page.dart` tampoco está en `PAGES_GUIDE.md`) |
| Ruta del micro / Abordaje / Botón de parada | `ruta_abordaje_page.dart`, `ruta_navegacion_page.dart`, `ruta_tiempo_page.dart` | ✅ |
| **5.3 Califica a tu conductor** | — | ❌ **No existe ninguna página de calificación en `lib/features/user/`** |
| 5.1/5.2 Notificaciones de saldo/promociones/cambio de ruta | `notificaciones_page.dart`, `preferencias_notificacion_page.dart` | ✅ |
| **6.1 Estadísticas (Mis gastos, Rutas frecuentes)** | — | ❌ **No existe página de estadísticas del pasajero** (`grep` de "estadistic/gastos" no arroja resultados) |
| Perfil de usuario | `perfil_page.dart` | ✅ |

**Doc gap:** `PAGES_GUIDE.md` no menciona `planificar_viaje_page.dart`, `plan_detalle_page.dart`, `detalle_viaje_page.dart`, `historial_beneficios_page.dart`, `mis_solicitudes_beneficio_page.dart`, `estado_beneficios_page.dart`, `notificaciones_page.dart`, `preferencias_notificacion_page.dart`, `map_location_picker_page.dart`, `perfil_page.dart` — son ~10 páginas reales sin documentar.

---

## 3. Chofer — Figma (44) vs `lib/features/driver/` (7 páginas)

| Grupo Figma | Página en código | Estado |
|---|---|---|
| 1.1/1.2/1.3 Login/Recuperar/Registrar | *(reutiliza `auth/` y `user/`)* | ✅ compartido |
| 3.3 Notificación temporal / Detener / Iniciar servicio | `driver_home_page.dart` (estados internos) | ⚠️ sin página propia, asumido como estado del home |
| **3.1 Tipo de vehículo / 3.1 Formulario / 3.2 Verificar documentos / 3.2 Fotografía / 3.2 Subir imagen (alta de unidad)** | — | ❌ **Sin página.** El dominio existe (`VehicleEntity`, `driver_vehicle_bloc.dart`, `vehicle_usecases.dart`, `vehicle_repository_impl.dart`) pero no hay ningún `*_page.dart` de registro de vehículo ni de verificación de documentos en `driver/presentation/pages/` |
| 7.2 Gestión de unidades / 3.4 Rutas asignadas | `driver_assigned_routes_page.dart` | ⚠️ parcial — cubre rutas asignadas, no "gestión de unidades" |
| 1.4 Perfil (chofer) | *(reutiliza `perfil_page.dart` de user/)* | ⚠️ sin variante específica de chofer |
| 5.4 Notificación de parada (×4) | — | ❌ sin página de notificaciones propia de chofer (¿reutiliza `notificaciones_page.dart`?) |
| 2.3 Historial de ingresos | `historial_ingresos_page.dart` | ✅ |
| 3.2.1 Elegir QR para cobrar / 5.4.1 Cobrar viaje | `tickeador_operation_register_page.dart` | ✅ |
| 6.2.1/6.2.2 Historial de viajes | `driver_trip_history_page.dart` | ✅ |
| **5.4.2/5.4.3 Calificación de usuario / Reseña / "Gracias por calificar"** | — | ❌ **No existe ninguna página de calificación al pasajero** (mismo hueco simétrico que en Usuario) |
| 2.2 Billetera (chofer) | — | ❌ no hay wallet propia de chofer (¿se asume que es `historial_ingresos_page.dart`?) |
| **6.2 Rendimiento del chofer** | — | ❌ sin página de métricas/desempeño |
| 3.2 Editar perfil / fotografía / subir imagen | *(reutiliza `editar_perfil_page.dart`, `subir_fotografia_page.dart`)* | ✅ compartido |

**Conclusión Chofer:** el "cobro" y el "historial" están sólidos; **todo el onboarding de vehículo/documentos y todo lo de calificaciones/rendimiento está sin construir en UI**, pese a que Figma ya lo diseñó y en el caso de vehículos el dominio (BLoC/repos) ya existe.

---

## 4. Administrador / Presidente / Tickeador — Figma corregido (58) vs código

### Admin (`lib/features/admin/`, 9 páginas) — bien cubierto
| Figma | Código |
|---|---|
| 7.1 Registro de administrador / Registro exitoso | `admin_create_admin_page.dart` ✅ |
| 7.1 Gestión de usuarios / ADMIN-GESTION GRAL / Bloquear usuarios | `user_management_page.dart` ✅ |
| 7.1.1 Privilegios de administrador | `admin_privileges_page.dart`, `admin_permissions_edit_page.dart` ✅ |
| Agregar/editar/eliminar rutas | `admin_route_form_page.dart`, `admin_route_management_page.dart` ✅ |
| Reportes | `reportes_operativos_page.dart` ✅ (revisar si usa datos reales — `INFORME_AVANCE_SPRINT.md` marca a Admin como "casi completo") |
| PERFIL Administrador | `admin_home_page.dart` ✅ |
| **cambiar contraseña** | `change_password_dialog.dart` (en `auth/`) | ⚠️ existe pero como **diálogo**, no como pantalla propia — válido, pero distinto de lo que Figma dibuja como pantalla completa |

### Presidente (`lib/features/presidente/`, 2 páginas) — **el diseño mismo está duplicado**
- Figma corregido todavía tiene **dos frames `vista presidente`** casi idénticos (#38 y #39: "Choferes" / "Supervisión y control") — no se resolvió a uno solo.
- Código tiene **dos implementaciones**: `presidente_home_page.dart` (pestañas con datos hardcodeados del UID de prueba) y `presidente_panel_page.dart` (usa `AdminService`/`RouteService` reales, es al que navegan `DriverHomePage` y el switcher de super-admin).
- **Esto confirma con el diseño lo que `docs/INFORME_AVANCE_SPRINT.md` §4.3 ya reportó desde el código**: no es que un dev haya "inventado" un segundo panel — el Figma nunca se depuró a una sola versión, así que dos personas construyeron cada una la suya.
- `control de ruta` (Mapa de Ruta) y `reportes` (Resumen de desempeño) sí están cubiertos por `presidente_panel_page.dart`.

### Tickeador — 1 página propia + funcionalidad duplicada en `driver/`
- Figma: `Modo Tickeador`, `Historial` (registros de hoy), `Unidades activas`, `Personal` (gestión de tickeadores), `Agregar tickeadores` → 5 frames distintos.
- Código: `tickeador_home_page.dart` (1 archivo) + `tickeador_operation_register_page.dart` / `tickeador_operations_history_page.dart` (dentro de `driver/`, la implementación paralela que `INFORME_AVANCE_SPRINT.md` §4.1 marca como duplicado activo en `dependency_injection.dart`).
- No hay evidencia de una página para "Personal/gestión de tickeadores" ni "Agregar tickeadores" en ninguna de las dos implementaciones.

### Estados menores (corregido)
- `admin sin privilegios`, `Aprobado`, `Bloquear`, `Advertencia`, `Aceptación` → probablemente diálogos/estados dentro de `admin_privileges_page.dart` / `user_management_page.dart`, no páginas propias — razonable, pero no verificado 1:1.

---

## 5. Estado de la documentación (`PAGES_GUIDE.md`)

`PAGES_GUIDE.md` solo documenta **Auth (5) + Usuario (21)** y dice explícitamente que Conductor y Administrador "están en desarrollo (carpeta vacía)". Eso ya no es cierto:

- `driver/` tiene 7 páginas reales.
- `admin/` tiene 9 páginas reales.
- `presidente/` (2) y `tickeador/` (1) **ni siquiera existían como conceptos** cuando se escribió la guía — no hay sección para ellos.
- Del lado de Usuario, faltan ~10 páginas ya construidas (ver §2).

**Recomendación:** actualizar `PAGES_GUIDE.md` con secciones reales para Conductor, Administrador, Presidente y Tickeador, y completar las páginas de Usuario faltantes — idealmente en el mismo PR que resuelva la duplicidad de Presidente/Tickeador (`docs/INFORME_AVANCE_SPRINT.md` recomendación #2 y #3), para no documentar una versión que luego se retira.

**`FIRESTORE_COLLECTIONS_GUIDE.md` tiene la misma staleness** (fechado 2026-06-29): su propia introducción dice que las colecciones "sin referencias en código" (`ratings`, `claims`, `station_logs`) "corresponden al módulo de conductores (`driver/`), que en `lib/features/driver/` es solo un placeholder (`.gitkeep`)" — igual de falso que en `PAGES_GUIDE.md`: `driver/` tiene 7 páginas reales y datasources funcionando (`vehicle_remote_datasource_impl.dart`, etc.). La parte de esquema de datos (`users` en dos formatos, `routes`/`routes_bbox`, `recharges`, `benefit_requests`...) sigue siendo confiable; solo esa afirmación introductoria sobre el estado del módulo conductor quedó vieja.

---

## 6. Hallazgos cruzados con `docs/INFORME_AVANCE_SPRINT.md`

| Hallazgo del informe de sprint | Confirmado también en Figma |
|---|---|
| Presidente tiene dos paneles compitiendo (§4.3) | ✅ Figma corregido conserva 2 frames `vista presidente` sin resolver |
| Tickeador duplicado en `tickeador/` y `driver/` (§4.1) | ✅ Figma diseña Tickeador como sección propia, pero el código lo partió en dos lugares |
| Admin "casi completo" | ✅ buena cobertura de pantallas Figma↔código |
| Usuario "completo funcionalmente" | ⚠️ matiza: **faltan** calificación al conductor y estadísticas de gastos, que si están en el Figma |

---

## 7. Gaps concretos a priorizar (nuevo, no estaba en el informe de sprint)

1. **Sistema de calificación (Usuario→Chofer y Chofer→Usuario)** — diseñado en Figma (5.3, 5.4.2, 5.4.3), **cero código** en ningún lado (`grep` de "calificar/rating/reseña" no encuentra páginas).
2. **Onboarding de vehículo + verificación de documentos del chofer** — dominio listo (`VehicleEntity`, blocs, repos), **falta toda la UI** (3.1, 3.2 en Figma Chofer).
3. **Estadísticas del pasajero** ("Mis Gastos", "Rutas Frecuentes", Figma 6.1) — sin página.
4. **Rendimiento del chofer** (Figma 6.2 "Rendimiento chofer") — sin página.
5. **Gestión de personal/tickeadores** desde el panel de Presidente — sin página en ninguna de las dos implementaciones de Tickeador.

---

## 8. Siguientes pasos posibles

Este documento es un **inventario de pantallas**, no una comparación visual detallada. Si quieres profundizar, puedo (bajo demanda, pantalla por pantalla, para no consumir contexto de más):
- Traer `get_design_context`/`get_screenshot` de un frame específico y compararlo contra el widget real (colores, spacing, copy en es-BO).
- Revisar si los 5 gaps de §7 están al menos parcialmente cubiertos por widgets/diálogos que no aparecen como `*_page.dart` (falso negativo de este análisis basado en nombres de archivo).
- Redactar la actualización de `PAGES_GUIDE.md` con las secciones reales de Conductor/Administrador/Presidente/Tickeador.

---

## 9. Flujo de jerarquía de roles — verificado contra código

Se verificó el flujo que describiste (Admin crea otros admins / gestiona usuarios / da privilegio de Presidente → Presidente aprueba choferes / asigna tickeadores → Usuario puede registrarse como chofer) contra el código real, no solo contra la documentación.

| Paso del flujo propuesto | ¿Existe hoy? | Evidencia |
|---|---|---|
| Admin agrega a otro admin | ✅ Sí | `admin_create_admin_page.dart` → `CreateAdminAccountEvent` → `AdminRepository.createAdminAccount`. Gated por `user.canManageAdmins`. |
| Admin gestiona usuarios (aceptar/bloquear pasajeros) | ✅ Sí (toggle activo/bloqueado) | `user_management_page.dart` + `UserManagementBloc.SetManagedUserActiveState`. |
| Admin aprueba specificamente a **choferes** | ⚠️ Existe la pantalla, mal conectada | `driver_approval_page.dart` usa el mismo `UserManagementBloc` filtrando `userTypeFilter: 'driver'` — pero **solo se navega a ella desde `driver_home_page.dart` (el propio chofer)**, no desde ningún panel de Admin ni de Presidente. Confirma lo ya señalado en `docs/INFORME_AVANCE_SPRINT.md` §4.4. |
| Admin da privilegio de **Presidente** a un usuario | ❌ No | El primitivo genérico existe (`AdminRepository.updateUserRole(uid, role)`), pero la única acción de UI conectada a él es "Promover a administrador" (`PromoteUserToAdminEvent`, ver [user_management_page.dart:70](lib/features/admin/presentation/pages/user_management_page.dart#L70)), que siempre manda `role: 'admin'`. No hay botón "Promover a presidente". |
| Presidente acepta usuarios que se registran como chofer | ⚠️ Backend listo, sin UI de Presidente | `DriverApprovalPage`/`UserManagementBloc` ya hacen exactamente esto, pero ni `presidente_home_page.dart` ni `presidente_panel_page.dart` los importan o enlazan. |
| Presidente asigna usuarios como **tickeador** | ❌ No | No existe ningún evento de bloc ni acción de UI que cambie `role`/`userType` a `'tickeador'`. `PresidentePanelState.totalTickeadores` solo **cuenta** cuántos tickeadores hay, no permite crear/asignar ninguno. |
| Usuario puede registrarse como chofer | ❌ No | [register_page.dart:92](lib/features/auth/presentation/pages/register_page.dart#L92) fija `role: 'user'` de forma dura — es el único valor que el formulario de registro puede producir. La única aparición de `role: 'driver'` en todo `lib/` es en `static_test_accounts.dart` (cuenta mock, no un flujo real). |

### Bloqueo estructural — ✅ RESUELTO (actualizado 28 ago 2026)

*(Hallazgo original, ya no vigente: `AdminAccessService.hasPermission` tenía `if (user.role != 'admin') return false`, lo que bloqueaba cualquier permiso a un usuario `presidente`.)*

Verificado contra el código actual: **esto ya se corrigió**. `AdminAccessService` ([lib/features/admin/domain/services/admin_access_service.dart](lib/features/admin/domain/services/admin_access_service.dart)) ahora expone `canApproveChoferRequests` y `canAssignTickeador`, ambos `true` para `role == 'presidente'` (además de `admin` y superadmin), con tests dedicados en `test/admin_access_test.dart`. De paso, el SuperAdmin también se resolvió: ya no depende de una allowlist de correos en código (`SuperAdminConfig`/`kSuperAdminEmail` — ambas existían y **se eliminaron**, confirmado por `SECURITY.md`); ahora es un único campo `users/{uid}.is_super_admin` en Firestore, no escribible por el cliente. Y el flujo de "Usuario pide ser chofer" también ya tiene datos reales: campo `driver_request` (`status: pending/approved/rejected`) documentado en `FIRESTORE_COLLECTIONS_GUIDE.md`, con lógica en `perfil_page.dart` (`_confirmarSolicitudChofer`, `hasPendingDriverRequest`).

Sigue pendiente conectar esos permisos ya existentes a botones de UI reales en el panel de Presidente (ver `RQ4-PRE-02`/`RQ4-PRE-03` en `REQUERIMIENTOS_POR_PERFIL_SPRINT3_SPRINT4.md`) — el bloqueo estructural que lo impedía ya no existe.

---

## 10. Puntos operativos solicitados

### 10.1 "Lentitud al calcular rutas — ¿es por Firebase?"

Evidencia en [route_data_sync_service.dart](lib/features/routes/domain/services/route_data_sync_service.dart) y [multi_route_planner.dart](lib/features/routes/domain/services/multi_route_planner.dart):

- El diseño **ya evita Firestore en cada búsqueda**: `RouteDataSyncService.getRoutesNearPoint()` siempre lee de SQLite local (comentario explícito en el propio archivo: *"Búsqueda → siempre desde SQLite (~1ms, sin red)"*). Firestore solo se toca (a) la primera siembra desde GTFS (assets locales, no red) y (b) un chequeo de versión en segundo plano (`_checkAndSyncVersion`, `unawaited`, no bloquea la búsqueda).
- El cálculo real (`MultiRoutePlanner.planAsync`) es 100% CPU en memoria: evalúa combinaciones de hasta 12×8×12 rutas candidatas, y por cada combinación de 2-3 tramos hace un muestreo anidado de puntos de polyline (`_findTransfer`: doble loop sobre los puntos de dos rutas, cada `_sampleStep = 15`). Es costo algorítmico, no una consulta a base de datos.
- **Conclusión: la lentitud reportada casi con certeza no es Firestore** — es carga de CPU del algoritmo de planificación multi-tramo, agravada por dos factores de entorno de prueba: (a) modo **debug** de Flutter (JIT, notablemente más lento que un build release) y (b) pruebas en **Chrome/web**, donde Dart compilado a JS/Wasm ejecuta bucles numéricos intensivos más lento que Dart nativo ARM de un release APK — esto conecta directamente con el punto 10.3 sobre pruebas en navegador.
- **Cómo confirmarlo (medición, no fix):** envolver `PlannedTripService.searchOptions()` en un `Stopwatch` y comparar el tiempo en (1) build release en un teléfono real vs (2) `flutter run` debug vs (3) Chrome — así se separa "problema de arquitectura de datos" (no lo es, según el código) de "costo del algoritmo por plataforma" (sí lo es).

### 10.2 "¿Cómo debería crear al superusuario para empezar el flujo de jerarquía?" — ✅ RESUELTO (actualizado 28 ago 2026)

*(Hallazgo original, ya no vigente: existían tres mecanismos de "superusuario" distintos y sin relación entre sí — `DevAdminBootstrap` con `admin@miruta.com`/`unanoche`, `SuperAdminConfig.superAdminEmails`, y un tercer `kSuperAdminEmail` separado solo para el switcher de QA.)*

Verificado contra el código actual: **el equipo ya lo unificó**. `lib/core/config/super_admin_config.dart` **ya no existe** — se eliminó junto con las dos allowlists de correos. `SECURITY.md` lo confirma explícitamente: *"No existe ninguna lista de correos privilegiados en el código [...] antes había dos, con listas distintas entre sí, y se eliminaron."* Ahora hay una única fuente de verdad: el campo `users/{uid}.is_super_admin` en Firestore, que ni el propio dueño de la cuenta puede escribirse (bloqueado por `firestore.rules`). `admin@miruta.com` (la cuenta de `DevAdminBootstrap`) explícitamente **ya no es superadmin por su correo** — hay un test que lo verifica (`test/admin_access_test.dart`: *"el correo ya no otorga superadmin por si solo"*).

**Procedimiento vigente para sembrar el primer superadmin** (documentado en `SECURITY.md`, un solo paso por entorno, y el único que queda):
1. Registrar una cuenta normal desde la app con un correo que solo conozca el equipo (nunca commiteado al repo).
2. Desde la Consola de Firebase / Admin SDK (credenciales de servicio, ignoran las reglas de cliente), editar `users/{uid}` a mano: `{ "role": "admin", "is_super_admin": true }`.
3. Desde ahí esa cuenta ya promueve admins/presidentes **desde la propia app**.

`DevAdminBootstrap` sigue existiendo para desarrollo (`admin@miruta.com`/`unanoche`, solo `kDebugMode`), pero su propio comentario ya advierte que desde que `firestore.rules` se endureció, no puede sembrar `role`/`is_super_admin` en un entorno nuevo — solo verifica una cuenta que ya era admin de antes.

### 10.3 Conflictos por pruebas en navegador vs. móvil

Esto ya estaba señalado como friction general en `docs/INFORME_AVANCE_SPRINT.md` §7; aquí se encontró la causa concreta en código:

- [recarga_qr_page.dart:90](lib/features/user/presentation/pages/recarga_qr_page.dart#L90) llama `Platform.isAndroid` (de `dart:io`) **sin ningún guard de `kIsWeb`**. En Flutter Web, `dart:io.Platform` lanza `UnsupportedError` al usarse — esta pantalla (guardar comprobante de recarga) puede fallar exactamente por esto en Chrome.
- En **todo** `lib/`, solo 2 archivos verifican `kIsWeb`/`Platform.is*` (`main.dart` y este mismo `recarga_qr_page.dart`) — casi ningún otro punto de la app distingue web de móvil, pese a usar `sqflite` (sin `sqflite_common_ffi_web` en `pubspec.yaml`, confirmado ausente), `mobile_scanner` y `geolocator`, que se comportan distinto o no funcionan igual en Chrome.
- Esto explica el conflicto que describes: cuando alguien "arregla" un flujo para que no truene en su prueba de Chrome, es fácil que rompa (o cambie silenciosamente) el camino real de móvil, porque no hay un patrón consistente de "esto es solo-móvil" en el código — cada dev decide caso por caso, sin guard.
- **Recomendación de proceso** (ya estaba en el informe de sprint, se reafirma con evidencia nueva): la validación funcional de QR, GPS, caché SQLite y subida de fotos debe hacerse siempre en dispositivo/emulador real; Chrome queda solo para iterar UI rápido. Si además se quiere que la app no truene en Chrome, cada uso de `Platform.is*`/plugin nativo debería envolverse en `if (!kIsWeb && ...)` con un fallback, no dejarlo lanzar la excepción.

### 10.4 Viabilidad de verificar comprobantes de recarga con IA (sin pasarela de pagos)

**Hallazgo crítico primero, antes de evaluar la IA:** hoy **no existe ninguna verificación, ni humana ni automática**. En [recharge_bloc.dart:34](lib/features/user/presentation/bloc/recharge_bloc.dart#L34), `_onSubmitRecharge` llama `approveRecharge()` inmediatamente después de subir la imagen, con el propio comentario del código: *"Aprobar la recarga automáticamente (en producción sería manual)"*. Cualquier imagen subida — comprobante real o no — acredita saldo al instante. Tampoco existe ninguna pantalla de admin para revisar la colección `recharges` (sin resultados al buscar "recharge" en `lib/features/admin`). Es decir: la propuesta de IA no compite con un proceso manual que hoy funciona — compite con **cero controles**, lo cual cambia la evaluación de riesgo a favor de intentarlo.

**Viabilidad técnica — sí, pero como asistente de un revisor humano, no como aprobador único:**
- Lo que un modelo de visión puede verificar con buena confiabilidad: que la imagen parece un comprobante bancario/QR real (no una foto aleatoria), que el monto en el texto coincide con el monto declarado en el formulario, que la fecha sea reciente, y que la cuenta/destinatario coincida con la configurada en `config/qr_recarga`.
- Lo que NO puede verificar de forma confiable solo con una pasada de visión: que el comprobante no sea un **duplicado reciclado** (la misma imagen reusada en dos recargas — para eso hace falta un hash de imagen + chequeo de duplicados contra `recharges` existentes) ni un **montaje/edición** sofisticado del monto.
- Riesgo de falsos positivos/negativos: puede rechazar comprobantes legítimos con mala foto/iluminación (fricción para el usuario real) o aprobar un montaje bien hecho (riesgo financiero) si se le da la decisión final sola.
- **Patrón recomendado:** IA como filtro de primera línea que marca la recarga (`ai_confidence_score`, `ai_flags`, p.ej. `monto_no_coincide`, `imagen_duplicada`, `no_parece_comprobante`) dejándola en `pending_review` — y un admin humano confirma antes de acreditar saldo. No "IA aprueba/rechaza sola", al menos mientras no haya volumen que justifique automatizar del todo.
- Costo/latencia: mandar una imagen a un modelo de visión (Claude/GPT-4V/Gemini) por recarga es barato y rápido (segundos) frente al monto típico de una recarga de transporte urbano — viable en costo.
- **Requisito previo que no es de IA sino de producto:** antes de sumar IA hace falta construir la cola/pantalla de revisión manual de `recharges` para admin, que hoy **no existe en absoluto** (0% construida). La IA se conecta ahí como un campo más que ayuda a priorizar/decidir, no como reemplazo del botón aprobar/rechazar.

**Conclusión:** viable como apoyo a un revisor humano que hoy no existe. Orden recomendado: (1) construir la cola/pantalla de revisión manual de `recharges` para admin, (2) cambiar `RechargeBloC` para dejar de auto-aprobar y de verdad esperar en `status: pending` hasta que alguien decida, (3) recién ahí sumar el análisis de imagen con IA como ayuda a la decisión del admin — no antes, porque hoy no hay ningún punto en el flujo donde ese análisis pueda conectarse.
