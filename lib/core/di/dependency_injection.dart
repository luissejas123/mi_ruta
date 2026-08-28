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
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_bloc.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_remote_datasource_impl.dart';
import 'package:mi_ruta/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mi_ruta/features/admin/domain/repositories/admin_repository.dart';
import 'package:mi_ruta/features/admin/domain/usecases/admin_usecases.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_route_datasource.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_route_datasource_impl.dart';
import 'package:mi_ruta/features/admin/data/repositories/admin_route_repository_impl.dart';
import 'package:mi_ruta/features/admin/domain/repositories/admin_route_repository.dart';
import 'package:mi_ruta/features/admin/domain/usecases/admin_route_usecases.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_bloc.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource_impl.dart';
import 'package:mi_ruta/features/user/data/datasources/trip_history_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/notification_datasource.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/routes/data/datasources/planned_trip_datasource.dart';
import 'package:mi_ruta/features/routes/domain/services/planned_trip_service.dart';
import 'package:mi_ruta/features/user/data/datasources/wallet_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/recharge_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/benefit_request_datasource.dart';
import 'package:mi_ruta/features/user/data/repositories/user_repository_impl.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/services/trip_history_service.dart';
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
import 'package:mi_ruta/features/routes/data/datasources/gtfs_datasource.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_migration_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_migration_bbox_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/core/local_db/route_local_database.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/domain/repositories/location_repository.dart';
import 'package:mi_ruta/features/user/data/repositories/location_repository_impl.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_location_usecase.dart';
import 'package:mi_ruta/features/user/domain/usecases/reverse_geocode_usecase.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_bloc.dart';
import 'package:mi_ruta/features/driver/data/datasources/vehicle_remote_datasource.dart';
import 'package:mi_ruta/features/driver/data/datasources/vehicle_remote_datasource_impl.dart';
import 'package:mi_ruta/features/driver/data/repositories/vehicle_repository_impl.dart';
import 'package:mi_ruta/features/driver/domain/repositories/vehicle_repository.dart';
import 'package:mi_ruta/features/driver/domain/usecases/vehicle_usecases.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_bloc.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_income_datasource.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_income_service.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_assigned_routes_datasource.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_assigned_routes_service.dart';
import 'package:mi_ruta/features/driver/data/datasources/tickeador_operations_datasource.dart';
import 'package:mi_ruta/features/driver/domain/services/tickeador_operations_service.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_privileges_datasource.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_privileges_service.dart';
import 'package:mi_ruta/features/stops/domain/services/bus_stop_service.dart';
import 'package:mi_ruta/core/connectivity/connectivity_service.dart';
import 'package:mi_ruta/features/user/domain/services/user_preferences_service.dart';

