# Deuda técnica conocida

**Última actualización:** 2026-09-13 — Ira verificó los 7 candidatos huérfanos pendientes del ítem 10 y se actuó sobre su veredicto: 5 archivos borrados (2 pago QR huérfanos, `tarifas_especiales.dart`, `auth/solicitud_beneficio_page.dart`, `test_schedule_service.dart`), `RouteDataSyncService._firestoreDocToEntity` borrado tras corregir su hermano vivo, y `beneficios_page.dart` reconectado (no era huérfano, era el patrón "historial de viajes" de nuevo — se perdió en un merge) con dos fixes reales de paso (hueco de seguridad en `firestore.rules` para `benefit_requests`, posible carga infinita). Ver ítem 10. Antes: se amplió el ítem 10 con una tercera pantalla duplicada tras escribir `docs/specs/claude Documento 2 Diseño Funcional.docx` (Gula). 2026-09-12: se resolvió el ítem 3 (`claims`) y se agregaron los ítems 8 y 9, tras investigar qué escondían los warnings/infos de `flutter analyze` (Padre + Gula). Base original: 2026-08-31, revisión Homúnculo (Padre + Soberbia + Ira + Pereza) de la documentación del proyecto.

> Este documento registra problemas **conocidos y verificados**, deliberadamente sin resolver todavía. No es un backlog de features — es la lista de "esto está roto o es inconsistente, y se decidió no tocarlo en este momento". Cuando algo se arregla, se borra de aquí (o se mueve a un changelog), no se marca `[x]`.

---

## 1. Bug activo: "ruta asignada al chofer" lee un campo que nadie escribe

**Estado: documentado, no arreglado — decisión explícita del usuario (2026-08-31).**

Hay tres mecanismos distintos para el mismo concepto en `users/{uid}`:

| Campo | Escritor | Lector |
|---|---|---|
| `assigned_route_ref` | `lib/features/admin/data/datasources/user_management_datasource.dart` (vía `asignar_ruta_chofer_page.dart`, del lado del presidente) | `lib/features/driver/data/datasources/driver_datasource.dart` → `DriverService.getAssignedRoute()` — **este es el que usa el flujo real**, y el que protege `firestore.rules` |
| `driver_profile.assigned_route_id` | `lib/features/driver/data/datasources/driver_assigned_routes_datasource.dart` | mismo archivo — es al que apunta el ítem de menú **"Ruta asignada"** en `perfil_page.dart` |
| `driver_info.assigned_line_id` | `tools/firestore_init_collections.py` (seeder) | nadie en `lib/` |

**Consecuencia real:** un chofer con ruta ya asignada por el presidente abre Perfil → "Ruta asignada" y la ve **vacía**. Si elige una ahí, la escritura va a `driver_profile.assigned_route_id`, que nada más lee — no tiene efecto. Ese campo tampoco está protegido por `firestore.rules` de la misma forma que `assigned_route_ref`.

**Por qué no se arregla ahora:** implica migrar datos reales de `users` en producción y tocar `firestore.rules`. Es exactamente el tipo de decisión que el proyecto reserva al humano, no a una sesión de limpieza de documentación.

**Cuando se retome:** migrar la pantalla `DriverAssignedRoutesPage` (o retirarla) para que lea/escriba `assigned_route_ref`, y decidir si `driver_profile.assigned_route_id` se borra del esquema o se retira el ítem de menú "Ruta asignada" en `perfil_page.dart` hasta entonces.

---

## 2. Tickeador duplicado — dos implementaciones activas

**Estado: conocido desde hace varias sesiones, sigue crítico y bloqueante.**

- `lib/features/tickeador/**` — feature completa en Clean Architecture.
- `lib/features/driver/**` (`tickeador_operations_datasource.dart`, `tickeador_operation_register_page.dart`, `tickeador_operations_history_page.dart`) — segunda implementación paralela.

