import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource_impl.dart';
import 'package:mi_ruta/features/user/data/repositories/user_repository_impl.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';

final getIt = GetIt.instance;

/// Configurar todas las dependencias de la aplicación
/// Llamar esta función en main.dart antes de runApp()
void setupDependencies() {
  // ============================================
  // FIRESTORE & EXTERNAL DEPENDENCIES
  // ============================================
  getIt.registerSingleton<FirebaseFirestore>(
    FirebaseFirestore.instance,
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
