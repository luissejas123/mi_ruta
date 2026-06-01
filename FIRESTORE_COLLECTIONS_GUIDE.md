# 📚 Firestore Collections Guide - Mi Ruta

## Estructura General

Firestore almacena rutas de transporte y datos de usuarios con las siguientes colecciones principales:

| Colección | Propósito | ID |
|-----------|-----------|-----|
| `users` | Perfil usuario con sub-objetos por rol (incluye driver_profile) | `uid` (Firebase Auth) |
| `transport_lines` | Líneas de transporte con control de estado | `line_id` |
| `routes_bbox` | Bounding box para búsqueda espacial | `route_id` |
| `schedules` | Horarios (subcolección de transport_lines) | HH-mm |
| `vehicles` | Datos técnicos de vehículos con documentación legal | `vehicle_id` (placa) |
| `trips` | Historial de viajes realizados por conductores | `trip_id` |
| `transactions` | Historial de pagos/recargas/ingresos | Auto-generado |
| `notifications` | Alertas para usuarios/conductores | Auto-generado |
| `ratings` | Calificaciones y reseñas de viajes | `rating_id` |
| `claims` | Reclamos y denuncias | `claim_id` |
| `station_logs` | Registros de terminal (salidas/llegadas) | `log_id` |

---

## 🧑 Colección: users

**Descripción:** Perfil usuario, cartera y configuración. Estructura ampliada por roles.

**Estructura Base (todos los roles):**
```json
{
  "uid": "user_001",
  "full_name": "Juan Pérez",
  "email": "juan@example.com",
  "government_id": "12345678LP",
  "phone_number": "+591 70123456",
  "profile_picture_url": "https://...",
  "role": "user",
  "created_at": "2026-01-15T10:30:00Z",
  "wallet": {
    "current_balance": 67.50,
    "currency": "Bs"
  },
  "settings": {
    "dark_mode_enabled": false,
    "is_driver_mode": false
  }
}
```

**Sub-objeto: admin_info (para role: "admin" o "presidente")**
```json
{
  "admin_info": {
    "assigned_line_id": "line_138",
    "privileges": {
      "manage_routes": {"create": true, "edit": true, "delete": false},
      "manage_users": {"accept": true, "suspend": true, "delete": false},
      "manage_admins": {"create": false, "edit": false, "delete": false}
    }
  }
}
```

**Sub-objeto: tickeador_info (para role: "tickeador")**
```json
{
  "tickeador_info": {
    "assigned_station": "Terminal Sur",
    "assigned_lines": ["line_138", "line_200"],
    "status": "active"
  }
}
```

**Sub-objeto: driver_info (para role: "driver")**
```json
{
  "driver_info": {
    "assigned_line_id": "line_138",
    "vehicle_plate": "2341-ABC",
    "vehicle_capacity": 24,
    "status": "approved",
    "performance_status": "good",
    "strikes_count": 0
  }
}
```

**Sub-objeto: driver_profile (para conductores activos - Módulo de Conductores)**
```json
{
  "driver_profile": {
    "current_vehicle_id": "ABC-1234",
    "assigned_route_id": "line_233",
    "is_service_active": true,
    "average_rating": 4.9,
    "total_trips_completed": 42
  }
}
```

**Roles:** `user` (pasajero), `driver` (conductor), `tickeador` (operador terminal), `admin` (administrador), `presidente` (presidente línea)

---

## 🚌 Colección: transport_lines

**Descripción:** Información de líneas de transporte con ruta geográfica y control de estado.

**Estructura:**
```json
{
  "line_id": "line_138",
  "line_name": "Línea 138",
  "transport_type": "micro",
  "status": "active",
  "is_diverted_realtime": false,
  "origin": "Centro",
  "destination": "Zona Sur",
  "base_fare": 2.00,
  "route_points": [
    {"latitude": -16.5283, "longitude": -68.1493, "name": "Centro"},
    {"latitude": -16.5350, "longitude": -68.1350, "name": "Plaza Avaroa"}
  ],
  "created_at": "2024-03-15T00:00:00Z"
}
```

**Status:** `active` (activo), `suspended` (suspendido), `diverted` (desviado)  
**Subcolección:** `transport_lines/{line_id}/schedules` (horarios con disponibilidad)

