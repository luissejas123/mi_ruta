# 📚 Firestore Collections Guide - Mi Ruta

> Verificado directamente contra el proyecto Firebase (`mi-ruta-4004d`) el 2026-06-29 y contra el código en `lib/`. Las colecciones marcadas como **"sin referencias en código"** existen como datos semilla/demo pero ningún datasource las lee o escribe todavía — corresponden al módulo de conductores (`driver/`), que en `lib/features/driver/` es solo un placeholder (`.gitkeep`).

## Estructura General

| Colección | Propósito | ID del doc | ¿Usada por código? |
|-----------|-----------|-----|-----|
| `users` | Perfil de usuario + cartera | `uid` (Firebase Auth) | ✅ |
| `routes` | Rutas con polyline/stops completos (fuente de `routes_bbox`) | auto-id | ✅ |
| `routes_bbox` | Bounding box ligero por ruta, para búsqueda espacial sin cargar polylines | auto-id | ✅ |
| `planned_trips/{uid}/trips` | Planes de viaje guardados (subcolección) | auto-id | ✅ |
| `notifications/{uid}/items` | Notificaciones del usuario (subcolección) | auto-id | ✅ |
| `trip_history/{uid}/trips` | Historial de viajes completados por el pasajero (subcolección) | auto-id | ✅ |
| `benefit_requests` | Solicitudes de descuento/beneficio (universitario, senior, etc.) | auto-id | ✅ |
| `recharges` | Solicitudes de recarga de saldo vía comprobante QR | auto-id | ✅ |
| `transactions` | Ledger de movimientos de dinero (recargas, beneficios, pagos) | auto-id | ✅ |
| `config` | Documentos de configuración global de la app | clave fija (`qr_recarga`, `routes_meta`) | ✅ |
| `trips` | Registro de viajes de conductor (ingresos, pasajeros) | `trip_id` | ✅ (leído por `TripPaymentService`) |
| `vehicles` | Datos técnicos/documentación legal de vehículos | `vehicle_id` (placa) | ✅ (leído/escrito por `VehicleRemoteDataSourceImpl`, features `driver`/`admin`) |
| `ratings` | Calificaciones de pasajero → conductor | `rating_id` | ⚠️ Sin referencias en código |
| `claims` | Reclamos/denuncias | `claim_id` | ⚠️ Sin referencias en código |
| `station_logs` | Registro de salidas/llegadas en terminal | `log_id` | ⚠️ Sin referencias en código |

**Nota:** `transport_lines` y la subcolección `schedules` que aparecían en versiones previas de este documento **no existen** en el proyecto Firebase real — se han eliminado de esta guía.

---

## 🧑 Colección: users

**⚠️ Inconsistencia real de esquema:** hay documentos antiguos en `snake_case` y documentos nuevos en `camelCase` coexistiendo en la misma colección. Revisado en producción:

**Esquema A — snake_case** (escrito por `wallet_datasource.dart`, `auth_remote_datasource_impl.dart`):
```json
{
  "uid": "1hTAcCmH04OfYzQLjFMb3OUMdoY2",
  "full_name": "caro",
  "email": "caro@gmail.com",
  "phone_number": "638xxxx",
  "government_id": "1234567hjd",
  "profile_picture_url": null,
  "role": "user",
  "created_at": "2026-05-21T21:12:01.166180",
  "wallet": {
    "current_balance": 12,
    "currency": "Bs",
    "updated_at": "<Timestamp>"
  },
  "settings": {
    "dark_mode_enabled": false,
    "is_driver_mode": false
  }
}
```

**Esquema B — camelCase** (visto en registros más recientes):
```json
{
  "uid": "0hLY27TtXRRBUxx2TzV3jvkuNzJ2",
  "fullName": "dropx",
  "email": "dropx@gmail.com",
  "phoneNumber": "77777777",
  "governmentId": "8888888",
  "userType": "user",
  "profileImageUrl": "",
  "isActive": true,
  "rating": 0,
  "reviewsCount": 0,
  "createdAt": "2026-06-29T20:29:31.603786",
  "updatedAt": "2026-06-29T20:29:31.603786",
  "wallet": { "balance": 0, "currency": "Bs." }
}
```

**Al leer `users` siempre verificar ambas claves** (`full_name`/`fullName`, `wallet.current_balance`/`wallet.balance`, etc.) o normalizar en el modelo de datos — actualmente cada datasource asume un esquema distinto, lo que es una fuente real de bugs.

**Roles vistos en datos:** `user`. Roles documentados pero sin datos de ejemplo: `driver`, `tickeador`, `admin`, `presidente` (relacionados al módulo de conductores no implementado).

---

## 🛣️ Colección: routes

**Descripción:** Catálogo maestro de rutas con polyline y paradas completas. Es la fuente desde la cual se genera `routes_bbox` (versión ligera) y desde la cual `RouteDataSyncService` siembra SQLite local para uso offline.

