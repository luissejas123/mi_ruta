// RQ-58 — Validación integral del módulo Usuario (Backlog Sprint 3).
// "Ejecutar pruebas funcionales" para el cierre del módulo Usuario.
//
// Cubre, sobre la app real (arranque real, widgets reales, navegación
// real): login -> pantalla principal -> perfil -> billetera -> cierre de
// sesión, y el caso de credenciales inválidas.
//
// Por qué se mockean Auth/User/Wallet/Ubicación en vez de pegarle a
// Firebase real: no existe ninguna cuenta de pasajero de prueba en este
// proyecto (`DevAdminBootstrap`/`DevDriverBootstrap` solo cubren
// admin/chofer — ver AuthRemoteDataSourceImpl.loginAsDemo, que
// explícitamente excluye al pasajero: "el pasajero se prueba con login
// real"). Crear una cuenta real o loguearse contra el proyecto de Firebase
// de producción desde un test automático no es aceptable, así que este
// test reemplaza únicamente los repositorios inyectados por `get_it`
// (Auth/User/Wallet/Ubicación) con dobles de prueba antes de levantar la
// app real — todo lo demás (BLoCs, páginas, navegación, widgets) es 100%
// código de producción sin tocar.
//
// Prerrequisito en el emulador/dispositivo (una sola vez): conceder permiso
// de ubicación para que `Geolocator.getPositionStream` (llamado directo en
// `MiRutaScreen`, fuera de la ubicación mockeada de abajo) no quede
// esperando el diálogo nativo de permisos, que este test no puede resolver:
//   adb shell pm grant <applicationId> android.permission.ACCESS_FINE_LOCATION
//   adb shell pm grant <applicationId> android.permission.ACCESS_COARSE_LOCATION
//
// Cómo correrlo:
//   flutter test integration_test/user_module_test.dart -d <deviceId>
import 'package:dartz/dartz.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/main.dart' show MyApp;

import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';
import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/location_repository.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_location_usecase.dart';
import 'package:mi_ruta/features/user/domain/usecases/reverse_geocode_usecase.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';
import 'package:mi_ruta/features/user/domain/entities/wallet.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/widgets/balance_card.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/profile_header.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockWalletService extends Mock implements WalletService {}

class MockLocationRepository extends Mock implements LocationRepository {}

const _testEmail = 'qa.integracion@miruta.test';
const _testPassword = 'ClaveDePrueba123';
const _testUid = 'qa-integration-user';

final _fakeUser = AuthEntity(
  uid: _testUid,
  fullName: 'QA Integración',
  email: _testEmail,
  governmentId: '0000000',
  phoneNumber: '70000000',
  role: 'user',
  createdAt: DateTime(2024, 1, 1),
);