---

## � Colección: vehicles

**Descripción:** Datos técnicos de vehículos registrados con documentación legal completa (Módulo de Conductores).

**Estructura:**
```json
{
  "vehicle_id": "ABC-1234",
  "owner_uid": "driver_001",
  "vehicle_type": "taxitrufi",
  "line_number": "233",
  "internal_number": "103",
  "brand": "Toyota",
  "model": "Corolla 2023",
  "color": "Blanco",
  "passenger_capacity": 15,
  "status": "approved",
  "legal_documentation": {
    "driver_license_url": "https://firebasestorage.../documents/driver_001_license.pdf",
    "vehicle_inspection_url": "https://firebasestorage.../documents/ABC1234_inspection.pdf",
    "soat_url": "https://firebasestorage.../documents/ABC1234_soat.pdf",
    "ruat_url": "https://firebasestorage.../documents/ABC1234_ruat.pdf",
    "municipal_operation_card_url": "https://firebasestorage.../documents/ABC1234_municipal.pdf"
  },
  "updated_at": "2026-05-30T10:00:00Z"
}
```

**Tipos:** `bus`, `micro`, `taxitrufi`, `minibus`  
**Status:** `pending_review` (pendiente), `approved` (aprobado), `rejected` (rechazado), `maintenance` (mantenimiento)

---

## 🗺️ Colección: trips

**Descripción:** Historial de viajes completados por conductores con datos de ruta, ingresos y pasajeros.

**Estructura:**
```json
{
  "trip_id": "TRP_001",
  "driver_uid": "driver_001",
  "vehicle_id": "ABC-1234",
  "internal_number": "103",
  "route_line": "233",
  "route_name": "Quillacollo - Cochabamba",
  "start_point": "Terminal Quillacollo",
  "end_point": "Plaza 14 de Septiembre",
  "start_time": "2026-03-15T14:00:00Z",
  "end_time": "2026-03-15T14:15:00Z",
  "duration_minutes": 15,
  "distance_km": 5.2,
  "base_fare": 4.00,
  "passengers_count": 8,
  "points_earned": 120,
  "total_amount_accumulated": 32.00,
  "geo_path_snapshot_url": "https://maps.googleapis.com/maps/api/staticmap?path=..."
}
```

**Uso:** Alimenta el historial de viajes y panel de descargas de reportes del conductor.

---

## �💰 Colección: transactions

**Descripción:** Registro de movimientos de dinero (recargas, pagos, ganancias).

**Estructura:**
```json
{
  "user_id": "user_001",
  "transaction_type": "trip_payment",
  "amount": 2.00,
  "description": "Pago Transporte Línea 138",
  "timestamp": "2026-05-05T08:45:00Z",
  "payment_method": "wallet",
  "status": "completed",
  "analytics": {
    "day_of_week": "M",
    "week_number": 18,
    "year": 2026
  }
}
```

**Tipos:** `trip_payment` (pago viaje usuario), `wallet_topup` (recarga cartera), `trip_income` (ingreso conductor), `withdrawal` (retiro conductor), `refund` (devolución)  
**Estados:** `completed`, `pending`, `failed`

---

## ⭐ Colección: ratings

**Descripción:** Calificaciones y reseñas que los usuarios dan a los conductores tras completar un viaje (Módulo de Conductores).

**Estructura:**
```json
{
  "rating_id": "RAT_001",
  "trip_id": "TRP_001",
  "reviewer_uid": "user_001",
  "target_uid": "driver_001",
  "stars": 5,
  "selected_tags": [
    "Conductor amable",
    "Viaje seguro",
    "Llegó a tiempo"
  ],
  "created_at": "2026-03-15T14:20:00Z"
}
```

**Rango de estrellas:** 1-5  
**Tags predefinidos:** "Conductor amable", "Excelente conducción", "Vehículo limpio", "Llegó a tiempo", "Conducción segura", etc.

---

## � Colección: claims

**Descripción:** Reclamos y denuncias sobre choferes, usuarios o servicio.

