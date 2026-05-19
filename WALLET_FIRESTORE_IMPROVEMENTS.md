# 🔄 Mejoras de Estructura Wallet-Firestore

## 📋 Análisis Actual

Se revisó la estructura de wallet implementada vs la estructura definida en `FIRESTORE_COLLECTIONS_GUIDE.md`.

### ✅ Lo que Está Bien
1. **WalletDatasource** lee correctamente desde `users/{uid}` con subcampo `wallet`
2. **Transacciones** se registran en colección global `transactions` con campos correctos
3. **BLoC** está bien estructurado con manejo de estados
4. **Entidad Wallet** tiene todos los campos necesarios
5. **Firestore Transactions** usadas para atomicidad en operaciones sensibles

### ⚠️ Mejoras Identificadas

#### 1. **Inicialización de Billetera**
**Problema:** No hay método para crear billetera inicial cuando el usuario se registra.

**Solución:** Agregar método `createWallet()` en WalletDatasource.
```dart
Future<void> createWallet(String userId, {double initialBalance = 0.0}) async {
  try {
    await _firestore.collection('users').doc(userId).set({
      'wallet': {
        'current_balance': initialBalance,
        'currency': 'Bs',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  } catch (e) {
    throw Exception('Error creando billetera: $e');
  }
}
```

#### 2. **Integración con AuthBloc**
**Problema:** userId está hardcodeado como `'user_demo'` en todas las páginas.

**Solución:** Extraer userId del AuthBloc state automáticamente.
```dart
// En _WalletPageState.initState()
final authState = context.read<AuthBloc>().state;
if (authState is AuthLoaded) {
  _userId = authState.user.uid;
} else {
  _userId = 'user_demo'; // fallback
}
```

#### 3. **Validación de Saldo Insuficiente**
**Problema:** El error de saldo insuficiente en `payTrip` no incluye el monto faltante.

**Solución:** Mejorar mensaje de error con detalles.
```dart
if (wallet.currentBalance < amount) {
  final shortage = amount - wallet.currentBalance;
  throw Exception(
    'Saldo insuficiente. Necesita: BS. ${shortage.toStringAsFixed(2)} más'
  );
}
```

#### 4. **Campos Faltantes en Transacciones**
**Problema:** Algunas transacciones pueden no incluir todos los campos recomendados.

**Solución:** Asegurar que todas las transacciones incluyen `route_number` y `route_name` incluso para top_ups.

#### 5. **Sincronización de Timestamps**
**Problema:** Se usa `FieldValue.serverTimestamp()` correctamente, pero no hay validación de sincronización.

**Solución:** Todos los timestamps ya usan serverTimestamp, está bien ✓

#### 6. **Subcollection vs Campo Anidado para Transacciones**
**Análisis:** Actualmente `transactions` es una colección global.

**Estado:** Esto es correcto según la guía. Las transacciones se guardan en colección global para poder consultarlas por usuario con queries.

---

## ✅ Estado Actual - Implementaciones Completadas

### ✨ Cambio 1: Mejorada WalletDatasource ✅
**Implementado:**
- Agregado método `createWallet()` para inicializar billetera de nuevos usuarios
- Agregado método `initializeWalletIfNotExists()` para usuarios sin billetera
- Mejorado mensaje de error en `deductTripPayment()` con detalles de monto faltante
- **Cambios realizados:**
  - `createWallet(userId, initialBalance)` - Crea billetera con timestamps servidor
  - `initializeWalletIfNotExists(userId)` - Inicializa si no existe
  - Error mejorado: muestra saldo disponible, necesario y faltante

### ✨ Cambio 2: Mejorada WalletService ✅
**Implementado:**
- Agregado `createNewUserWallet()` - Llamar durante registro
- Agregado `ensureWalletExists()` - Validar billetera existe
- Agregado `getWalletStats()` - Estadísticas (ingreso, gasto, transacciones)
- Agregado `getTransactionsByType()` - Filtrar por tipo de transacción
- Agregado `hasValidWallet()` - Validación de billetera válida
- **Métodos nuevos:**
  ```dart
  getWalletStats(userId) → Map<String, dynamic>
  getTransactionsByType(userId, type) → List<Map>
  hasValidWallet(userId) → bool
  ```

### ✨ Cambio 3: Conectado AuthBloc ✅
**Implementado:**
- `wallet_page.dart`: Obtiene userId de `AuthBloc.state.user.uid`
- `recarga_saldo_page.dart`: Conectado con AuthBloc
- `movimientos_page.dart`: Conectado con AuthBloc
- **Patrón implementado:**
  ```dart
  final authState = context.read<AuthBloc>().state;
  if (authState is AuthLoaded) {
    _userId = authState.user.uid;
  } else {
    _userId = 'user_demo'; // fallback
  }
  ```

### ⚠️ Estado Anterior (Lo que Faltaba)

## 🎯 Plan de Cambios - Actualizado

| Cambio | Estado | Detalles |
|--------|--------|----------|
| 1. Mejorar WalletDatasource | ✅ HECHO | createWallet(), initializeWalletIfNotExists(), errores mejorados |
| 2. Conectar con AuthBloc | ✅ HECHO | wallet_page, recarga_saldo_page, movimientos_page actualizadas |
| 3. Mejorar Mensajes Error | ✅ HECHO | payTrip() muestra monto faltante, validaciones mejoradas |
| 4. Agregar Métodos Utilitarios | ✅ HECHO | getWalletStats(), getTransactionsByType(), hasValidWallet() |
| 5. Documentación Firestore | ⏳ PENDIENTE | Crear script de inicialización para usuarios nuevos |

---

## 📊 Alineación con Guía Firestore - ACTUALIZADO

| Aspecto | Estado | Notas |
|--------|--------|-------|
| Colección `users` | ✅ Correcto | Acceso a `users/{uid}` |
| Subcampo `wallet` | ✅ Correcto | `current_balance`, `currency` |
| Timestamps | ✅ Correcto | Usar `serverTimestamp()` |
| Colección `transactions` | ✅ Correcto | Global, no subcollection |
| Campos de transacción | ⚠️ Mejorar | Agregar campos opcionales consistentemente |
| userId references | ⚠️ Mejorar | Conectar con AuthBloc |
| Atomicidad | ✅ Correcto | Usar `runTransaction()` |
| Inicialización | ❌ Falta | Agregar `createWallet()` |

---

## 💡 Recomendaciones Futuras

1. **Soft Deletes:** Agregar campo `is_deleted` en lugar de eliminar documentos
2. **Auditoría:** Campo `last_modified_by` en transacciones importantes
3. **Cachéing:** Implementar local cache con sqflite para menos consultas
4. **Batch Operations:** Para múltiples transacciones usar batch writes
5. **Analytics:** Tracking de patrones de gasto por usuario/línea

---

## ✨ Impacto de Cambios

- **Performance:** Mejor con creación inicial correcta
- **Reliability:** Más robusto con validaciones
- **UX:** Mensajes más claros para el usuario
- **Mantenibilidad:** Código más limpio y documentado