**Escrito por:** [lib/features/routes/data/datasources/route_datasource.dart](lib/features/routes/data/datasources/route_datasource.dart)

```json
{
  "name": "106 - Trufi 106",
  "ref": "106",
  "color": "#FF5733",
  "stops": [{"latitude": -17.32, "longitude": -66.14}],
  "polyline": [{"latitude": -17.32, "longitude": -66.14}, "... cientos de puntos"],
  "description": null,
  "active": true,
  "created_at": "<Timestamp>",
  "updated_at": "<Timestamp>"
}
```

**Uso:** Documentos pueden ser grandes (polyline con cientos de puntos) — la migración a `routes_bbox` se hace en lotes de 20 (`getAllActiveRoutesForMigration`) para evitar OOM.

---

## 🗺️ Colección: routes_bbox

**Descripción:** Versión ligera de `routes` — solo bounding box y metadatos, sin polyline. Permite filtrar rutas candidatas por área sin cargar geometría completa.

```json
{
  "ref": "106",
  "name": "106 - Trufi 106",
  "lat_min": -17.4019863,
  "lat_max": -17.3277236,
  "lng_min": -66.2661124,
  "lng_max": -66.1419522,
  "active": true
}
```

**Uso real (filtro en memoria, no query compuesta):**
```dart
final routes = await FirebaseFirestore.instance
    .collection('routes_bbox')
    .where('active', isEqualTo: true)
    .get();
// luego filtrar lat_min/lat_max/lng_min/lng_max en memoria
```

---

## 🗂️ Subcolección: planned_trips/{uid}/trips

**Descripción:** Planes de viaje multi-tramo generados por `MultiRoutePlanner` y guardados para repetir/seguir después. Ver [lib/features/routes/data/datasources/planned_trip_datasource.dart](lib/features/routes/data/datasources/planned_trip_datasource.dart).

```json
{
  "origin_name": "Av. Blanco Galindo",
  "origin_lat": -17.39, "origin_lng": -66.16,
  "destination_name": "UMSS",
  "destination_lat": -17.40, "destination_lng": -66.15,
  "legs": [
    {
      "leg_type": "bus",
      "route_id": "rt_001", "route_name": "Trufi 106", "route_ref": "106",
      "direction_id": "1",
      "boarding_lat": -17.39, "boarding_lng": -66.16,
      "alighting_lat": -17.40, "alighting_lng": -66.15,
      "walk_to_meters": 120, "transit_meters": 2400, "walk_from_meters": 80
    }
  ],
  "created_at": "2026-06-29T10:00:00Z",
  "is_completed": false
}
```

`leg_type` es `"bus"` o `"walking"` (`LegType` enum en [lib/features/routes/domain/entities/planned_trip.dart](lib/features/routes/domain/entities/planned_trip.dart)).

---

## 🔔 Subcolección: notifications/{uid}/items

**Descripción:** Notificaciones del usuario (recarga aprobada, viaje completado, regalos/descuentos). Ver [lib/features/user/data/datasources/notification_datasource.dart](lib/features/user/data/datasources/notification_datasource.dart).

```json
{
  "type": "gift",
  "title": "¡Tienes un descuento!",
  "body": "20% en tu próximo viaje",
  "is_read": false,
  "created_at": "2026-06-29T10:00:00Z",
  "discount_percent": 20,
  "business_name": "Café Central",
  "is_used": false,
  "valid_until": "2026-07-15T00:00:00Z"
}
```

Los campos `discount_percent`, `business_name`, `is_used`, `valid_until` solo existen cuando `type == "gift"`. `NotificationType` define los valores válidos de `type` en [lib/features/user/domain/entities/app_notification.dart](lib/features/user/domain/entities/app_notification.dart).

---

## 🕓 Subcolección: trip_history/{uid}/trips

**Descripción:** Historial de viajes completados por el pasajero (no confundir con la colección `trips`, que es del conductor). Ver [lib/features/user/data/datasources/trip_history_datasource.dart](lib/features/user/data/datasources/trip_history_datasource.dart).

```json
{
  "route_name": "Trufi 106",
  "origin_name": "Mi ubicación",
  "destination_name": "UMSS",
  "elapsed_seconds": 1140,
  "date": "2026-06-29T10:00:00Z"
}
```

---

## 🎓 Colección: benefit_requests

**Descripción:** Solicitudes de descuento/beneficio (universitario, senior, discapacidad) con documentos de respaldo. Ver [lib/features/user/data/datasources/benefit_request_datasource.dart](lib/features/user/data/datasources/benefit_request_datasource.dart).