Ambas están registradas en `dependency_injection.dart` y **ambas escriben/leen `station_logs`**. `VehicleEntity` también está definida dos veces (`driver/domain/entities/vehicle_entity.dart` y `tickeador/domain/entities/vehicle_entity.dart`).

**Por qué no se arregla ahora:** requiere decidir cuál es la base y migrar la otra — trabajo de una sesión dedicada, no de limpieza de docs.

---

## 3. `claims` — **resuelto**, ya tiene datasource y UI real

Estaba huérfana cuando se escribió esta entrada. Ya no: `ClaimDatasource`/`ClaimService` (feature Reclamos) leen y escriben la colección con el mismo esquema documentado, con UI tanto del lado del reportante (pasajero/chofer) como del staff que resuelve (`PresidenteReclamosPage`). Se deja la entrada como registro de que la pregunta ya se resolvió, no para repetir la investigación.

---

## 4. Violaciones no declaradas de los límites de capa (`CLAUDE.md`)

`CLAUDE.md` dice explícitamente "domain layer has zero dependencies on Flutter or Firebase" y "presentation communicates only through BLoC events — never calls Firestore directly". Hoy eso no es cierto en 6 puntos, sin ninguna excepción documentada (a diferencia de los planning services, que sí están anotados como excepción deliberada):

- **`domain/` importando Firebase directo:** `lib/features/routes/domain/services/route_data_sync_service.dart`, `lib/features/routes/domain/services/route_service.dart`, `lib/features/user/domain/services/storage_service.dart`, `lib/features/user/domain/services/trip_payment_service.dart`.
- **Presentación llamando Firestore directo:** `lib/features/admin/presentation/pages/reportes_operativos_page.dart`, `lib/features/user/presentation/pages/recarga_qr_page.dart`.

**Por qué no se arregla ahora:** son 6 puntos con motivos posiblemente distintos cada uno; hace falta revisar caso por caso si son deuda real o si merecen convertirse en excepción declarada.

---

## 5. `lib/services/firebase_service.dart` — **eliminado el 2026-09-04**

Confirmado código muerto: un solo commit (`1d15f62`, "añadido de firebase y colecciones de users buses y wallets ejm"), nunca importado desde ningún archivo de `lib/`, nunca invocado desde `main.dart`. Escribía datos de ejemplo genéricos (español ibérico, EUR, "Madrid - Barcelona") en las colecciones `buses` y `wallets` — **ninguna de las dos existe en el Firestore real del proyecto** (verificado contra la consola, ver `FIRESTORE_COLLECTIONS_GUIDE.md`) — y además reescribía la colección real `users` con un esquema completamente ajeno al de `UserModel`/`AuthModel` (`name`/`photo`/`registrationDate` en vez de `full_name`/`profile_picture_url`/`created_at`), lo que la habría corrompido si alguna vez se hubiera llamado. Borrado junto con el directorio `lib/services/` (quedó vacío).

---

## 6. Scripts de siembra de Firestore desincronizados con el esquema real

Ver la advertencia completa en `tools/FIRESTORE_INIT_README.md` (agregada 2026-08-31). Resumen: `tools/firestore_init_collections.py` crea `transport_lines` (que `FIRESTORE_COLLECTIONS_GUIDE.md` declara eliminada), siembra `routes_bbox` y `notifications` con esquemas incompatibles con lo que el código real espera, y no escribe `roles`/`is_super_admin`/`admin_permissions` en `users` (riesgo de degradar permisos si un uid coincide). Existe además un segundo script, `tools/firestore_init_driver_collections.py`, no documentado en el README de `tools/`.

---

## 7. Posible fuga de credenciales — verificar si ya se rotaron

