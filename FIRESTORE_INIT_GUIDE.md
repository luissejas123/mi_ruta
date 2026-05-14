# 🔥 Guía: Inicializar Estructura de Firestore

## 📋 Descripción

Este documento explica cómo inicializar la estructura de colecciones en Firebase Firestore con datos mock. Esto permite que todos los desarrolladores trabajen con la misma estructura de datos desde el inicio.

---

## 🏗️ Estructura de Colecciones Propuesta

```
Firestore Database
├── users (Collection)
│   ├── user_001 (Document)
│   │   ├── full_name: String
│   │   ├── email: String
│   │   ├── government_id: String
│   │   ├── phone_number: String
│   │   ├── profile_picture_url: String
│   │   ├── role: String ("user", "driver", "admin")
│   │   ├── created_at: Timestamp
│   │   ├── wallet: {
│   │   │   ├── current_balance: Double
│   │   │   └── currency: String
│   │   └── settings: {
│   │       ├── dark_mode_enabled: Boolean
│   │       └── is_driver_mode: Boolean
│   ├── driver_001 (Document)
│   └── ...
│
├── transport_lines (Collection)
│   ├── line_138 (Document)
│   │   ├── line_name: String
│   │   ├── transport_type: String ("trufi", "micro")
│   │   ├── status: String ("active", "suspended")
│   │   ├── base_fare: Double
│   │   ├── route_points: Array<{latitude, longitude, name}>
│   │   ├── created_at: Timestamp
│   │   └── schedules (Sub-collection)
│   │       ├── 07-30 (Document)
│   │       │   ├── departure_time: String
│   │       │   ├── estimated_arrival_minutes: Integer
│   │       │   ├── seat_availability_percent: Integer
│   │       │   └── comfort_level: String
│   │       ├── 08-00
│   │       └── ...
│   ├── line_133
│   └── ...
│
├── transactions (Collection)
│   ├── auto-id-001 (Document)
│   │   ├── user_id: String (Reference to users.uid)
│   │   ├── transaction_type: String ("top_up", "trip_payment")
│   │   ├── amount: Double
│   │   ├── description: String
│   │   ├── timestamp: Timestamp
│   │   ├── payment_method: String ("QR", "wallet")
│   │   └── status: String
│   └── ...
│
└── notifications (Collection)
    ├── auto-id-001 (Document)
    │   ├── user_id: String (Reference to users.uid)
    │   ├── category: String ("wallet", "ia_prediction", "gift")
    │   ├── title: String
    │   ├── content: String
    │   ├── is_read: Boolean
    │   ├── created_at: Timestamp
    │   └── deep_link_module: String
    └── ...
```

---

## 🚀 Cómo Funciona la Inicialización

### **Archivo: `firestore_structure_mocks.dart`**

Contiene todas las constantes con datos mock para las 4 colecciones principales:
- `mockUsers` - Usuarios (user, driver, admin)
- `mockTransportLines` - Líneas de transporte (micro, trufi)
- `mockSchedulesLine138` - Horarios para cada línea
- `mockTransactions` - Historial de transacciones
- `mockNotifications` - Notificaciones de usuarios

### **Archivo: `firestore_initialization_service.dart`**

Contiene la clase `FirestoreInitializationService` con métodos para:
- `initializeFirestoreStructure()` - Crea todas las colecciones
- `isFirestoreInitialized()` - Verifica si ya está inicializado
- `clearAllCollections()` - Limpia todas las colecciones (⚠️ CUIDADO)
- `getCollectionsStats()` - Obtiene estadísticas
- `printCollectionsSummary()` - Imprime resumen en consola

### **Archivo: `main.dart`**

Ejecuta automáticamente en el primer inicio:
```dart
final firestoreService = FirestoreInitializationService();
final isInitialized = await firestoreService.isFirestoreInitialized();

if (!isInitialized) {
  await firestoreService.initializeFirestoreStructure();
}
```

---

## 📊 Datos Iniciales por Colección

### **1. USERS (3 documentos)**

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

**Documentos incluidos:**
- `user_001` - Pasajero regular
- `driver_001` - Conductor
- `admin_001` - Administrador

---

### **2. TRANSPORT_LINES (3 documentos)**

```json
{
  "line_id": "line_138",
  "line_name": "Línea 138",
  "transport_type": "micro",
  "status": "active",
  "base_fare": 2.00,
  "route_points": [
    {"latitude": -16.5283, "longitude": -68.1493, "name": "Centro"},
    {"latitude": -16.5350, "longitude": -68.1350, "name": "Plaza Avaroa"},
    {"latitude": -16.5400, "longitude": -68.1200, "name": "Zona Sur"}
  ],
  "created_at": "2024-03-15T00:00:00Z"
}
```

**Documentos incluidos:**
- `line_138` - Micro (Centro - Zona Sur)
- `line_133` - Trufi (Calacoto - Aeropuerto)
- `line_112` - Micro (Villa Fátima - Obrajes)

---

### **3. TRANSPORT_LINES/SCHEDULES (Sub-collection)**

```json
{
  "time": "07-30",
  "departure_time": "7:30 AM",
  "estimated_arrival_minutes": 25,
  "seat_availability_percent": 40,
  "comfort_level": "available"
}
```