import 'package:mi_ruta/features/user/presentation/bloc/user_preferences_bloc.dart';
import 'package:mi_ruta/features/routes/domain/services/gtfs_schedule_service.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/admin/data/datasources/user_management_datasource.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_service.dart';
import 'package:mi_ruta/features/tickeador/data/datasources/tickeador_datasource.dart';
import 'package:mi_ruta/features/tickeador/data/repositories/tickeador_repository_impl.dart';
import 'package:mi_ruta/features/tickeador/domain/repositories/tickeador_repository.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_bloc.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';





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

  getIt.registerSingleton<ChangePasswordUseCase>(
    ChangePasswordUseCase(getIt<AuthRepository>()),
  );

  // TEMPORAL — modo prueba, ver AuthRepository.loginAsDemo
  getIt.registerSingleton<LoginAsDemoUseCase>(
    LoginAsDemoUseCase(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<ChangePasswordBloc>(
    ChangePasswordBloc(changePasswordUseCase: getIt<ChangePasswordUseCase>()),
  );

  // AUTH FEATURE - PRESENTATION LAYER (BLoC)
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      registerUseCase: getIt<RegisterUseCase>(),
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentAuthUserUseCase>(),
      resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
      loginAsDemoUseCase: getIt<LoginAsDemoUseCase>(),
    ),
  );

  // ============================================
  // ADMIN FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<AdminRemoteDataSource>(
    AdminRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );

  getIt.registerSingleton<AdminRepository>(
    AdminRepositoryImpl(remoteDataSource: getIt<AdminRemoteDataSource>()),
  );

  // Gestion neutral de cuentas (RQ-71/72): aprobacion de choferes y
  // asignacion de tickeador. Lo consumen DriverApprovalBloc y el panel de
  // Presidente.
  getIt.registerSingleton<UserManagementDatasource>(
    UserManagementDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<UserManagementService>(
    UserManagementService(datasource: getIt<UserManagementDatasource>()),
  );

  // ============================================
  // ADMIN FEATURE - DOMAIN LAYER (UseCases)
  // ============================================
  getIt.registerSingleton<GetAdminUsersUseCase>(
    GetAdminUsersUseCase(getIt<AdminRepository>()),
  );

  getIt.registerSingleton<GetAdminUserByIdUseCase>(
    GetAdminUserByIdUseCase(getIt<AdminRepository>()),
  );

  getIt.registerSingleton<UpdateUserRoleUseCase>(
    UpdateUserRoleUseCase(getIt<AdminRepository>()),
  );

  getIt.registerSingleton<UpdateAdminPermissionsUseCase>(
    UpdateAdminPermissionsUseCase(getIt<AdminRepository>()),
  );

  getIt.registerSingleton<CreateAdminAccountUseCase>(
    CreateAdminAccountUseCase(getIt<AdminRepository>()),
  );

  // ============================================
  // ADMIN FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<UserManagementBloc>(
    UserManagementBloc(
      getUsersUseCase: getIt<GetAdminUsersUseCase>(),
      updateUserRoleUseCase: getIt<UpdateUserRoleUseCase>(),
    ),
  );

  getIt.registerSingleton<AdminPrivilegesBloc>(
    AdminPrivilegesBloc(
      getUsersUseCase: getIt<GetAdminUsersUseCase>(),
      getUserByIdUseCase: getIt<GetAdminUserByIdUseCase>(),
      updatePermissionsUseCase: getIt<UpdateAdminPermissionsUseCase>(),
      createAdminAccountUseCase: getIt<CreateAdminAccountUseCase>(),
    ),
  );

  // ============================================
  // USER FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<LocationDatasource>(LocationDatasource());
  getIt.registerSingleton<GeocodingDatasource>(GeocodingDatasource());

  getIt.registerSingleton<LocationRepository>(
    LocationRepositoryImpl(
      locationDatasource: getIt<LocationDatasource>(),
      geocodingDatasource: getIt<GeocodingDatasource>(),
    ),
  );

  getIt.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(remoteDataSource: getIt<UserRemoteDataSource>()),
  );

  // ============================================
  // USER FEATURE - DOMAIN LAYER (UseCases)
  // ============================================
  getIt.registerSingleton<GetCurrentLocationUseCase>(
    GetCurrentLocationUseCase(repository: getIt<LocationRepository>()),
  );

  getIt.registerSingleton<ReverseGeocodeUseCase>(
    ReverseGeocodeUseCase(repository: getIt<LocationRepository>()),
  );

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
  getIt.registerSingleton<MiRutaBloc>(
    MiRutaBloc(
      getCurrentLocationUseCase: getIt<GetCurrentLocationUseCase>(),
      reverseGeocodeUseCase: getIt<ReverseGeocodeUseCase>(),
    ),
  );

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
  getIt.registerSingleton<UserPreferencesService>(UserPreferencesService());
  getIt.registerSingleton<UserPreferencesBloc>(
    UserPreferencesBloc(
      preferencesService: getIt<UserPreferencesService>(),
    ),
  );
  // ============================================
  // TRIP HISTORY FEATURE
  // ============================================
  getIt.registerSingleton<TripHistoryDatasource>(
    TripHistoryDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<TripHistoryService>(
    TripHistoryService(datasource: getIt<TripHistoryDatasource>()),
  );

  // ============================================
  // NOTIFICATIONS FEATURE
  // ============================================
  getIt.registerSingleton<NotificationDatasource>(
    NotificationDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<NotificationService>(
    NotificationService(datasource: getIt<NotificationDatasource>()),
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

  getIt.registerSingleton<RouteMigrationBboxService>(
    RouteMigrationBboxService(datasource: getIt<RouteDatasource>()),
  );

  // ============================================
  // ROUTES FEATURE - LOCAL DB + GTFS + SYNC
  // ============================================
  getIt.registerSingleton<RouteLocalDatabase>(RouteLocalDatabase());

  getIt.registerSingleton<GtfsDatasource>(GtfsDatasource());

  // ============================================
  // ADMIN FEATURE - GESTIÓN DE RUTAS
  // ============================================
  getIt.registerSingleton<AdminRouteDataSource>(
    AdminRouteDataSourceImpl(
      routeDatasource: getIt<RouteDatasource>(),
      gtfsDatasource: getIt<GtfsDatasource>(),
    ),
  );

  getIt.registerSingleton<AdminRouteRepository>(
    AdminRouteRepositoryImpl(remoteDataSource: getIt<AdminRouteDataSource>()),
  );

  getIt.registerSingleton<GetAdminRoutesUseCase>(
    GetAdminRoutesUseCase(getIt<AdminRouteRepository>()),
  );

  getIt.registerSingleton<GetAdminRouteByIdUseCase>(
    GetAdminRouteByIdUseCase(getIt<AdminRouteRepository>()),
  );

  getIt.registerSingleton<CreateAdminRouteUseCase>(
    CreateAdminRouteUseCase(getIt<AdminRouteRepository>()),
  );

  getIt.registerSingleton<UpdateAdminRouteUseCase>(
    UpdateAdminRouteUseCase(getIt<AdminRouteRepository>()),
  );

  getIt.registerSingleton<DeleteAdminRouteUseCase>(
    DeleteAdminRouteUseCase(getIt<AdminRouteRepository>()),
  );

  getIt.registerSingleton<LoadRoutesFromGtfsUseCase>(
    LoadRoutesFromGtfsUseCase(getIt<AdminRouteRepository>()),
  );

  getIt.registerSingleton<RouteManagementBloc>(
    RouteManagementBloc(
      getRoutesUseCase: getIt<GetAdminRoutesUseCase>(),
      createRouteUseCase: getIt<CreateAdminRouteUseCase>(),
      updateRouteUseCase: getIt<UpdateAdminRouteUseCase>(),
      deleteRouteUseCase: getIt<DeleteAdminRouteUseCase>(),
      loadRoutesFromGtfsUseCase: getIt<LoadRoutesFromGtfsUseCase>(),
    ),
  );

  getIt.registerSingleton<RouteDataSyncService>(
    RouteDataSyncService(
      localDb: getIt<RouteLocalDatabase>(),
      gtfsDatasource: getIt<GtfsDatasource>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  // ============================================
  // CONECTIVIDAD - REANUDAR SINCRONIZACIÓN (RQ-57)
  // ============================================
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());

  // ============================================
  // TRIP PLANNER FEATURE
  // ============================================
  getIt.registerSingleton<PlannedTripDatasource>(
    PlannedTripDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<PlannedTripService>(
    PlannedTripService(
      datasource: getIt<PlannedTripDatasource>(),
      syncService: getIt<RouteDataSyncService>(),
    ),
  );

  // ============================================
  // VEHICLE FEATURE (driver + admin) - DATA LAYER
  // ============================================
  getIt.registerSingleton<VehicleRemoteDataSource>(
    VehicleRemoteDataSourceImpl(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<VehicleRepository>(
    VehicleRepositoryImpl(remoteDataSource: getIt<VehicleRemoteDataSource>()),
  );

  // VEHICLE FEATURE - DOMAIN LAYER (UseCases)
  getIt.registerSingleton<GetMyVehicleUseCase>(
    GetMyVehicleUseCase(repository: getIt<VehicleRepository>()),
  );

  getIt.registerSingleton<GetMyVehicleStreamUseCase>(
    GetMyVehicleStreamUseCase(repository: getIt<VehicleRepository>()),
  );

  getIt.registerSingleton<SetVehicleOnDutyUseCase>(
    SetVehicleOnDutyUseCase(repository: getIt<VehicleRepository>()),
  );

  getIt.registerSingleton<GetActiveVehiclesStreamUseCase>(
    GetActiveVehiclesStreamUseCase(repository: getIt<VehicleRepository>()),
  );

  // VEHICLE FEATURE - PRESENTATION LAYER (BLoC)
  getIt.registerFactory<DriverVehicleBloc>(
    () => DriverVehicleBloc(
      getMyVehicleStreamUseCase: getIt<GetMyVehicleStreamUseCase>(),
      setVehicleOnDutyUseCase: getIt<SetVehicleOnDutyUseCase>(),
    ),
  );

  getIt.registerFactory<AdminActiveVehiclesBloc>(
    () => AdminActiveVehiclesBloc(
      getActiveVehiclesStreamUseCase: getIt<GetActiveVehiclesStreamUseCase>(),
      getUsersByIdsUseCase: getIt<GetUsersByIdsUseCase>(),
    ),
  );

  // ============================================
  // DRIVER FEATURE - DATA LAYER (unidades/viajes/cobros)
  // ============================================
  getIt.registerSingleton<DriverDatasource>(
    DriverDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  // ============================================
  // DRIVER FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<DriverService>(
    DriverService(
      datasource: getIt<DriverDatasource>(),
      routeService: getIt<RouteService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  getIt.registerSingleton<DriverAssignedRoutesDatasource>(
    DriverAssignedRoutesDatasource(
      firestore: getIt<FirebaseFirestore>(),
      routeDatasource: getIt<RouteDatasource>(),
    ),
  );
  getIt.registerSingleton<DriverAssignedRoutesService>(
    DriverAssignedRoutesService(
      datasource: getIt<DriverAssignedRoutesDatasource>(),
    ),
  );

  getIt.registerSingleton<DriverIncomeDatasource>(
    DriverIncomeDatasource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<DriverIncomeService>(
    DriverIncomeService(datasource: getIt<DriverIncomeDatasource>()),
  );

  getIt.registerSingleton<TickeadorOperationsDatasource>(
    TickeadorOperationsDatasource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<TickeadorOperationsService>(
    TickeadorOperationsService(
      datasource: getIt<TickeadorOperationsDatasource>(),
    ),
  );

  // ============================================
  // ADMIN FEATURE - Unidades / supervisión (AdminService, RQ-71 a RQ-77)
  // ============================================
  getIt.registerSingleton<AdminService>(
    AdminService(
      userManagementService: getIt<UserManagementService>(),
      driverDatasource: getIt<DriverDatasource>(),
    ),
  );

  // ============================================
  // STOPS FEATURE (paradas cercanas)
  // ============================================
  getIt.registerSingleton<BusStopService>(
    BusStopService(localDb: getIt<RouteLocalDatabase>()),
  );

  // ============================================
  // ROUTES FEATURE - Horarios GTFS (GtfsScheduleService)
  // ============================================
  getIt.registerSingleton<GtfsScheduleService>(
    GtfsScheduleService(getIt<GtfsDatasource>()),
  );

  // ============================================
  // TICKEADOR FEATURE - DATA LAYER
  // ============================================
  getIt.registerSingleton<TickeadorDatasource>(
    TickeadorDatasource(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<TickeadorRepository>(
    TickeadorRepositoryImpl(datasource: getIt<TickeadorDatasource>()),
  );

  // ============================================
  // TICKEADOR FEATURE - DOMAIN LAYER (Services)
  // ============================================
  getIt.registerSingleton<TickeadorService>(
    TickeadorService(
      repository: getIt<TickeadorRepository>(),
      driverDatasource: getIt<DriverDatasource>(),
    ),
  );

  // ============================================
  // TICKEADOR FEATURE - PRESENTATION LAYER (BLoC)
  // ============================================
  getIt.registerSingleton<TickeadorBloc>(
    TickeadorBloc(service: getIt<TickeadorService>()),
  );
}
