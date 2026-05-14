# 🔧 Guía: Arquitectura de Funciones para Obtener Datos de Firestore

## 📌 El Problema

Si llamamos a Firestore directamente desde cada página/widget:
```dart
// ❌ MAL - Llamadas directas (ineficiente)
class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc('user_001')
          .get(),  // ← Llamada directa
      builder: (context, snapshot) { ... }
    );
  }
}
```

**Problemas:**
- ❌ Repetir código en muchos lugares
- ❌ Difícil de mantener
- ❌ Sin caché de datos
- ❌ Difícil de testear
- ❌ Múltiples lecturas de la BD

---

## ✅ La Solución: Clean Architecture

Estructura el código en capas que usen funciones centralizadas:

```
Frontend (Pages/Widgets)
    ↓
Presentation Layer (BLoC)
    ↓
Domain Layer (UseCases)
    ↓
Data Layer (Repositories)
    ↓
Firestore / Backend
```

---

## 🏗️ Implementación Paso a Paso

### **PASO 1: Crear Entity (Modelo de Negocio)**

Archivo: `lib/features/user/domain/entities/user_entity.dart`

```dart
class UserEntity {
  final String uid;
  final String fullName;
  final String email;
  final String governmentId;
  final String phoneNumber;
  final String profilePictureUrl;
  final String role;
  final DateTime createdAt;
  final double currentBalance;
  final String currency;
  final bool darkModeEnabled;
  final bool isDriverMode;

  UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.governmentId,
    required this.phoneNumber,
    required this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    required this.currentBalance,
    required this.currency,
    required this.darkModeEnabled,
    required this.isDriverMode,
  });
}
```

---

### **PASO 2: Crear Model (Con serialización JSON)**

Archivo: `lib/features/user/data/models/user_model.dart`

```dart
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required String uid,
    required String fullName,
    required String email,
    required String governmentId,
    required String phoneNumber,
    required String profilePictureUrl,
    required String role,
    required DateTime createdAt,
    required double currentBalance,
    required String currency,
    required bool darkModeEnabled,
    required bool isDriverMode,
  }) : super(
    uid: uid,
    fullName: fullName,
    email: email,
    governmentId: governmentId,
    phoneNumber: phoneNumber,
    profilePictureUrl: profilePictureUrl,
    role: role,
    createdAt: createdAt,
    currentBalance: currentBalance,
    currency: currency,
    darkModeEnabled: darkModeEnabled,
    isDriverMode: isDriverMode,
  );

  /// Convertir JSON de Firestore a Model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      governmentId: json['government_id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentBalance: (json['wallet']?['current_balance'] ?? 0).toDouble(),
      currency: json['wallet']?['currency'] ?? 'Bs',
      darkModeEnabled: json['settings']?['dark_mode_enabled'] ?? false,
      isDriverMode: json['settings']?['is_driver_mode'] ?? false,
    );
  }

  /// Convertir Model a JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'government_id': governmentId,
      'phone_number': phoneNumber,
      'profile_picture_url': profilePictureUrl,
      'role': role,
      'created_at': createdAt,
      'wallet': {
        'current_balance': currentBalance,
        'currency': currency,
      },
      'settings': {
        'dark_mode_enabled': darkModeEnabled,
        'is_driver_mode': isDriverMode,
      },
    };
  }
}
```

---

### **PASO 3: Crear Interfaz del Repositorio (Contrato)**

Archivo: `lib/features/user/domain/repositories/user_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/errors/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Obtener usuario por ID
  Future<Either<Failure, UserEntity>> getUserById(String uid);

  /// Obtener usuario actual (autenticado)
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Actualizar perfil del usuario
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);

  /// Obtener todos los usuarios
  Future<Either<Failure, List<UserEntity>>> getAllUsers();

  /// Buscar usuarios por nombre
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query);
}
```

---

### **PASO 4: Crear DataSource (Conexión a Firestore)**