```json
{
  "user_id": "hikHzOhxx0d8QnJto4jAvBfCaFa2",
  "benefit_type": "university",
  "description": "prueba",
  "document_urls": ["https://firebasestorage.googleapis.com/.../document_0.png"],
  "status": "pending",
  "admin_notes": null,
  "approved_at": null,
  "created_at": "<Timestamp>"
}
```

**Tipos:** `university`, `senior`, (otros definidos en la UI de solicitud)
**Estados:** `pending`, `approved`, `rejected`
**Efecto secundario:** al crear una solicitud se agrega un doc espejo en `transactions` con `transaction_type: "benefit_request"`.

---

## 💳 Colección: recharges

**Descripción:** Solicitudes de recarga de saldo con comprobante de pago (QR/transferencia) subido a Storage. Ver [lib/features/user/data/datasources/recharge_datasource.dart](lib/features/user/data/datasources/recharge_datasource.dart).

```json
{
  "user_id": "1hTAcCmH04OfYzQLjFMb3OUMdoY2",
  "amount": 12,
  "currency": "Bs",
  "proof_image_url": "https://firebasestorage.googleapis.com/.../proof_....jpg",
  "status": "approved",
  "created_at": "<Timestamp>",
  "verified_at": "<Timestamp>"
}
```

**Estados:** `pending`, `approved`, `rejected`
**Efecto secundario:** al aprobarse, se actualiza `users/{uid}.wallet.current_balance` y se agrega un doc en `transactions`.

---

## 💰 Colección: transactions

**Descripción:** Ledger de todos los movimientos de dinero — recargas, beneficios, pagos de viaje.

```json
{
  "user_id": "dTZKcwHInueq683GUD6xAUJklem1",
  "transaction_type": "recharge",
  "amount": 80,
  "description": "Recarga con QR",
  "payment_method": "qr_proof",
  "status": "approved",
  "recharge_id": "TOVzLud2gHvUNOqYCemJ",
  "timestamp": "<Timestamp>"
}
```

**`transaction_type` vistos en datos:** `recharge`, `benefit_request`. Documentados en código pero también usados: `trip_payment`, `trip_income`.
**Estados:** `pending`, `approved`/`completed`, `rejected`/`failed`
**Campo de vínculo opcional:** `recharge_id` o `benefit_request_id` según el tipo de transacción.

---

## ⚙️ Colección: config

**Descripción:** Documentos de configuración global, IDs fijos por propósito (no auto-generados).

```json
// config/qr_recarga
{
  "qr_url": "https://firebasestorage.googleapis.com/.../qr_banco.jpg",
  "update_at": "2026-06-28"
}

// config/routes_meta
{
  "description": "Rutas de transporte Cochabamba desde GTFS",
  "source": "gtfs_seed",
  "version": "1.0",
  "total_routes": 140,
  "updated_at": "<Timestamp>"
}
```

---

## 🚌 Colección: trips (conductor)

**Descripción:** Registro de viajes completados por conductores — leído por `TripPaymentService` para procesar pagos pasajero→conductor. Actualmente solo hay datos demo (`TRP_001`, `TRP_002`); no existe flujo de escritura desde la app (el módulo conductor está sin implementar).

```json
{
  "trip_id": "TRP_001",
  "driver_uid": "driver_001",
  "vehicle_id": "ABC-1234",
  "route_line": "233",
  "route_name": "Quillacollo - Cochabamba",
  "start_point": "Terminal Quillacollo",
  "end_point": "Plaza 14 de Septiembre",
  "start_time": "2026-05-29T06:00:29",
  "end_time": "2026-05-29T06:15:29",
  "duration_minutes": 15,
  "distance_km": 5.2,
  "base_fare": 4,
  "passengers_count": 8,
  "total_amount_accumulated": 32
}
```

---

## ✅ vehicles (implementado — features `driver`/`admin`)

ID = placa del vehículo. Campos: `vehicle_id`, `owner_uid` (uid del chofer dueño-operador, asignado por el admin), `vehicle_type` (`taxitrufi`/`micro`/...), `line_number`, `internal_number`, `brand`, `model`, `color`, `passenger_capacity`, `status` (`approved`/`pending_review`/`rejected`), `legal_documentation` (URLs a Storage: `soat_url`, `vehicle_inspection_url`, `driver_license_url`, `municipal_operation_card_url`, `ruat_url`), `updated_at`.

Campos nuevos añadidos para la feature "unidades activas":
- `is_on_duty` (bool, default `false`) — toggle manual que el chofer activa/desactiva desde su panel (`DriverHomePage`) para marcar su unidad como "en servicio ahora". No es presencia real (no hay heartbeat/Cloud Functions); permanece activo hasta que el chofer lo desactive manualmente.
- `is_on_duty_updated_at` (string ISO8601) — timestamp del último cambio del toggle.

El admin (`AdminHomePage`) consulta en tiempo real `vehicles` filtrando `is_on_duty == true` para ver qué unidades están activas.

