import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:mi_ruta/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mi_ruta/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:mi_ruta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource_impl.dart';
import 'package:mi_ruta/features/user/data/datasources/wallet_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/recharge_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/benefit_request_datasource.dart';
import 'package:mi_ruta/features/user/data/repositories/user_repository_impl.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';
import 'package:mi_ruta/features/user/domain/services/recharge_service.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';
import 'package:mi_ruta/features/user/domain/services/benefit_request_service.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/routes/data/datasources/route_datasource.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_migration_service.dart';

final getIt = GetIt.instance;

/// Configurar todas las dependencias de la aplicación
/// Llamar esta función en main.dart antes de runApp()
void setupDependencies() {
  // ============================================
  // FIRESTORE & EXTERNAL DEPENDENCIES
  // ============================================
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

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

  // ============================================
  // WALLET FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<WalletDatasource>(
    WalletDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  // ============================================
  // WALLET FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<WalletService>(
    WalletService(datasource: getIt<WalletDatasource>()),
  );

  // ============================================
  // WALLET FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<WalletBloc>(
    WalletBloc(walletService: getIt<WalletService>()),
  );

  // ============================================
  // STORAGE SERVICE - DOMAIN LAYER
  // ============================================
  getIt.registerSingleton<StorageService>(
    StorageService(storage: getIt<FirebaseStorage>()),
  );

  // ============================================
  // RECHARGE FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<RecargeDatasource>(
    RecargeDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  // ============================================
  // RECHARGE FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<RechargeService>(
    RechargeService(
      datasource: getIt<RecargeDatasource>(),
      walletService: getIt<WalletService>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // ============================================
  // RECHARGE FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<RechargeBloC>(
    RechargeBloC(rechargeService: getIt<RechargeService>()),
  );

  // ============================================
  // TRIP PAYMENT FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<TripPaymentService>(
    TripPaymentService(firestore: getIt<FirebaseFirestore>()),
  );

  // ============================================
  // TRIP PAYMENT FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<TripPaymentBLoC>(
    TripPaymentBLoC(tripPaymentService: getIt<TripPaymentService>()),
  );

  // ============================================
  // BENEFIT REQUEST FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<BenefitRequestDatasource>(
    BenefitRequestDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  // ============================================
  // BENEFIT REQUEST FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<BenefitRequestService>(
    BenefitRequestService(
      datasource: getIt<BenefitRequestDatasource>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // ============================================
  // BENEFIT REQUEST FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<BenefitRequestBLoC>(
    BenefitRequestBLoC(benefitRequestService: getIt<BenefitRequestService>()),
  );

  // ============================================
  // ROUTES FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<RouteDatasource>(
    RouteDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  // ============================================
  // ROUTES FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<RouteService>(
    RouteService(datasource: getIt<RouteDatasource>()),
  );

  getIt.registerSingleton<RouteMigrationService>(
    RouteMigrationService(datasource: getIt<RouteDatasource>()),
  );
}