Archivo: `lib/features/user/data/datasources/user_remote_datasource.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUserById(String uid);
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateUser(UserModel user);
  Future<List<UserModel>> getAllUsers();
  Future<List<UserModel>> searchUsers(String query);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl(this._firestore);

  @override
  Future<UserModel> getUserById(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      
      if (!snapshot.exists) {
        throw Exception('Usuario no encontrado');
      }

      return UserModel.fromJson(snapshot.data()!);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    // Obtener UID del usuario autenticado
    // Por ahora usamos un UID de prueba
    return getUserById('user_001');
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
      return user;
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('full_name', isGreaterThanOrEqualTo: query)
          .where('full_name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }
}
```

---

### **PASO 5: Crear Implementación del Repositorio**

Archivo: `lib/features/user/data/repositories/user_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/errors/failures.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> getUserById(String uid) async {
    try {
      final user = await remoteDataSource.getUserById(uid);
      return Right(user);
    } on Exception catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on Exception catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      final userModel = user as UserModel;
      final updatedUser = await remoteDataSource.updateUser(userModel);
      return Right(updatedUser);
    } on Exception catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final users = await remoteDataSource.getAllUsers();
      return Right(users.cast<UserEntity>());
    } on Exception catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> searchUsers(String query) async {
    try {
      final users = await remoteDataSource.searchUsers(query);
      return Right(users.cast<UserEntity>());
    } on Exception catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
```

---

### **PASO 6: Crear UseCases (Lógica de Negocio)**

Archivo: `lib/features/user/domain/usecases/get_user_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/errors/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';

class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String uid) async {
    return await repository.getUserById(uid);
  }
}
```

Archivo: `lib/features/user/domain/usecases/get_current_user_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/errors/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';

class GetCurrentUserUseCase {
  final UserRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getCurrentUser();
  }
}
```

---

### **PASO 7: Crear BLoC (Gestión de Estado)**

Archivo: `lib/features/user/presentation/bloc/user_event.dart`

```dart
abstract class UserEvent {}

class GetCurrentUserEvent extends UserEvent {}

class GetUserByIdEvent extends UserEvent {
  final String userId;
  GetUserByIdEvent(this.userId);
}

class SearchUsersEvent extends UserEvent {
  final String query;
  SearchUsersEvent(this.query);
}

class UpdateUserEvent extends UserEvent {
  final UserEntity user;
  UpdateUserEvent(this.user);
}
```

Archivo: `lib/features/user/presentation/bloc/user_state.dart`

```dart
abstract class UserState {}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class UserLoadedState extends UserState {
  final UserEntity user;
  UserLoadedState(this.user);
}

class UsersListLoadedState extends UserState {
  final List<UserEntity> users;
  UsersListLoadedState(this.users);
}

class UserErrorState extends UserState {
  final String message;
  UserErrorState(this.message);
}
```

Archivo: `lib/features/user/presentation/bloc/user_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_user_usecase.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_user_usecase.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetUserUseCase getUserUseCase;

  UserBloc({
    required this.getCurrentUserUseCase,
    required this.getUserUseCase,
  }) : super(UserInitialState()) {
    
    on<GetCurrentUserEvent>((event, emit) async {
      emit(UserLoadingState());
      
      final result = await getCurrentUserUseCase();
      
      result.fold(
        (failure) => emit(UserErrorState(failure.message)),
        (user) => emit(UserLoadedState(user)),
      );
    });

    on<GetUserByIdEvent>((event, emit) async {
      emit(UserLoadingState());
      
      final result = await getUserUseCase(event.userId);
      
      result.fold(
        (failure) => emit(UserErrorState(failure.message)),
        (user) => emit(UserLoadedState(user)),
      );
    });
  }
}
```

---

### **PASO 8: Usar en Pages (Frontend)**

