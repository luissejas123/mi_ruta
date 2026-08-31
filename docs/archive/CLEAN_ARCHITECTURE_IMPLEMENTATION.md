# 🏗️ Clean Architecture Implementation - User Feature

## ✅ Completado: Feature User

He implementado una arquitectura limpia y profesional para la feature **User**. Aquí está el patrón que puedes replicar en todas las features.

---

## 📊 Estructura Implementada

```
lib/
├── core/
│   ├── di/
│   │   └── dependency_injection.dart (✅ CENTRALIZA todas las dependencias)
│   └── error/
│       └── failures.dart (✅ Manejo de errores)
│
├── features/user/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── user_remote_datasource.dart (✅ Interfaz)
│   │   │   └── user_remote_datasource_impl.dart (✅ Conexión a Firestore)
│   │   ├── models/
│   │   │   └── user_model.dart (✅ Serialización JSON)
│   │   └── repositories/
│   │       └── user_repository_impl.dart (✅ Manejo de errores)
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user_entity.dart (✅ Modelo de negocio puro)
│   │   ├── repositories/
│   │   │   └── user_repository.dart (✅ Interfaz del contrato)
│   │   └── usecases/
│   │       └── user_usecases.dart (✅ 6 funciones reutilizables)
│   │
│   └── presentation/
│       ├── bloc/
│       │   ├── user_bloc.dart (✅ Gestión de estado)
│       │   ├── user_event.dart (✅ 7 eventos)
│       │   └── user_state.dart (✅ 7 estados)
│       └── pages/
│           └── user_profile_page.dart (✅ Ejemplo de UI)
```

---

## 🎯 Las 6 Funciones Reutilizables (UseCases)

```dart
1. GetCurrentUserUseCase    → Obtener usuario autenticado
2. GetUserByIdUseCase       → Obtener usuario por ID
3. GetUsersByIdsUseCase     → Obtener múltiples usuarios
4. UpdateUserUseCase        → Actualizar datos
5. GetUserRatingUseCase     → Obtener calificación
6. GetUserStreamUseCase     → Stream en tiempo real
```

**✅ VENTAJA:** Llamas una sola vez desde cualquier página, sin repetir Firestore calls.

---

## 📱 Cómo Usar en Páginas

### Forma CORRECTA ✅

```dart
// En tu página/widget
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    if (state is UserLoaded) {
      return UserCard(user: state.user);
    }
    return LoadingWidget();
  },
);

// Para cargar datos
context.read<UserBloc>().add(GetUserByIdEvent(uid: 'user_001'));
context.read<UserBloc>().add(UpdateUserEvent(uid: 'user_001', data: {...}));
```

### Forma INCORRECTA ❌

```dart
// NO HAGAS ESTO
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();  // ❌ Llamada repetida en cada pantalla
```

---

## 🔧 Cómo Replicar para Otras Features

### 1️⃣ Crear Feature (ejemplo: Auth)

```bash
lib/features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart
│   │   └── auth_remote_datasource_impl.dart
│   ├── models/
│   │   └── auth_model.dart
│   └── repositories/
│       └── auth_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   └── auth_entity.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       └── auth_usecases.dart
│
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart
    │   ├── auth_event.dart
    │   └── auth_state.dart
    └── pages/
        ├── login_page.dart
        └── register_page.dart
```

### 2️⃣ Copiar Patrón de User a Auth

1. Renombrar `UserEntity` → `AuthEntity`
2. Copiar `user_datasources.dart` → `auth_datasources.dart`
3. Cambiar nombre de clases
4. Actualizar métodos (login, register, logout)
5. Copiar patrón de BLoC

### 3️⃣ Registrar en Dependency Injection

```dart
// En lib/core/di/dependency_injection.dart

void setupDependencies() {
  // ... USER

  // ============================================
  // AUTH FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(remoteDataSource: getIt<AuthRemoteDataSource>()),
  );

  // ... UseCases
  // ... BLoC

  getIt.registerSingleton<AuthBloc>(
    AuthBloc(...),
  );
}
```

### 4️⃣ Agregar en MultiBlocProvider

```dart
// En lib/main.dart

MultiBlocProvider(
  providers: [
    BlocProvider<UserBloc>(
      create: (context) => getIt<UserBloc>(),
    ),
    BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),  // ← Agregar aquí
    ),
  ],
  child: MaterialApp(...),
);
```

---

## 📚 Métodos Disponibles por Feature

### User Feature (✅ Implementada)
- `getCurrentUser()` → Usuario autenticado
- `getUserById(uid)` → Por ID
- `getUsersByIds(uids)` → Múltiples usuarios
- `updateUser(uid, data)` → Actualizar
- `getUserRating(uid)` → Calificación
- `getUserStream(uid)` → Stream en tiempo real

### Próximas a Implementar

**Auth Feature:**
- `login(email, password)`
- `register(email, password, userData)`
- `logout()`
- `resetPassword(email)`
- `getCurrentAuthUser()`

**Routes Feature:**
- `searchRoutes(origin, destination)`
- `getRoute(routeId)`
- `getRouteSchedules(routeId)`
- `updateRouteSchedule(routeId, scheduleId, data)`

**Payment Feature:**
- `getTransactions(uid, limit)`
- `createTransaction(uid, data)`
- `updateTransactionStatus(transactionId, status)`
- `getWalletBalance(uid)`
- `addMoneyToWallet(uid, amount)`

**Notifications Feature:**
- `getUserNotifications(uid, limit)`
- `markAsRead(notificationId)`
- `deleteNotification(notificationId)`
- `subscribeToNotifications(uid)` (Stream)

---

## 🚀 Ventajas de esta Arquitectura

| Aspecto | Beneficio |
|--------|----------|
| **Una Sola Fuente de Verdad** | Si cambias Firestore, cambias en 1 lugar |
| **Reutilizable** | UseCases usados en todas las páginas |
| **Testeable** | Mocking de DataSource sin BD real |
| **Manejo de Errores** | Either<Failure, Data> consistent |
| **Estado Centralizado** | BLoC maneja todo |
| **Escalable** | Fácil agregar nuevas features |
| **Profesional** | Usado en apps grandes (Netflix, Spotify) |
| **Performance** | Caché y Stream nativos de Firestore |

---

## 📝 Resumen para el Equipo

```
✅ AHORA: Usar el BLoC para acceder a datos
context.read<UserBloc>().add(GetUserByIdEvent(uid: 'user_001'));

❌ NUNCA: Llamar directamente a Firestore
FirebaseFirestore.instance.collection('users').doc(uid).get();
```

---

## 🔄 Flujo de Datos

```
Page (UI)
   ↓
BLoC (Event)
   ↓
UseCase (Business Logic)
   ↓
Repository (Error Handling)
   ↓
DataSource (Firestore Connection)
   ↓
Firestore (Database)
   ↓
Response (Model → Entity)
   ↓
BLoC (State Update)
   ↓
Page (Widget Rebuild)
```

Cada capa tiene responsabilidades claras. ¡No mezcles!

---

## ✨ Próximos Pasos

1. Implementar Auth feature igual que User
2. Replicar patrón en Routes, Payment, Notifications
3. Crear páginas usando los BLoCs
4. Agregar más métodos a cada UseCase según necesidad
5. Implementar caché local opcional con Hive

¡Tu arquitectura está lista para escalar! 🎉
