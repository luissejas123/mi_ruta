# 🚀 Inicialización de Firestore - Estructura para Nuevos Usuarios

Esta guía documenta cómo Firestore se inicializa para nuevos usuarios y proporciona datos de prueba.

---

## 📌 Cuándo se Crea la Billetera

La billetera se crea automáticamente **durante el registro del usuario** en la función de registro (RegisterUseCase).

### Flujo de Registro

```
User → Register Form
  ↓
RegisterEvent → AuthBloc
  ↓
RegisterUseCase
  ↓
AuthRepository.register()
  ↓
[AQUI] WalletService.createNewUserWallet(uid, initialBalance: 0.0)
  ↓
Firebase Auth + Firestore → User Document + Wallet Subcollection
  ↓
AuthLoaded state → WalletPage
```

---

## 🔧 Implementación en RegisterUseCase

**Ubicación:** `lib/features/auth/domain/usecases/auth_usecases.dart`

Actualmente el registro crea el usuario en Auth y Firestore, pero **NO** crea la billetera.

### ✅ Dónde Agregar la Inicialización

En `auth_remote_datasource_impl.dart` en el método `register()`:

```dart
Future<AuthModel> register({
  required String email,
  required String password,
  required String fullName,
  required String governmentId,
  required String phoneNumber,
  required String role,
}) async {
  try {
    // 1. Crear usuario en Firebase Auth
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    // 2. Crear documento de usuario en Firestore
    await _firebaseFirestore.collection('users').doc(uid).set({
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'government_id': governmentId,
      'phone_number': phoneNumber,
      'profile_picture_url': '',
      'role': role,
      'created_at': FieldValue.serverTimestamp(),
      // 3. ✅ AQUI: Crear billetera inicial
      'wallet': {
        'current_balance': 0.0,
        'currency': 'Bs',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      // 4. Crear configuración inicial
      'settings': {
        'dark_mode_enabled': false,
        'is_driver_mode': false,
      }
    });

    // 5. Obtener y devolver usuario creado
    final userDoc = await _firebaseFirestore.collection('users').doc(uid).get();
    return AuthModel.fromJson(userDoc.data()!);

  } on FirebaseAuthException catch (e) {
    throw Exception('Error registro: ${e.message}');
  } catch (e) {
    throw Exception('Error inesperado: $e');
  }
}
```

---

## 📊 Estructura de Documento Esperada

### Usuario Nuevo - Primer Login

```json
{
  "uid": "abc123xyz",
  "full_name": "Juan Pérez García",
  "email": "juan@example.com",
  "government_id": "12345678LP",
  "phone_number": "+591 70123456",
  "profile_picture_url": "",
  "role": "user",
  "created_at": "2026-05-19T15:30:00Z",
  "wallet": {
    "current_balance": 0.0,
    "currency": "Bs",
    "created_at": "2026-05-19T15:30:00Z",
    "updated_at": "2026-05-19T15:30:00Z"
  },
  "settings": {
    "dark_mode_enabled": false,
    "is_driver_mode": false
  }
}
```

---

## 🧪 Datos de Prueba Manualmente

Si necesitas crear datos de prueba sin usar el registro de app, usa la Consola de Firestore:

### 1. Usuario Demo con Billetera

**Ruta:** `users` → `user_demo` → Document

```json
{
  "uid": "user_demo",
  "full_name": "Usuario Demo",
  "email": "demo@example.com",
  "government_id": "0000000SCP",
  "phone_number": "+591 70000000",
  "profile_picture_url": "https://i.pravatar.cc/150?img=1",
  "role": "user",
  "created_at": "2026-01-15T10:30:00Z",
  "wallet": {
    "current_balance": 67.50,
    "currency": "Bs",
    "created_at": "2026-01-15T10:30:00Z",
    "updated_at": "2026-05-05T18:45:00Z"
  },
  "settings": {
    "dark_mode_enabled": false,
    "is_driver_mode": false
  }
}
```

### 2. Historial de Transacciones Demo

**Ruta:** `transactions` → Auto-ID

```json
{
  "user_id": "user_demo",
  "transaction_type": "top_up",
  "amount": 50.00,
  "description": "Recarga de saldo",
  "timestamp": "2026-05-05T08:00:00Z",
  "payment_method": "wallet",
  "status": "completed"
}
```