**Estructura:**
```json
{
  "claim_id": "claim_99812",
  "reporter_id": "user_001",
  "target_id": "driver_001",
  "line_id": "line_220",
  "claim_type": "driver",
  "title": "Tarifa incorrecta",
  "description": "El chofer me cobró Bs 3.00 en lugar de Bs 2.00",
  "status": "open",
  "created_at": "2026-05-30T09:15:00Z",
  "resolved_at": null,
  "resolved_by": null
}
```

**Tipos:** `driver` (sobre chofer), `user` (sobre usuario), `service` (sobre servicio)  
**Estados:** `open` (abierto), `resolved` (atendido)

---

## 🔔 Colección: notifications

**Descripción:** Alertas para usuarios (saldo bajo, promociones, avisos).

**Estructura:**
```json
{
  "user_id": "user_001",
  "category": "wallet",
  "title": "Saldo bajo",
  "content": "Tu saldo está por debajo de Bs 20...",
  "is_read": false,
  "created_at": "2026-05-05T10:00:00Z",
  "deep_link_module": "module_2"
}
```

**Categorías:** `wallet`, `ia_prediction`, `gift`, `driver`, `system`

---

## 🗺️ Colección: routes_bbox

**Descripción:** Bounding boxes de rutas para búsqueda espacial eficiente (geocerca).

**Estructura:**
```json
{
  "route_id": "route_138_001",
  "line_id": "line_138",
  "bbox": {
    "north": -16.4980,
    "south": -16.5500,
    "east": -68.0900,
    "west": -68.1600
  },
  "metadata": {
    "line_name": "Línea 138",
    "transport_type": "micro",
    "base_fare": 2.00
  },
  "created_at": "2024-03-15T00:00:00Z"
}
```

**Uso:** Consultas geoespaciales para encontrar rutas disponibles en un área específica.

```dart
// Buscar rutas en área (bounding box)
final routes = await FirebaseFirestore.instance
    .collection('routes_bbox')
    .where('bbox.north', isGreaterThanOrEqualTo: lat)
    .where('bbox.south', isLessThanOrEqualTo: lat)
    .where('bbox.east', isGreaterThanOrEqualTo: lng)
    .where('bbox.west', isLessThanOrEqualTo: lng)
    .get();
```

---

## � Colección: station_logs

**Descripción:** Registro de salidas/llegadas de vehículos por operador de terminal.

**Estructura:**
```json
{
  "log_id": "log_77219",
  "tickeador_id": "tick_001",
  "station_name": "Terminal Sur",
  "line_id": "line_138",
  "vehicle_plate": "2341-ABC",
  "driver_id": "driver_001",
  "passenger_count": 24,
  "max_capacity": 24,
  "log_type": "departure",
  "timestamp": "2026-05-30T13:20:00Z",
  "time_since_last_departure": "1h 20min"
}
```

**Log Type:** `departure` (salida), `arrival` (llegada)

---

## �🔗 Relaciones

| Relación | Vínculo |
|----------|---------|
| Usuarios → Transacciones | `users.uid = transactions.user_id` |
| Usuarios → Notificaciones | `users.uid = notifications.user_id` |
| Usuarios → Vehículos | `users.uid = vehicles.owner_uid` (conductor propietario) |
| Usuarios → Viajes | `users.uid = trips.driver_uid` (conductor del viaje) |
| Usuarios → Calificaciones | `users.uid = ratings.target_uid` (conductor calificado) |
| Líneas → Horarios | `transport_lines.line_id` (subcolección) |
| Líneas → BBox Rutas | `transport_lines.line_id = routes_bbox.line_id` |
| Líneas → Viajes | `transport_lines.line_id = trips.route_line` |
| Vehículos → Viajes | `vehicles.vehicle_id = trips.vehicle_id` |
| Viajes → Calificaciones | `trips.trip_id = ratings.trip_id` |
| Reclamos → Chofer | `claims.target_id = users.uid` (driver) |
| Reclamos → Resolutor | `claims.resolved_by = users.uid` (admin) |
| Logs Terminal → Tickeador | `station_logs.tickeador_id = users.uid` |
| Logs Terminal → Chofer | `station_logs.driver_id = users.uid` |
| Logs Terminal → Línea | `station_logs.line_id = transport_lines.line_id` |
---

## Consultas Comunes

**Obtener perfil usuario:**
```dart
final user = await FirebaseFirestore.instance.collection('users').doc('user_001').get();
```

