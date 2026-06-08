import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:mi_ruta/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mi_ruta/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:mi_ruta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource_impl.dart';
import 'package:mi_ruta/features/user/data/repositories/user_repository_impl.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:mi_ruta/features/notifications/data/datasources/notification_remote_datasource_impl.dart';
import 'package:mi_ruta/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:mi_ruta/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mi_ruta/features/notifications/domain/usecases/notification_usecases.dart';

final getIt = GetIt.instance;

/// Configurar todas las dependencias de la aplicación
/// Llamar esta función en main.dart antes de runApp()
void setupDependencies() {
  // ============================================
  // FIRESTORE & EXTERNAL DEPENDENCIES
  // ============================================
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  // ============================================
  // AUTH FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(remoteDataSource: getIt<AuthRemoteDataSource>()),
  );

  // ============================================
  // AUTH FEATURE - DOMAIN LAYER (UseCases)
  // ============================================
  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<LoginUseCase>(LoginUseCase(getIt<AuthRepository>()));

  getIt.registerSingleton<LogoutUseCase>(
    LogoutUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<GetCurrentAuthUserUseCase>(
    GetCurrentAuthUserUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<ResetPasswordUseCase>(
    ResetPasswordUseCase(getIt<AuthRepository>()),
  );

  // ============================================
  // AUTH FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      registerUseCase: getIt<RegisterUseCase>(),
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentAuthUserUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
    ),
  );

  // ============================================
  // USER FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(remoteDataSource: getIt<UserRemoteDataSource>()),
  );

  // ============================================
  // USER FEATURE - DOMAIN LAYER (UseCases)
  // ============================================
  getIt.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(repository: getIt<UserRepository>()),
  );

  getIt.registerSingleton<GetUserByIdUseCase>(
    GetUserByIdUseCase(repository: getIt<UserRepository>()),
  );

  getIt.registerSingleton<GetUsersByIdsUseCase>(
    GetUsersByIdsUseCase(repository: getIt<UserRepository>()),
  );

  getIt.registerSingleton<UpdateUserUseCase>(
    UpdateUserUseCase(repository: getIt<UserRepository>()),
  );

  getIt.registerSingleton<GetUserRatingUseCase>(
    GetUserRatingUseCase(repository: getIt<UserRepository>()),
  );

  getIt.registerSingleton<GetUserStreamUseCase>(
    GetUserStreamUseCase(repository: getIt<UserRepository>()),
  );

  // ============================================
  // NOTIFICATIONS FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<NotificationRemoteDataSource>(
    NotificationRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(
      remoteDataSource: getIt<NotificationRemoteDataSource>(),
    ),
  );

  // ============================================
  // NOTIFICATIONS FEATURE - DOMAIN LAYER (UseCases)
  // ============================================
  getIt.registerSingleton<GetUserNotificationsUseCase>(
    GetUserNotificationsUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerSingleton<SubscribeToNotificationsUseCase>(
    SubscribeToNotificationsUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerSingleton<MarkNotificationAsReadUseCase>(
    MarkNotificationAsReadUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerSingleton<DeleteNotificationUseCase>(
    DeleteNotificationUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerSingleton<CreateNotificationUseCase>(
    CreateNotificationUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerSingleton<InitializeUserNotificationsUseCase>(
    InitializeUserNotificationsUseCase(getIt<NotificationRepository>()),
  );

  // ============================================
  // USER FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<UserBloc>(
    UserBloc(
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      getUserByIdUseCase: getIt<GetUserByIdUseCase>(),
      getUsersByIdsUseCase: getIt<GetUsersByIdsUseCase>(),
      updateUserUseCase: getIt<UpdateUserUseCase>(),
      getUserRatingUseCase: getIt<GetUserRatingUseCase>(),
      getUserStreamUseCase: getIt<GetUserStreamUseCase>(),
    ),
  );
}