```json
{
  "user_id": "user_demo",
  "transaction_type": "trip_payment",
  "amount": 2.00,
  "description": "Pago Línea 202 - Línea 202",
  "timestamp": "2026-05-05T09:30:00Z",
  "payment_method": "wallet",
  "status": "completed",
  "route_number": "202",
  "route_name": "Línea 202"
}
```

```json
{
  "user_id": "user_demo",
  "transaction_type": "trip_payment",
  "amount": 1.50,
  "description": "Pago Línea 138 - Línea 138",
  "timestamp": "2026-05-05T14:15:00Z",
  "payment_method": "wallet",
  "status": "completed",
  "route_number": "138",
  "route_name": "Línea 138"
}
```

---

## 🛡️ Validaciones Automáticas

El sistema valida automáticamente:

1. **Al cargar billetera:**
   ```dart
   if (wallet == null) {
     // Intentar inicializar automáticamente
     wallet = await walletService.ensureWalletExists(userId);
   }
   ```

2. **Al hacer un pago:**
   ```dart
   if (currentBalance < amount) {
     throw 'Saldo insuficiente. Faltante: BS. ${(amount - currentBalance).toStringAsFixed(2)}';
   }
   ```

3. **Al recargar:**
   ```dart
   if (amount <= 0) {
     throw 'El monto debe ser mayor a 0';
   }
   ```

---

## 🔌 Endpoints de Inicialización en WalletService

```dart
// Para llamar durante registro:
await walletService.createNewUserWallet(
  userId,
  initialBalance: 0.0,  // o cualquier otro monto
);

// Para usuarios sin billetera:
await walletService.ensureWalletExists(userId);

// Para validar:
bool hasWallet = await walletService.hasValidWallet(userId);
```

---

## 📋 Checklist de Configuración

- [ ] WalletDatasource registrado en dependency_injection.dart
- [ ] WalletService registrado en dependency_injection.dart
- [ ] WalletBloc registrado en dependency_injection.dart
- [ ] WalletBloc agregado a MultiBlocProvider en main.dart
- [ ] AuthBloc conectado en wallet_page.dart
- [ ] Billetera se crea en RegisterUseCase
- [ ] Usuario demo con datos de prueba creado manualmente en Firestore
- [ ] Transacciones de prueba creadas manualmente

---

## 🧪 Pruebas de Integración

### Prueba 1: Registrar Usuario Nuevo
```
1. Ir a Registro
2. Llenar formulario
3. Enviar
4. Verificar en Firestore: users/{uid}/wallet existe
5. Saldo inicial: 0.00
```

### Prueba 2: Recarga de Saldo
```
1. Ir a wallet_page
2. Ver saldo actual (debe ser 0.00)
3. Click "Recargar Saldo"
4. Ingresar monto: 50.00
5. Confirmar
6. Verificar: Saldo actualizado a 50.00
7. Verificar en Firestore: transactions contiene el registro
```

### Prueba 3: Pago de Viaje
```
1. Ir a wallet_page con saldo 50.00
2. Click "Pagar"
3. Escanear QR (o simular)
4. Monto: 2.00
5. Confirmar pago
6. Verificar: Saldo es ahora 48.00
7. Verificar: Transacción registrada como trip_payment
```

### Prueba 4: Historial de Movimientos
```
1. Ir a movimientos_page
2. Ver transacciones ordenadas por fecha (más reciente primero)
3. Tipos: Verde (+) para top_up, Rojo (-) para trip_payment
4. Fechas formateadas correctamente
```

---

## 🐛 Debugging

### Ver estructura actual de usuario en Firestore
```
1. Abrir Firestore Console
2. Colección: users
3. Documento: user_demo (o uid del usuario)
4. Expandir: wallet → Ver campos
```

### Ver transacciones registradas
```
1. Firestore Console
2. Colección: transactions
3. Filtrar: user_id == "user_demo"
4. Ver campos: timestamp, amount, description
```

### Logs en App
Agregar logs para debugging:
```dart
print('WalletBloc: Cargando billetera para $userId');
print('Saldo actual: ${wallet.currentBalance}');
print('Transacciones: ${transactions.length}');
```

---

## 📞 Próximos Pasos

1. **Implementar InitializeUserWalletEvent** en AuthBloc después de login exitoso
2. **Crear billetera en RegisterUseCase** (ver sección anterior)
3. **Agregar Cloud Function** para crear billetera automáticamente on auth
4. **Integrar pago QR** con PayTripEvent en pago_qr_page.dart
5. **Agregar notificaciones** cuando saldo baja de umbral