final _fakeUserEntity = UserEntity(
  uid: _testUid,
  fullName: 'QA Integración',
  email: _testEmail,
  phoneNumber: '70000000',
  userType: 'passenger',
  profileImageUrl: '',
  rating: 4.8,
  reviewsCount: 12,
  walletBalance: 42.5,
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

final _fakeWallet = Wallet(
  userId: _testUid,
  currentBalance: 42.5,
  currency: 'BOB',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

const _cochabambaCoords = LatLng(-17.3895, -66.1568);

/// `pumpAndSettle` nunca termina una vez que la app llega a `MiRutaScreen`:
/// esa pantalla mantiene un `StreamSubscription` de Geolocator vivo y, si el
/// permiso de ubicación no fue concedido, un `CircularProgressIndicator` de
/// animación infinita (ver `_buildMap` en mi_ruta_screen.dart). Ese widget
/// sigue montado (aunque tapado) mientras se navega a Billetera/Perfil, así
/// que de ahí en adelante hay que "asentar" la UI con pumps acotados en vez
/// de esperar a que no queden animaciones corriendo.
Future<void> _settleIgnoringInfiniteAnimations(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final mockAuthRepository = MockAuthRepository();
  final mockUserRepository = MockUserRepository();
  final mockWalletService = MockWalletService();
  final mockLocationRepository = MockLocationRepository();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp();
    setupDependencies();

    // ---- AUTH: reconstruye repo -> usecases -> bloc con el mock ----
    getIt.unregister<AuthRepository>();
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    getIt.unregister<RegisterUseCase>();
    getIt.registerSingleton<RegisterUseCase>(RegisterUseCase(mockAuthRepository));
    getIt.unregister<LoginUseCase>();
    getIt.registerSingleton<LoginUseCase>(LoginUseCase(mockAuthRepository));
    getIt.unregister<LogoutUseCase>();
    getIt.registerSingleton<LogoutUseCase>(LogoutUseCase(mockAuthRepository));
    getIt.unregister<GetCurrentAuthUserUseCase>();
    getIt.registerSingleton<GetCurrentAuthUserUseCase>(
      GetCurrentAuthUserUseCase(mockAuthRepository),
    );
    getIt.unregister<ResetPasswordUseCase>();
    getIt.registerSingleton<ResetPasswordUseCase>(
      ResetPasswordUseCase(mockAuthRepository),
    );
    getIt.unregister<LoginAsDemoUseCase>();
    getIt.registerSingleton<LoginAsDemoUseCase>(
      LoginAsDemoUseCase(mockAuthRepository),
    );
    getIt.unregister<AuthBloc>();
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

    // ---- USER: idem, con UserRepository mockeado ----
    getIt.unregister<UserRepository>();
    getIt.registerSingleton<UserRepository>(mockUserRepository);
    getIt.unregister<GetCurrentUserUseCase>();
    getIt.registerSingleton<GetCurrentUserUseCase>(
      GetCurrentUserUseCase(repository: mockUserRepository),
    );
    getIt.unregister<GetUserByIdUseCase>();
    getIt.registerSingleton<GetUserByIdUseCase>(
      GetUserByIdUseCase(repository: mockUserRepository),
    );
    getIt.unregister<GetUsersByIdsUseCase>();
    getIt.registerSingleton<GetUsersByIdsUseCase>(
      GetUsersByIdsUseCase(repository: mockUserRepository),
    );
    getIt.unregister<UpdateUserUseCase>();
    getIt.registerSingleton<UpdateUserUseCase>(
      UpdateUserUseCase(repository: mockUserRepository),
    );
    getIt.unregister<GetUserRatingUseCase>();
    getIt.registerSingleton<GetUserRatingUseCase>(
      GetUserRatingUseCase(repository: mockUserRepository),
    );
    getIt.unregister<GetUserStreamUseCase>();
    getIt.registerSingleton<GetUserStreamUseCase>(
      GetUserStreamUseCase(repository: mockUserRepository),
    );
    getIt.unregister<UserBloc>();
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

    // ---- WALLET: WalletService es una clase concreta (no interfaz), se
    // mockea directo con mocktail y se reconstruye el bloc con el mock ----
    getIt.unregister<WalletService>();
    getIt.registerSingleton<WalletService>(mockWalletService);
    getIt.unregister<WalletBloc>();
    getIt.registerSingleton<WalletBloc>(
      WalletBloc(walletService: mockWalletService),
    );

    // ---- UBICACIÓN: para que MiRutaScreen muestre el mapa (no el spinner
    // infinito) sin depender de GPS/permiso real dentro del bloc ----
    getIt.unregister<LocationRepository>();
    getIt.registerSingleton<LocationRepository>(mockLocationRepository);
    getIt.unregister<GetCurrentLocationUseCase>();
    getIt.registerSingleton<GetCurrentLocationUseCase>(
      GetCurrentLocationUseCase(repository: mockLocationRepository),
    );
    getIt.unregister<ReverseGeocodeUseCase>();
    getIt.registerSingleton<ReverseGeocodeUseCase>(
      ReverseGeocodeUseCase(repository: mockLocationRepository),
    );
    getIt.unregister<MiRutaBloc>();
    getIt.registerSingleton<MiRutaBloc>(
      MiRutaBloc(
        getCurrentLocationUseCase: getIt<GetCurrentLocationUseCase>(),
        reverseGeocodeUseCase: getIt<ReverseGeocodeUseCase>(),
      ),
    );

    // Estubs por defecto, comunes a todos los tests de este archivo.
    when(() => mockAuthRepository.getCurrentUser()).thenAnswer(
      (_) async => Left(ServerFailure(message: 'No hay sesión activa')),
    );
    when(() => mockAuthRepository.logout()).thenAnswer(
      (_) async => const Right(null),
    );
    when(() => mockLocationRepository.getCurrentLocation()).thenAnswer(
      (_) async => const Right(_cochabambaCoords),
    );
    when(() => mockUserRepository.getUserStream(any())).thenAnswer(
      (_) => Stream.value(Right(_fakeUserEntity)),
    );
    when(() => mockWalletService.getWallet(any())).thenAnswer(
      (_) async => _fakeWallet,
    );
    when(
      () => mockWalletService.getTransactionHistory(
        any(),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  testWidgets(
    'RQ-58: flujo funcional integral del módulo Usuario '
    '(login inválido -> login válido -> inicio -> perfil -> billetera -> '
    'cerrar sesión)',
    (tester) async {
      // `MyApp` solo se pumpea UNA vez en todo este test: `BlocProvider`
      // (con `create:`) cierra los BLoCs singleton de `get_it` cuando su
      // árbol se desmonta, así que un segundo `pumpWidget(MyApp())` en un
      // `testWidgets` separado reutilizaría BLoCs ya cerrados (`StateError`
      // al agregar eventos). Por eso ambos escenarios (login inválido y
      // válido) viven en un único flujo continuo, igual que pasaría en una
      // sesión real de la app.
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => Left(ServerFailure(message: 'Credenciales inválidas')),
      );

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 0) Login con credenciales inválidas: muestra error y no navega.
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), _testEmail);
      await tester.enterText(find.byType(TextField).at(1), _testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Credenciales inválidas'), findsOneWidget);
      expect(find.byType(CustomBottomNav), findsNothing);

      // 1) Reintenta con credenciales válidas, sobre el mismo formulario.
      when(
        () => mockAuthRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(_fakeUser));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));

      // A partir de acá evitamos pumpAndSettle: MiRutaScreen puede quedar
      // con animaciones infinitas corriendo (ver docstring del helper).
      await _settleIgnoringInfiniteAnimations(tester);

      // 2) Pantalla principal del pasajero alcanzada.
      expect(find.byType(CustomBottomNav), findsOneWidget);

      // 3) Navegar a Perfil y verificar los datos del usuario autenticado.
      await tester.tap(find.text('Perfil'));
      await _settleIgnoringInfiniteAnimations(tester);

      final profileHeader = tester.widget<ProfileHeader>(
        find.byType(ProfileHeader),
      );
      expect(profileHeader.name, _fakeUserEntity.fullName);
      expect(profileHeader.email, _fakeUserEntity.email);

      // Perfil/Billetera no tienen botón de volver (`automaticallyImplyLeading:
      // false` a propósito): se navega entre pestañas con el bottom nav, que
      // reemplaza el stack entero (`navigateBottomNav` -> `pushAndRemoveUntil`).
      await tester.tap(find.text('Inicio'));
      await _settleIgnoringInfiniteAnimations(tester);

      // 4) Navegar a Billetera y verificar el saldo mockeado.
      await tester.tap(find.text('Billetera'));
      await _settleIgnoringInfiniteAnimations(tester);

      final balanceCard = tester.widget<BalanceCard>(
        find.byType(BalanceCard),
      );
      expect(balanceCard.balance, _fakeWallet.currentBalance);
      expect(balanceCard.currency, _fakeWallet.currency);

      await tester.tap(find.text('Inicio'));
      await _settleIgnoringInfiniteAnimations(tester);

      // 5) Cerrar sesión desde Perfil vuelve a la pantalla de login.
      await tester.tap(find.text('Perfil'));
      await _settleIgnoringInfiniteAnimations(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await _settleIgnoringInfiniteAnimations(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cerrar sesión'));
      await _settleIgnoringInfiniteAnimations(tester);

      expect(find.text('MiRuta'), findsOneWidget);
      expect(find.byType(CustomBottomNav), findsNothing);
      verify(() => mockAuthRepository.logout()).called(1);
    },
  );
}
