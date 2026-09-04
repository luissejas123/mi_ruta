# Deuda técnica conocida

**Última actualización:** 2026-08-31, tras la revisión Homúnculo (Padre + Soberbia + Ira + Pereza) de la documentación del proyecto.

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

## 3. `claims` — colección sin ningún lector ni escritor

`FIRESTORE_COLLECTIONS_GUIDE.md` la documenta con esquema completo (`reporter_id`, `target_id`, `line_id`, `claim_type`, `status`...), pero ningún archivo en `lib/` la usa. A diferencia de `ratings` y `station_logs` (que sí resultaron tener código real al verificar), esta sigue genuinamente huérfana.

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

## Resuelto — ya no es deuda (registrado para no repetir la pregunta)

- **`qa_access` vs `is_super_admin`**: no era un duplicado accidental — `is_super_admin` es el mecanismo vigente (se siembra a mano en Firestore para la primera cuenta, ver `SECURITY.md`); `qa_access` se mantuvo un tiempo como compatibilidad legacy para versiones ya compiladas. **Retirado del código el 2026-09-04** (campo, getters, `setQaAccess` y el chequeo en `SwitchProfileButton`, que ahora depende solo de `is_super_admin`) por decisión del usuario. Cualquier doc `users/{uid}.qa_access` que quede en Firestore ya no tiene efecto — no hace falta borrarlo.