Sesión anterior (2026-08-27, commit `428ce53`) encontró un archivo `env` (sin el punto, no cubierto por `.gitignore`) commiteado con una API key de Firebase y una de Google Maps en texto plano, ya empujado al remoto. El archivo ya no existe en el working tree actual, pero **sigue en el historial de git** de todos modos. No hay confirmación registrada de que las claves se hayan rotado. `SECURITY.md` tiene una sección "En caso de fuga accidental" pero no registra este incidente como caso — si las claves ya se rotaron, esta entrada se puede borrar; si no, es la más urgente de esta lista.

---

## 8. Sistema de permisos de administrador duplicado

**Encontrado 2026-09-12** (Padre + Gula, a raíz de investigar qué escondían los warnings de `flutter analyze`).

`lib/core/di/dependency_injection.dart:80-81` importa `AdminPrivilegesDatasource`/`AdminPrivilegesService` y **nunca los registra** — de ahí salían los `unused_import` en el análisis estático. Ese par escribe `users/{uid}.admin_info.privileges` (esquema anidado). El sistema que sí está vivo es otro, con un nombre de entidad casi idéntico: `AdminPrivilegesBloc` → `users/{uid}.settings.admin_permissions` (esquema plano, `admin_remote_datasource_impl.dart:124,160`). Mismo concepto, dos campos, dos clases con nombres que solo difieren en "Privileges" vs "Permissions".

**Por qué no se arregla ahora:** requiere confirmar cuál de los dos esquemas tiene datos reales en producción antes de borrar el otro — no es limpieza de código muerto simple, podría haber cuentas ya escritas con el esquema equivocado.

---

## 9. Preferencias de notificación — dos sistemas desconectados

**Encontrado 2026-09-12** (mismo hallazgo que el ítem 8, misma investigación).

`UserPreferencesBloc` está registrado en DI (`dependency_injection.dart:331`) y no tiene ningún consumidor real — guarda en `SharedPreferences` (local, por dispositivo). El que sí funciona es `perfil_page.dart:681+`, que escribe `users/{uid}.settings.trip_notifications_enabled` (y campos hermanos) directo en Firestore. Mismo concepto de "el usuario eligió qué notificaciones recibir", una versión local muerta y una remota viva.

**Por qué no se arregla ahora:** `UserPreferencesBloc` no rompe nada estando muerto (nadie lo lee), así que no es urgente — pero es candidato directo para el mismo tipo de limpieza de huérfanos que ya se está haciendo en `docs/PLAN_SEGURIDAD_TARIFAS_GPS.md`.

---

## 10. Varias pantallas con nombre de clase casi idéntico, solo una conectada por concepto

**Resuelto 2026-09-13 — Ira verificó los 7 candidatos huérfanos y se actuó sobre su veredicto.** Quedaba pendiente convocar a Ira antes de borrar (ver nota anterior); ya se hizo. Resultado:

- **Pago QR — las dos huérfanas se borraron.** `lib/features/user/pago_QR.dart` (`PagoQrPage`) y `lib/features/auth/presentation/pages/pago_qr_page.dart` (`PagoQr`) eran maquetas estáticas sin escáner ni lógica de pago — cero aporte frente a la real (`user/presentation/pages/pago_qr_page.dart`, `PagoQRPage`, con `MobileScannerController`, `ImagePicker`, `TripPaymentBloc`). Se borraron sin reemplazo.
- **`tarifas_especiales.dart` — borrado.** Maqueta cuyos tres botones de beneficio llevaban los tres a `PagoQRPage` (flujo sin sentido) y que además declaraba una copia duplicada de `SolicitudBeneficioPage` en el mismo directorio que la real — riesgo de ambigüedad de nombre si alguien la importaba por error. Sin importadores reales, confirmado.
- **`auth/presentation/pages/solicitud_beneficio_page.dart` — borrado.** Era un scaffold de app independiente (`void main() { runApp(MyApp()) }`) con botones que solo hacían `debugPrint`. Tercera declaración duplicada de `SolicitudBeneficioPage` en el repo, ahora eliminada.
- **`test_schedule_service.dart` — borrado.** `void main()` de depuración suelto dentro de `lib/`, con `stopId` hardcodeado; `plan_detalle_page.dart` ya hace lo mismo mejor.
- **`RouteDataSyncService._firestoreDocToEntity` — borrado, con un fix previo.** Antes de borrarlo se corrigió su hermano vivo `RouteDatasource._mapToRouteEntity` (`route_datasource.dart`), al que le faltaba mapear `direction_id` desde Firestore (el huérfano sí lo tenía). Sin ese fix, `getRouteByRef`/`getRouteById`/`getAllActiveRoutes`/`getActiveRoutesPaginated` devolvían siempre `directionId == null`, lo que podía colapsar ida/vuelta de una misma línea en la deduplicación `ref|directionId` que usa la planificación de viajes (ver CLAUDE.md, sección routes). Ya corregido.