**6 horarios incluidos** para cada línea:
- 07:30, 08:00, 08:30, 09:00, 14:30, 17:00

---

### **4. TRANSACTIONS (4 documentos)**

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

**Documentos incluidos:**
- 1 top-up (recarga)
- 2 trip_payments (viajes)
- 1 driver_earning (ganancias)

---

### **5. NOTIFICATIONS (4 documentos)**

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

**Categorías incluidas:**
- `wallet` - Alertas de saldo
- `ia_prediction` - Predicciones de IA
- `gift` - Bonos especiales

---

## 🛠️ Cómo Usar en tu Aplicación

### **1. Ejecutar Inicialización (Automático)**

La inicialización se ejecuta automáticamente en `main.dart` la primera vez:

```bash
flutter run
```

Verás en la consola:
```
🚀 Primera vez: Inicializando estructura de Firestore...
📝 Creando colección: users
  ✓ Usuario creado: user_001
  ✓ Usuario creado: driver_001
  ✓ Usuario creado: admin_001
🚌 Creando colección: transport_lines
  ✓ Línea de transporte creada: line_138
  📅 Creando subcollection schedules para: line_138
    ✓ Schedule creado: 07-30
    ✓ Schedule creado: 08-00
    ...
✅ Estructura de Firestore inicializada correctamente
```

---

### **2. Verificar Datos en Firebase Console**

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto: **mi-ruta-4004d**
3. Ve a **Firestore Database**
4. Verás las colecciones:
   - ✅ users
   - ✅ transport_lines (con subcollection schedules)
   - ✅ transactions
   - ✅ notifications

---

### **3. Usar Datos en tu Código**

**Desde BLoC:**
```dart
import 'package:mi_ruta/mocks/firestore_structure_mocks.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  RoutesBloc() : super(RoutesInitialState());

  Future<void> _onFetchRoutes(FetchRoutesEvent event, Emitter emit) async {
    // Usar datos mock mientras desarrollas
    final routes = FirestoreStructureMocks.mockTransportLines;
    emit(RoutesLoadedState(routes: routes));
  }
}
```

**Desde Page:**
```dart
class TransportLinesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lines = FirestoreStructureMocks.mockTransportLines;
    
    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Card(
          child: ListTile(
            title: Text(line['line_name']),
            subtitle: Text(line['transport_type']),
            trailing: Text('${line['base_fare']} Bs'),
          ),
        );
      },
    );
  }
}
```

---

### **4. Consultar Datos de Firestore**

**Obtener todos los usuarios:**
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .get();

for (var doc in snapshot.docs) {
  print(doc['full_name']); // Juan Pérez García
}
```

**Obtener una línea de transporte con horarios:**
```dart
final line = await FirebaseFirestore.instance
    .collection('transport_lines')
    .doc('line_138')
    .get();

final schedules = await line.reference
    .collection('schedules')
    .orderBy('time')
    .get();

for (var schedule in schedules.docs) {
  print(schedule['departure_time']); // 7:30 AM, 8:00 AM, ...
}
```

**Obtener transacciones de un usuario:**
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('transactions')
    .where('user_id', isEqualTo: 'user_001')
    .orderBy('timestamp', descending: true)
    .get();
```

**Obtener notificaciones no leídas:**
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('notifications')
    .where('user_id', isEqualTo: 'user_001')
    .where('is_read', isEqualTo: false)
    .get();
```

---

## 🔧 Operaciones Útiles

### **Reimicializar Datos (Limpiar + Crear de nuevo)**

```dart
final service = FirestoreInitializationService();

// Limpiar todo
await service.clearAllCollections();

// Volver a inicializar
await service.initializeFirestoreStructure();
```

### **Ver Estadísticas**

```dart
final service = FirestoreInitializationService();
await service.printCollectionsSummary();

// Output:
// 📊 RESUMEN DE COLECCIONES
// ================================
// users: 3 documentos
// transport_lines: 3 documentos
// transactions: 4 documentos
// notifications: 4 documentos
// ================================
```

---

## ⚙️ Reglas de Seguridad de Firestore

Para desarrollo/testing, agregar estas reglas en **Firestore Console** → **Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura/escritura para desarrollo
    match /{document=**} {
      allow read, write: if request.auth != null || true;
    }
  }
}
```

⚠️ **Nota:** Estas reglas son solo para desarrollo. Para producción, implementar autenticación adecuada.

---

## 📝 Para Otros Desarrolladores

**Instrucciones para nuevos desarrolladores:**

1. ✅ Clonar el repositorio
2. ✅ Ejecutar `flutter pub get`
3. ✅ Ejecutar `flutter run -d android` (o el emulador que uses)
4. ✅ La estructura de Firestore se inicializará automáticamente
5. ✅ Verificar datos en Firebase Console

**No necesitan hacer nada adicional. Todo está automatizado.**

---

## 🎯 Próximos Pasos

1. **Implementar Entities** - Crear clases que representen los documentos
2. **Implementar Models** - Models que extiendan entities con serialización
3. **Implementar Repositories** - Obtener datos de Firestore y mapearlos
4. **Reemplazar Mocks en Código** - Cambiar de mock_data a repositorios reales

---

**Última actualización:** 11 de mayo de 2026
