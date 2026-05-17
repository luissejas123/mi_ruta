# 📚 Documentación de Colecciones en Firestore - Mi Ruta

## Introducción

Este documento explica la estructura de datos en Firestore de forma detallada. Cada colección se describe con sus campos en español e inglés, el tipo de dato, y ejemplos de uso.

---

## 📋 Tabla de Contenidos

1. [Colección: Usuarios](#colección-usuarios)
2. [Colección: Líneas de Transporte](#colección-líneas-de-transporte)
3. [Subcolección: Horarios](#subcolección-horarios)
4. [Colección: Transacciones](#colección-transacciones)
5. [Colección: Notificaciones](#colección-notificaciones)
6. [Relaciones entre Colecciones](#relaciones-entre-colecciones)
7. [Guía de Tipos de Datos](#guía-de-tipos-de-datos)

---

## Colección: Usuarios

**Nombre en Firestore:** `users`

**Descripción:** Almacena la información del perfil de cada usuario (pasajeros, conductores, administradores).

**ID del Documento:** `uid` (Identificador único del usuario en Firebase Auth)

### Estructura de Campos

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `uid` | ID de Usuario | String | Identificador único generado por Firebase Auth | `user_001` |
| `full_name` | Nombre Completo | String | Nombre y apellido del usuario | `Juan Pérez García` |
| `email` | Correo Electrónico | String | Email para contacto y login | `juan@example.com` |
| `government_id` | Cédula de Identidad | String | Número de CI del usuario | `12345678LP` |
| `phone_number` | Número de Teléfono | String | Teléfono de contacto | `+591 70123456` |
| `profile_picture_url` | URL de Foto de Perfil | String | Link a la imagen del perfil en Firebase Storage | `https://i.pravatar.cc/150?img=1` |
| `role` | Rol | String | Tipo de usuario (user/driver/admin) | `user` o `driver` o `admin` |
| `created_at` | Fecha de Creación | Timestamp | Fecha y hora cuando se registró | `2026-01-15T10:30:00Z` |

### Sub-objeto: Cartera (Wallet)

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `wallet.current_balance` | Saldo Actual | Double | Dinero disponible en la cartera | `67.50` |
| `wallet.currency` | Moneda | String | Tipo de moneda | `Bs` (Bolivianos) |

### Sub-objeto: Configuración (Settings)

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `settings.dark_mode_enabled` | Modo Oscuro Activado | Boolean | Si el usuario prefiere tema oscuro | `false` |
| `settings.is_driver_mode` | Modo Conductor Activado | Boolean | Si está en modo conductor | `false` |

### Ejemplo Completo

```json
{
  "uid": "user_001",
  "full_name": "Juan Pérez García",
  "email": "juan@example.com",
  "government_id": "12345678LP",
  "phone_number": "+591 70123456",
  "profile_picture_url": "https://i.pravatar.cc/150?img=1",
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

### Roles Disponibles

| Rol | Descripción |
|---|---|
| `user` | Pasajero regular que usa el transporte |
| `driver` | Conductor/Chofer que maneja un micro o trufi |
| `admin` | Administrador que gestiona la plataforma |

---

## Colección: Líneas de Transporte

**Nombre en Firestore:** `transport_lines`

**Descripción:** Almacena información sobre las rutas de transporte (micros, trufis, etc.).

**ID del Documento:** `line_id` (Identificador único de la línea)

### Estructura de Campos

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `line_id` | ID de Línea | String | Identificador único de la línea | `line_138` |
| `line_name` | Nombre de la Línea | String | Nombre de la ruta de transporte | `Línea 138` |
| `transport_type` | Tipo de Transporte | String | Tipo de vehículo (micro/trufi) | `micro` o `trufi` |
| `status` | Estado | String | Estado de operación (active/suspended) | `active` |
| `base_fare` | Tarifa Base | Double | Precio base del viaje | `2.00` |
| `created_at` | Fecha de Creación | Timestamp | Cuándo se registró la línea | `2024-03-15T00:00:00Z` |

### Sub-array: Puntos de Ruta (Route Points)

Cada línea tiene un array de puntos que forman la ruta en el mapa.

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `route_points[].latitude` | Latitud | Double | Coordenada de latitud del punto | `-16.5283` |
| `route_points[].longitude` | Longitud | Double | Coordenada de longitud del punto | `-68.1493` |
| `route_points[].name` | Nombre del Punto | String | Nombre del lugar (parada) | `Centro` |

### Ejemplo Completo

```json
{
  "line_id": "line_138",
  "line_name": "Línea 138",
  "transport_type": "micro",
  "status": "active",
  "base_fare": 2.00,
  "route_points": [
    {
      "latitude": -16.5283,
      "longitude": -68.1493,
      "name": "Centro"
    },
    {
      "latitude": -16.5350,
      "longitude": -68.1350,
      "name": "Plaza Avaroa"
    },
    {
      "latitude": -16.5400,
      "longitude": -68.1200,
      "name": "Zona Sur"
    }
  ],
  "created_at": "2024-03-15T00:00:00Z"
}
```

### Tipos de Transporte

| Tipo | Descripción |
|---|---|
| `micro` | Autobús de mediano tamaño (15-25 pasajeros) |
| `trufi` | Minibus compartido (6-8 pasajeros) |

### Estados

| Estado | Descripción |
|---|---|
| `active` | La línea está operativa |
| `suspended` | La línea está suspendida temporalmente |

---

## Subcolección: Horarios

**Nombre en Firestore:** `transport_lines/{line_id}/schedules`

**Descripción:** Contiene los horarios de salida para cada línea de transporte. Esta es una **subcolección** de la colección `transport_lines`.

**ID del Documento:** Formato HH-mm (ej: `07-30`, `08-00`)

### Estructura de Campos

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `time` | Hora | String | Formato HH-mm del documento ID | `07-30` |
| `departure_time` | Hora de Salida | String | Hora legible para el usuario | `7:30 AM` |
| `estimated_arrival_minutes` | Minutos de Llegada Estimados | Integer | Cuántos minutos tarda el recorrido | `25` |
| `seat_availability_percent` | Porcentaje de Disponibilidad | Integer | Porcentaje de asientos disponibles (0-100) | `40` |
| `comfort_level` | Nivel de Comodidad | String | Evaluación de comodidad (full/neutral/available) | `available` |

### Ejemplo Completo

```json
{
  "time": "07-30",
  "departure_time": "7:30 AM",
  "estimated_arrival_minutes": 25,
  "seat_availability_percent": 40,
  "comfort_level": "available"
}
```

### Niveles de Comodidad

| Nivel | Descripción |
|---|---|
| `full` | Bus completamente lleno, sin asientos disponibles |
| `neutral` | Bus con ocupación media |
| `available` | Bus con muchos asientos disponibles |

### Cómo Acceder

Para obtener los horarios de una línea específica:

```dart
// Obtener horarios de la línea 138
final schedules = await FirebaseFirestore.instance
    .collection('transport_lines')
    .doc('line_138')
    .collection('schedules')
    .orderBy('time')
    .get();
```

---

## Colección: Transacciones

**Nombre en Firestore:** `transactions`

**Descripción:** Registra todos los movimientos de dinero en el sistema (recargas, pagos de viajes, ganancias, etc.).

**ID del Documento:** Generado automáticamente (Firestore lo crea)

### Estructura de Campos

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `user_id` | ID del Usuario | String | Referencia al usuario (vinculo a `users.uid`) | `user_001` |
| `transaction_type` | Tipo de Transacción | String | Tipo de movimiento (top_up/trip_payment/driver_earning) | `trip_payment` |
| `amount` | Monto | Double | Cantidad de dinero en Bs | `2.00` |
| `description` | Descripción | String | Descripción legible de la transacción | `Pago Transporte Línea 138` |
| `timestamp` | Fecha y Hora | Timestamp | Cuándo ocurrió la transacción | `2026-05-05T08:45:00Z` |
| `payment_method` | Método de Pago | String | Cómo se pagó (wallet/QR) | `wallet` |
| `status` | Estado | String | Estado de la transacción (completed/pending/failed) | `completed` |

### Ejemplo Completo

```json
{
  "user_id": "user_001",
  "transaction_type": "trip_payment",
  "amount": 2.00,
  "description": "Pago Transporte Línea 138",
  "timestamp": "2026-05-05T08:45:00Z",
  "payment_method": "wallet",
  "status": "completed"
}
```

### Tipos de Transacción

| Tipo | Descripción |
|---|---|
| `top_up` | El usuario recargó dinero a su cartera |
| `trip_payment` | El usuario pagó un viaje |
| `driver_earning` | El conductor recibió ganancias |
| `refund` | Se devolvió dinero al usuario |

### Métodos de Pago

| Método | Descripción |
|---|---|
| `wallet` | Pagado desde la cartera del usuario |
| `QR` | Pagado mediante código QR (pago móvil) |
| `credit_card` | Pagado con tarjeta de crédito |
| `debit_card` | Pagado con tarjeta de débito |

### Estados de Transacción

| Estado | Descripción |
|---|---|
| `completed` | La transacción fue exitosa |
| `pending` | La transacción está en proceso |
| `failed` | La transacción falló |

---

## Colección: Notificaciones

**Nombre en Firestore:** `notifications`

**Descripción:** Almacena mensajes y alertas para cada usuario (avisos de saldo, predicciones, bonos, etc.).

**ID del Documento:** Generado automáticamente

### Estructura de Campos

| Campo Inglés | Campo Español | Tipo | Descripción | Ejemplo |
|---|---|---|---|---|
| `user_id` | ID del Usuario | String | Referencia al usuario que recibe la notificación | `user_001` |
| `category` | Categoría | String | Tipo de notificación (wallet/ia_prediction/gift) | `wallet` |
| `title` | Título | String | Título de la notificación | `Saldo bajo` |
| `content` | Contenido | String | Mensaje completo de la notificación | `Tu saldo está por debajo de Bs 20...` |
| `is_read` | Está Leída | Boolean | Si el usuario ya leyó la notificación | `false` |
| `created_at` | Fecha de Creación | Timestamp | Cuándo se creó la notificación | `2026-05-05T10:00:00Z` |
| `deep_link_module` | Enlace a Módulo | String | Módulo de la app a abrir al hacer click | `module_2` |

### Ejemplo Completo

```json
{
  "user_id": "user_001",
  "category": "wallet",
  "title": "Saldo bajo",
  "content": "Tu saldo está por debajo de Bs 20. Recarga para continuar usando el servicio.",
  "is_read": false,
  "created_at": "2026-05-05T10:00:00Z",
  "deep_link_module": "module_2"
}
```

### Categorías de Notificación

| Categoría | Descripción |
|---|---|
| `wallet` | Alertas relacionadas con la cartera/saldo |
| `ia_prediction` | Predicciones generadas por IA sobre transporte |
| `gift` | Bonos, ofertas especiales, promociones |
| `driver` | Notificaciones para conductores |
| `system` | Notificaciones del sistema |

### Módulos Disponibles

| Módulo | Descripción |
|---|---|
| `module_2` | Módulo de Cartera/Pagos |
| `module_8_1` | Módulo de Predicción de IA |
| `module_driver_earnings` | Módulo de Ganancias del Conductor |
| `module_payment` | Módulo de Pagos |
| `module_routes` | Módulo de Rutas |

---

## Relaciones entre Colecciones

### Diagrama de Relaciones

```
┌──────────────┐
│    USERS     │
│              │
│ uid (PK)     │◄─────┐
│ full_name    │      │
│ email        │      │
│ wallet       │      │
│ settings     │      │
└──────────────┘      │
                      │
                      │ user_id (FK)
                      │
        ┌─────────────┼──────────────┐
        │             │              │
   ┌────────────┐ ┌────────────┐ ┌────────────────┐
   │TRANSACTIONS│ │NOTIFICATION│ │TRANSPORT_LINES │
   │            │ │            │ │                │
   │ user_id    │ │ user_id    │ │ line_id (PK)   │
   │ amount     │ │ title      │ │ line_name      │
   │ timestamp  │ │ content    │ │ route_points   │
   └────────────┘ └────────────┘ │                │
                                  │  (sub-coll)   │
                                  │  SCHEDULES     │
                                  │                │
                                  │  time          │
                                  │  departure_time│
                                  │  availability  │
                                  └────────────────┘
```

### Cómo se Vinculan

**1. Usuarios ↔ Transacciones**
```
users.uid = transactions.user_id
```
Para obtener todas las transacciones de un usuario:
```dart
final transactions = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_id', isEqualTo: 'user_001')
    .get();
```

**2. Usuarios ↔ Notificaciones**
```
users.uid = notifications.user_id
```
Para obtener notificaciones no leídas:
```dart
final unreadNotifications = await FirebaseFirestore.instance
    .collection('notifications')
    .where('user_id', isEqualTo: 'user_001')
    .where('is_read', isEqualTo: false)
    .get();
```

**3. Líneas de Transporte ↔ Horarios**
```
transport_lines.line_id → schedules (subcollection)
```
Es una relación de uno a muchos (una línea tiene múltiples horarios):
```dart
final schedules = await FirebaseFirestore.instance
    .collection('transport_lines')
    .doc('line_138')
    .collection('schedules')
    .get();
```

---

## Guía de Tipos de Datos

### String
Texto. Puede contener letras, números y caracteres especiales.
```
Ejemplo: "Juan Pérez García"
```

### Double
Número decimal. Se usa para cantidades de dinero.
```
Ejemplo: 67.50
```

### Integer
Número entero. Se usa para conteos o porcentajes.
```
Ejemplo: 40, 100
```

### Boolean
Valor verdadero o falso. Solo dos opciones: `true` o `false`
```
Ejemplo: true, false
```

### Timestamp
Fecha y hora. Se almacena en formato ISO 8601.
```
Ejemplo: 2026-05-05T10:30:00Z
```

### Array
Lista de elementos. En este caso, lista de objetos con latitud/longitud.
```json
[
  {"latitude": -16.5283, "longitude": -68.1493, "name": "Centro"},
  {"latitude": -16.5350, "longitude": -68.1350, "name": "Plaza Avaroa"}
]
```

### Map / Objeto
Colección de pares clave-valor.
```json
{
  "current_balance": 67.50,
  "currency": "Bs"
}
```

---

## 📌 Reglas Importantes

### ✅ Hacer

- Usar `uid` de Firebase Auth como ID principal para usuarios
- Denormalizar datos que se usan juntos (como wallet en users)
- Crear subcollections para datos que crecen indefinidamente (como schedules)
- Usar timestamps para todas las fechas
- Referenciar documentos por su ID, no duplicar datos

### ❌ No Hacer

- No duplicar información del usuario en cada transacción
- No crear colecciones anidadas más de 2 niveles
- No usar strings para datos que deberían ser números
- No guardar referencias en texto plano sin la estructura del ID

---

## 🔍 Consultas Comunes

### Obtener Perfil de Usuario
```dart
final user = await FirebaseFirestore.instance
    .collection('users')
    .doc('user_001')
    .get();

print(user['full_name']); // "Juan Pérez García"
print(user['wallet']['current_balance']); // 67.50
```

### Obtener Todas las Líneas Activas
```dart
final lines = await FirebaseFirestore.instance
    .collection('transport_lines')
    .where('status', isEqualTo: 'active')
    .get();
```

### Obtener Horarios Disponibles
```dart
final schedules = await FirebaseFirestore.instance
    .collection('transport_lines')
    .doc('line_138')
    .collection('schedules')
    .where('seat_availability_percent', isGreaterThan: 0)
    .orderBy('seat_availability_percent', descending: true)
    .get();
```

### Obtener Últimas Transacciones
```dart
final transactions = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_id', isEqualTo: 'user_001')
    .orderBy('timestamp', descending: true)
    .limit(10)
    .get();
```

### Obtener Total de Ganancias del Conductor
```dart
final earnings = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_id', isEqualTo: 'driver_001')
    .where('transaction_type', isEqualTo: 'driver_earning')
    .get();

double total = 0;
for (var doc in earnings.docs) {
  total += doc['amount'];
}
print('Total ganancias: $total Bs');
```

---

## 📊 Ejemplo Práctico Completo

### Escenario: Un Usuario Compra un Pasaje

1. **El usuario selecciona Línea 138, horario 08:00**
2. **Se crea una transacción:**
```json
{
  "user_id": "user_001",
  "transaction_type": "trip_payment",
  "amount": 2.00,
  "description": "Pago Transporte Línea 138",
  "timestamp": "2026-05-05T08:00:00Z",
  "payment_method": "wallet",
  "status": "completed"
}
```

3. **Se actualiza el saldo del usuario:**
```json
{
  "wallet": {
    "current_balance": 65.50  // 67.50 - 2.00
  }
}
```

4. **Se crea una notificación:**
```json
{
  "user_id": "user_001",
  "category": "wallet",
  "title": "Pasaje Comprado",
  "content": "Compraste un pasaje Línea 138 por Bs 2.00",
  "is_read": false,
  "created_at": "2026-05-05T08:00:00Z",
  "deep_link_module": "module_routes"
}
```

---

**Última actualización:** 11 de mayo de 2026
**Versión:** 1.0
