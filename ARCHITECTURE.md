# 🏗️ Estructura de Arquitectura - Mi Ruta

## 📋 Índice
1. [Visión General](#visión-general)
2. [Estructura General del Proyecto](#estructura-general-del-proyecto)
3. [Clean Architecture](#clean-architecture)
4. [Descripción de Carpetas](#descripción-de-carpetas)
5. [Ejemplo Detallado: Feature Users](#ejemplo-detallado-feature-users)
6. [Flujo de Datos](#flujo-de-datos)

---

## Visión General

El proyecto **Mi Ruta** sigue el patrón **Clean Architecture** que permite:
- ✅ Separación clara de responsabilidades
- ✅ Fácil mantenimiento y escalabilidad
- ✅ Testabilidad de código
- ✅ Independencia de frameworks y librerías
- ✅ Reutilización de código

---

## Estructura General del Proyecto

```
lib/
├── config/              # Configuración global
├── core/                # Código compartido y utilidades
├── features/            # Características principales del app
└── main.dart           # Punto de entrada

android/                # Configuración Android
ios/                    # Configuración iOS
web/                    # Configuración Web
windows/                # Configuración Windows
macos/                  # Configuración macOS
linux/                  # Configuración Linux
```

---

## Clean Architecture

La arquitectura se divide en **3 capas principales**:

### 1️⃣ **Capa de Presentación (Presentation Layer)**
- **Responsabilidad:** Interfaz de usuario y lógica de presentación
- **Componentes:** BLoC, Pages, Widgets
- **Tecnología:** Flutter widgets, BLoC para estado

### 2️⃣ **Capa de Dominio (Domain Layer)**
- **Responsabilidad:** Lógica de negocio independiente de frameworks
- **Componentes:** Entities, Repositories (interfaces), UseCases
- **Independencia:** No depende de Firebase ni de Flutter

### 3️⃣ **Capa de Datos (Data Layer)**
- **Responsabilidad:** Obtención y almacenamiento de datos
- **Componentes:** DataSources, Models, Repositories (implementación)
- **Acceso:** Conecta con APIs, Firestore, bases de datos locales

---

## Descripción de Carpetas

### 📁 `lib/config/`
**Propósito:** Configuración centralizada del aplicativo

```
lib/config/
├── routes.dart         # Definición de rutas de navegación
├── theme.dart          # Tema global (colores, tipografía)
└── constants.dart      # Constantes de la aplicación
```

**Para qué sirve:**
- Centralizar rutas y evitar hardcoding de strings
- Mantener consistencia visual en toda la app
- Definir valores que se usan en múltiples lugares

---

### 📁 `lib/core/`
**Propósito:** Código compartido y utilidades generales

```
lib/core/
├── domain/
│   ├── entity.dart            # Clase base para entities
│   └── usecase.dart           # Clase base para use cases
├── errors/
│   ├── exceptions.dart        # Excepciones personalizadas
│   └── failures.dart          # Clases de fallo/error
├── network/
│   └── firebase_client.dart   # Cliente Firebase centralizado
└── utils/
    ├── validators.dart        # Validadores (email, teléfono)
    └── helpers.dart           # Funciones auxiliares
```

**Para qué sirve:**
- Reutilizar código entre features
- Centralizar excepciones y errores
- Proporcionar clases base para entities y use cases
- Centralizar conexión a Firebase

---

### 📁 `lib/features/`
**Propósito:** Características principales del aplicativo

Cada feature es **completamente independiente** y contiene su propia lógica de negocio.

```
lib/features/
├── auth/           # Autenticación (login, registro)
├── user/           # Funcionalidades de usuario/pasajero
├── driver/         # Funcionalidades de conductor/chofer
├── admin/          # Panel de administrador
├── routes/         # Gestión de rutas de buses
├── payment/        # Sistema de pagos y wallet
└── shared/         # Código compartido entre features
```

---

## Ejemplo Detallado: Feature Users

### Estructura Completa de `users/`

```
lib/features/user/
├── data/
│   ├── datasources/
│   │   ├── user_local_datasource.dart      # Datos locales
│   │   └── user_remote_datasource.dart     # Datos de Firebase
│   ├── models/
│   │   └── user_model.dart                 # User con serialización
│   └── repositories/
│       └── user_repository_impl.dart       # Implementación del repositorio
│
├── domain/
│   ├── entities/
│   │   └── user_entity.dart                # Modelo de negocio puro
│   ├── repositories/
│   │   └── user_repository.dart            # Interfaz del repositorio
│   └── usecases/
│       ├── get_user_usecase.dart           # Obtener usuario
│       ├── update_user_usecase.dart        # Actualizar usuario
│       └── delete_user_usecase.dart        # Eliminar usuario
│
└── presentation/
    ├── bloc/
    │   ├── user_bloc.dart                  # BLoC principal
    │   ├── user_event.dart                 # Eventos
    │   └── user_state.dart                 # Estados
    ├── pages/
    │   ├── user_profile_page.dart          # Página de perfil
    │   └── edit_user_page.dart             # Página de editar
    └── widgets/
        ├── user_card.dart                  # Widget de usuario
        └── user_form.dart                  # Formulario de usuario
```

---

### 📋 Explicación de Subcarpetas en `user/`

#### **1. `data/` - Capa de Datos**

**`datasources/`**
- `user_remote_datasource.dart`: Conecta con Firebase Firestore
  ```dart
  // Ejemplo: obtener usuario de Firestore
  Future<UserModel> getUserById(String id) async {
    final doc = await firestore.collection('users').doc(id).get();
    return UserModel.fromJson(doc.data());
  }
  ```

- `user_local_datasource.dart`: Almacenamiento local (SQLite, SharedPreferences)
  ```dart
  // Ejemplo: guardar usuario localmente
  Future<void> cacheUser(UserModel user) async {
    // Usar Hive o SQLite
  }
  ```

**`models/`**
- `user_model.dart`: Extiende de `UserEntity` con métodos de serialización
  ```dart
  class UserModel extends UserEntity {
    UserModel({required String id, required String name});
    
    factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(...);
    Map<String, dynamic> toJson() => {...};
  }
  ```

**`repositories/`**
- `user_repository_impl.dart`: Implementación concreta que coordina datasources
  ```dart
  class UserRepositoryImpl implements UserRepository {
    final UserRemoteDatasource remoteDatasource;
    final UserLocalDatasource localDatasource;
    
    @override
    Future<Either<Failure, UserEntity>> getUserById(String id) async {
      try {
        final user = await remoteDatasource.getUserById(id);
        await localDatasource.cacheUser(user);
        return Right(user);
      } catch (e) {
        return Left(Failure());
      }
    }
  }
  ```

#### **2. `domain/` - Capa de Dominio (Lógica de Negocio)**

**`entities/`**
- `user_entity.dart`: Modelo puro de negocio sin dependencias externas
  ```dart
  class UserEntity {
    final String id;
    final String name;
    final String email;
    final String phone;
    
    UserEntity({
      required this.id,
      required this.name,
      required this.email,
      required this.phone,
    });
  }
  ```

**`repositories/`**
- `user_repository.dart`: Interfaz (contrato) que debe cumplir el repositorio
  ```dart
  abstract class UserRepository {
    Future<Either<Failure, UserEntity>> getUserById(String id);
    Future<Either<Failure, UserEntity>> updateUser(UserEntity user);
    Future<Either<Failure, void>> deleteUser(String id);
  }
  ```

**`usecases/`**
- `get_user_usecase.dart`: Lógica de negocio para obtener usuario
  ```dart
  class GetUserUseCase implements UseCase<UserEntity, String> {
    final UserRepository userRepository;
    
    GetUserUseCase(this.userRepository);
    
    @override
    Future<Either<Failure, UserEntity>> call(String id) {
      return userRepository.getUserById(id);
    }
  }
  ```

#### **3. `presentation/` - Capa de Presentación (UI)**

**`bloc/`**
- `user_bloc.dart`: Maneja el estado de usuario
- `user_event.dart`: Eventos que disparan cambios
- `user_state.dart`: Estados que la UI escucha
  ```dart
  // Evento
  class GetUserEvent extends UserEvent {
    final String userId;
    GetUserEvent(this.userId);
  }
  
  // Estado
  class UserLoadingState extends UserState {}
  class UserLoadedState extends UserState {
    final UserEntity user;
    UserLoadedState(this.user);
  }
  
  // BLoC
  class UserBloc extends Bloc<UserEvent, UserState> {
    final GetUserUseCase getUserUseCase;
    
    UserBloc(this.getUserUseCase) : super(UserInitialState()) {
      on<GetUserEvent>((event, emit) async {
        emit(UserLoadingState());
        final result = await getUserUseCase(event.userId);
        result.fold(
          (failure) => emit(UserErrorState()),
          (user) => emit(UserLoadedState(user)),
        );
      });
    }
  }
  ```

**`pages/`**
- `user_profile_page.dart`: Página que muestra el perfil
  ```dart
  class UserProfilePage extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoadedState) {
            return UserCard(user: state.user);
          }
          return LoadingWidget();
        },
      );
    }
  }
  ```

**`widgets/`**
- `user_card.dart`: Widget reutilizable que muestra info del usuario
- `user_form.dart`: Formulario para editar usuario

---

## Flujo de Datos

### Ejemplo: Obtener un Usuario

```
1. UI (Page) dispara evento
   └─> UserProfilePage() emite GetUserEvent('123')

2. BLoC recibe evento y llama UseCase
   └─> UserBloc recibe GetUserEvent
       └─> Llama GetUserUseCase('123')

3. UseCase consulta Repositorio (interface)
   └─> GetUserUseCase llama userRepository.getUserById('123')

4. Repositorio (implementación) elige DataSource
   └─> UserRepositoryImpl decide:
       ├─> Buscar en cache local primero
       └─> Si no existe, traer de Firebase

5. DataSource obtiene los datos
   └─> UserRemoteDatasource.getUserById() → Firebase
       └─> Retorna UserModel

6. Resultado vuelve al BLoC
   └─> UserRepositoryImpl retorna Either<Failure, UserEntity>
       └─> BLoC emite UserLoadedState(user)

7. UI se actualiza automáticamente
   └─> BlocBuilder escucha UserLoadedState
       └─> Renderiza UserCard(user)
```

---

## 🔑 Ventajas de esta Estructura

| Aspecto | Beneficio |
|--------|-----------|
| **Mantenibilidad** | Cambios aislados en una capa no afectan otras |
| **Testing** | Fácil hacer unit tests sin UI o Firebase |
| **Reutilización** | Features independientes pueden reutilizarse |
| **Escalabilidad** | Agregar nuevas features sin modificar existentes |
| **Independencia** | Cambiar Firebase por otra BD sin tocar domain/presentation |
| **Equipo** | Múltiples devs pueden trabajar en features diferentes |

---

## 📌 Reglas Importantes

✅ **DO:**
- Cada feature es independiente
- Domain NO depende de externas (Firebase, Flutter)
- Data implementa interfaces de Domain
- Presentation solo accede a través de BLoC

❌ **DON'T:**
- Importar `package:firebase_core` en domain
- Importar `package:flutter` en domain
- Acceder directamente a DataSources desde Presentation
- Mezclar lógica de negocio con UI

---

## 📂 Estructura Completa del Proyecto

```
mi_ruta/
├── lib/
│   ├── config/
│   │   ├── routes.dart
│   │   ├── theme.dart
│   │   └── constants.dart
│   │
│   ├── core/
│   │   ├── domain/
│   │   │   ├── entity.dart
│   │   │   └── usecase.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   └── firebase_client.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── helpers.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── user/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── driver/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── admin/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── routes/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── payment/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── shared/
│   │       ├── models/
│   │       ├── widgets/
│   │       └── services/
│   │
│   └── main.dart
│
├── android/
├── ios/
├── web/
├── windows/
├── macos/
├── linux/
│
├── pubspec.yaml
├── ARCHITECTURE.md
└── README.md
```

---

**Última actualización:** 4 de mayo de 2026