Leído/escrito por: `lib/features/driver/data/datasources/vehicle_remote_datasource_impl.dart`.

---

## ⚠️ Colecciones sin referencias en código (datos demo del futuro módulo conductor)

Estas colecciones tienen datos en Firestore pero **ningún archivo en `lib/` las lee o escribe**. Documentadas aquí tal como existen hoy en la base, para cuando se implemente el módulo:

### ratings
ID = `rating_id`. Campos: `trip_id`, `reviewer_uid`, `target_uid`, `stars` (1-5), `selected_tags` (array de strings predefinidos), `created_at`.

### claims
ID = `claim_id`. Campos: `reporter_id`, `target_id` (nullable), `line_id`, `claim_type` (`driver`/`user`/`service`), `title`, `description`, `status` (`open`/`resolved`), `created_at`, `resolved_at`, `resolved_by`.

### station_logs
ID = `log_id`. Campos: `tickeador_id`, `station_name`, `line_id`, `vehicle_plate`, `driver_id`, `passenger_count`, `max_capacity`, `log_type` (`departure`/`arrival`), `timestamp`, `time_since_last_departure`.

---

## 🔗 Relaciones (verificadas en código)

| Relación | Vínculo |
|----------|---------|
| Usuario → Notificaciones | `notifications/{uid}/items` (subcolección) |
| Usuario → Planes de viaje | `planned_trips/{uid}/trips` (subcolección) |
| Usuario → Historial de viajes | `trip_history/{uid}/trips` (subcolección) |
| Usuario → Solicitudes de beneficio | `benefit_requests.user_id = users.uid` |
| Usuario → Recargas | `recharges.user_id = users.uid` |
| Usuario → Transacciones | `transactions.user_id = users.uid` |
| Recarga → Transacción | `transactions.recharge_id = recharges.{id}` |
| Beneficio → Transacción | `transactions.benefit_request_id = benefit_requests.{id}` |
| Ruta → BBox | `routes_bbox.ref = routes.ref` |

**Relaciones del módulo conductor (sin código, solo datos demo):** `vehicles.owner_uid`, `trips.driver_uid`/`vehicle_id`, `ratings.target_uid`/`trip_id`, `claims.target_id`, `station_logs.driver_id`/`tickeador_id` — todas referencian `users.uid` o `trips.trip_id`, pero no hay datasources implementados todavía.

---

## Consultas Comunes (verificadas contra código real)

**Obtener perfil usuario:**
```dart
final user = await FirebaseFirestore.instance.collection('users').doc(uid).get();
```

**Buscar rutas por bbox (filtro en memoria, ver `route_datasource.dart`):**
```dart
final bboxSnap = await FirebaseFirestore.instance
    .collection('routes_bbox')
    .where('active', isEqualTo: true)
    .get();
// filtrar lat_min/lat_max/lng_min/lng_max contra el punto en memoria
```

**Obtener planes de viaje guardados:**
```dart
final plans = await FirebaseFirestore.instance
    .collection('planned_trips').doc(userId).collection('trips')
    .orderBy('created_at', descending: true)
    .limit(50)
    .get();
```

**Obtener notificaciones no leídas:**
```dart
final count = await FirebaseFirestore.instance
    .collection('notifications').doc(userId).collection('items')
    .where('is_read', isEqualTo: false)
    .count().get();
```

**Obtener transacciones de un usuario:**
```dart
final tx = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_id', isEqualTo: userId)
    .orderBy('timestamp', descending: true)
    .get();
```

**Obtener solicitudes de beneficio pendientes:**
```dart
final pending = await FirebaseFirestore.instance
    .collection('benefit_requests')
    .where('status', isEqualTo: 'pending')
    .get();
```

---

## Notas Importantes

- **Inconsistencia de esquema en `users`** — coexisten docs `snake_case` y `camelCase`. Cualquier código nuevo que lea `users` debe manejar ambas convenciones o se debe planear una migración de normalización.
- **`routes` vs `routes_bbox`** — `routes` tiene polyline completo (pesado), `routes_bbox` es la versión ligera para queries de área. La sincronización es manual vía `RouteDatasource.createBboxCollection()`, no automática con triggers.
- **Timestamps mixtos** — algunos campos usan `Timestamp` nativo de Firestore (`created_at` en `recharges`, `benefit_requests`), otros usan string ISO 8601 (`created_at` en `users`, `notifications`, `planned_trips`). No asumir un tipo único al deserializar.
- **Moneda:** Bs (Bolivianos), almacenada como número (`int`/`double` según el doc).
- **Las colecciones del módulo conductor existen pero están huérfanas** — son datos de prueba para una funcionalidad (`lib/features/driver/`) que aún no se implementó. No depender de ellas hasta que exista código que las consuma.