**Obtener líneas activas:**
```dart
final lines = await FirebaseFirestore.instance
    .collection('transport_lines')
    .where('status', isEqualTo: 'active')
    .get();
```

**Obtener rutas en área geográfica:**
```dart
final routes = await FirebaseFirestore.instance
    .collection('routes_bbox')
    .where('bbox.north', isGreaterThanOrEqualTo: lat)
    .where('bbox.south', isLessThanOrEqualTo: lat)
    .get();
```

**Obtener transacciones usuario:**
```dart
final tx = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_id', isEqualTo: userId)
    .orderBy('timestamp', descending: true)
    .get();
```

**Obtener reclamos abiertos:**
```dart
final claims = await FirebaseFirestore.instance
    .collection('claims')
    .where('status', isEqualTo: 'open')
    .orderBy('created_at', descending: true)
    .get();
```

**Obtener registros de terminal por tickeador:**
```dart
final logs = await FirebaseFirestore.instance
    .collection('station_logs')
    .where('tickeador_id', isEqualTo: 'tick_001')
    .orderBy('timestamp', descending: true)
    .limit(20)
    .get();
```

**Obtener vehículos de un conductor:**
```dart
final vehicles = await FirebaseFirestore.instance
    .collection('vehicles')
    .where('owner_uid', isEqualTo: 'driver_001')
    .get();
```

**Obtener viajes completados por conductor:**
```dart
final trips = await FirebaseFirestore.instance
    .collection('trips')
    .where('driver_uid', isEqualTo: 'driver_001')
    .orderBy('start_time', descending: true)
    .limit(10)
    .get();
```

**Obtener calificaciones de un conductor:**
```dart
final ratings = await FirebaseFirestore.instance
    .collection('ratings')
    .where('target_uid', isEqualTo: 'driver_001')
    .orderBy('created_at', descending: true)
    .get();

// Calcular promedio de estrellas
double totalStars = 0;
for (var doc in ratings.docs) {
  totalStars += doc['stars'];
}
double averageRating = ratings.docs.isEmpty ? 0 : totalStars / ratings.docs.length;
```

**Obtener ingresos de conductor (últimas 7 días):**
```dart
final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
final earnings = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_uid', isEqualTo: 'driver_001')
    .where('type', isEqualTo: 'trip_income')
    .where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo.toIso8601String())
    .orderBy('timestamp', descending: true)
    .get();

double totalEarnings = 0;
for (var doc in earnings.docs) {
  totalEarnings += doc['amount'];
}
```

---

## Notas Importantes

- **IDs:** `uid` para usuarios, `line_id` para líneas, `route_id` para rutas, `vehicle_id` para vehículos (placa), `trip_id` para viajes, `claim_id` para reclamos, `log_id` para logs, `rating_id` para calificaciones
- **Timestamps:** Usar siempre formato ISO 8601
- **Moneda:** Bs (Bolivianos) - almacenados como Double
- **Roles permitidos:** user, driver, tickeador, admin, presidente
- **Sub-objetos condicionados:** Solo incluir admin_info, tickeador_info o driver_profile según el rol

## Módulo de Conductores - Estructura de Datos

El módulo de conductores utiliza las siguientes colecciones principales:

1. **users** - Expandida con `driver_profile` (ruta asignada, vehículo actual, estado del servicio, calificación promedio)
2. **vehicles** - Datos técnicos y documentación legal (licencia, inspección, SOAT, RUAT, tarjeta municipal)
3. **trips** - Historial de viajes con ingresos, pasajeros y duración
4. **transactions** - Ingresos (`trip_income`), retiros (`withdrawal`) y análisis por día/semana
5. **notifications** - Alertas de mantenimiento, solicitudes de parada, bloqueos, pagos
6. **ratings** - Calificaciones con tags predefinidos de usuarios hacia conductores

## Campos para Gráficos y Reportes

- **transactions.analytics** - `{day_of_week, week_number, year}` para gráficos semanales de ingresos
- **trips.duration_minutes** y **trips.distance_km** - Para estadísticas de rendimiento
- **ratings.stars** - Para calcular promedio de calificación del conductor
- **vehicles.legal_documentation** - URLs de documentos en Firebase Storage para validación