Archivo: `lib/features/user/presentation/pages/user_profile_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UserLoadedState) {
              final user = state.user;
              return ListView(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundImage: NetworkImage(user.profilePictureUrl),
                    radius: 50,
                  ),
                  
                  // Nombre
                  ListTile(
                    title: Text(user.fullName),
                    subtitle: Text(user.email),
                  ),
                  
                  // Teléfono
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(user.phoneNumber),
                  ),
                  
                  // Rol
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(user.role),
                  ),
                  
                  // Saldo
                  ListTile(
                    leading: const Icon(Icons.wallet),
                    title: Text('${user.currentBalance} ${user.currency}'),
                  ),
                ],
              );
            }

            return const Center(child: Text('Cargar datos'));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Disparar evento para cargar datos del usuario actual
          context.read<UserBloc>().add(GetCurrentUserEvent());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

---

### **PASO 9: Configurar Inyección de Dependencias**

Archivo: `lib/main.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/data/repositories/user_repository_impl.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_user_usecase.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_user_usecase.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Firebase
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  // DataSources
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(getIt<FirebaseFirestore>()),
  );

  // Repositories
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(getIt<UserRemoteDataSource>()),
  );

  // UseCases
  getIt.registerSingleton(GetUserUseCase(getIt<UserRepository>()));
  getIt.registerSingleton(GetCurrentUserUseCase(getIt<UserRepository>()));

  // BLoCs
  getIt.registerSingleton(
    UserBloc(
      getCurrentUserUseCase: getIt(),
      getUserUseCase: getIt(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  setupDependencies();

  runApp(const MyApp());
}
```

---

## 📊 Diagrama del Flujo

```
┌────────────────┐
│ UserProfilePage│  ← Frontend (UI)
└────────┬────────┘
         │
         │ add(GetCurrentUserEvent())
         ↓
┌────────────────┐
│   UserBloc     │  ← Estado
└────────┬────────┘
         │
         │ call()
         ↓
┌────────────────────────┐
│ GetCurrentUserUseCase  │  ← Lógica de Negocio
└────────┬───────────────┘
         │
         │ getCurrentUser()
         ↓
┌────────────────────┐
│  UserRepository    │  ← Interfaz
└────────┬───────────┘
         │
         │ getUserById()
         ↓
┌────────────────────┐
│ UserRepositoryImpl  │  ← Implementación
└────────┬───────────┘
         │
         │ call()
         ↓
┌────────────────────────────┐
│ UserRemoteDataSourceImpl    │  ← Conexión Firestore
└────────┬───────────────────┘
         │
         │ get('users').doc(uid)
         ↓
┌────────────────────┐
│  Firestore Database│  ← Datos
└────────────────────┘
```

---

## 🎯 Ventajas de Este Sistema

✅ **Reutilizable** - Una sola llamada a Firestore, usada en múltiples lugares  
✅ **Testeable** - Cada capa puede ser testeada independientemente  
✅ **Mantenible** - Cambios en un solo lugar  
✅ **Escalable** - Fácil agregar nuevas features  
✅ **Separación de responsabilidades** - Cada capa tiene un propósito  
✅ **Con caché** - Puedes agregar caché local fácilmente  
✅ **Manejo de errores** - Either<Failure, Data> para errores seguros  

---

## 💡 Tips

1. **Usar GetIt para inyección de dependencias** - Simplifica mucho el código

2. **Cachear datos localmente** - Para aplicaciones offline:
```dart
class UserLocalDataSource {
  Future<UserModel> getUserFromCache(String uid) async {
    // Usar SQLite o Hive
  }
}
```

3. **Combinar Local + Remote**:
```dart
Future<UserModel> getUserById(String uid) async {
  // 1. Intentar obtener del caché local
  try {
    return await localDataSource.getUser(uid);
  } catch (e) {
    // 2. Si falla, obtener de Firestore
    final user = await remoteDataSource.getUser(uid);
    // 3. Guardar en caché
    await localDataSource.saveUser(user);
    return user;
  }
}
```

4. **Usar Streams para datos en tiempo real**:
```dart
Stream<UserEntity> watchUserById(String uid) {
  return _firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) => UserModel.fromJson(snapshot.data()));
}
```

---

**Última actualización:** 11 de mayo de 2026