**`beneficios_page.dart` — NO era huérfano, era el caso "historial de viajes" otra vez: reconectado, no borrado.** Git (`git log -S`) confirma que `wallet_page.dart` navegaba a `BeneficiosPage` hasta que un merge (`a589a2b`, resolviendo la rama de Mario Bráñez) lo revirtió a `MisSolicitudesBeneficioPage` y dejó el import de `BeneficiosPage` como residuo. `BeneficiosPage` es estrictamente más rico: renovar server-side (reutiliza el documento ya subido en vez de pedir un formulario en blanco), cancelar, descargar el comprobante en PDF (`StorageService.generateBenefitPdf`, ~60 líneas reales), y mostrar `description`/`adminNotes`. Se revirtió `wallet_page.dart` para navegar a `BeneficiosPage` de nuevo y se borró `mis_solicitudes_beneficio_page.dart` (quedó sin callers). De paso se corrigieron dos problemas reales que este archivo exponía:
  - **Hueco de seguridad en `firestore.rules`:** `benefit_requests` no validaba dueño ni bloqueaba auto-aprobación (`allow read, write: if isSignedIn()` a secas — mismo patrón ya corregido antes para `vehicles`). Cualquier usuario autenticado con un `requestId` ajeno podía leer el documento de identidad de otro o escribirse `status: 'approved'` directo. Corregido con el mismo patrón que `vehicles`: el dueño puede crear/renovar/cancelar pero nunca poner `approved`; solo staff puede aprobar. **Falta desplegar manualmente**, como siempre.
  - **Posible carga infinita:** `_loadHistory()` no despachaba nada si `AuthBloc` todavía no estaba en `AuthLoaded` en `initState`, dejando el `build()` pegado en "Cargando beneficios..." para siempre. Se cambió para despachar siempre (con `userId` vacío si hace falta), dejando que el BLoC resuelva a un estado terminal como ya hacía `wallet_page.dart` con el mismo patrón.

**Pago QR — hallazgo suelto que sigue sin arreglar (no relacionado a los huérfanos de arriba):** dentro de la `PagoQRPage` real, el botón "subir QR desde galería" (`_pickQRFromGallery`) no decodifica el QR de la imagen elegida — pasa la ruta del archivo directo como `qrData`, que `TripPaymentService.processPayment` no puede parsear (espera `driverId|tripId|amount`). El escaneo con cámara no tiene este problema. Sigue sin tocar, fuera de alcance de esta limpieza.

---

## Resuelto — ya no es deuda (registrado para no repetir la pregunta)

- **`qa_access` vs `is_super_admin`**: no era un duplicado accidental — `is_super_admin` es el mecanismo vigente (se siembra a mano en Firestore para la primera cuenta, ver `SECURITY.md`); `qa_access` se mantuvo un tiempo como compatibilidad legacy para versiones ya compiladas. **Retirado del código el 2026-09-04** (campo, getters, `setQaAccess` y el chequeo en `SwitchProfileButton`, que ahora depende solo de `is_super_admin`) por decisión del usuario. Cualquier doc `users/{uid}.qa_access` que quede en Firestore ya no tiene efecto — no hace falta borrarlo.
