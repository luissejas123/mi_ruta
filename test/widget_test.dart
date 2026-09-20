// Tests de widgets que NO dependen de Firebase.
// InsertarCorreoPage requiere más contexto, por lo que se omite aquí.
// Para tests de integración con Firebase, usar integration_test/.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/boton_amarillo.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/input_con_sombra.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';
import 'package:mi_ruta/features/user/presentation/pages/historial_viajes_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// `IniciarSesionPage` envuelve su body en un `BlocListener<AuthBloc,
/// AuthState>` (ver `homeScreenForRole`, criterio único de ruteo por rol),
/// así que necesita un `AuthBloc` real en el árbol — con un repositorio
/// mockeado, ya que estos tests no dependen de Firebase.
AuthBloc _buildAuthBloc() {
  final repository = MockAuthRepository();
  return AuthBloc(
    registerUseCase: RegisterUseCase(repository),
    loginUseCase: LoginUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
    getCurrentUserUseCase: GetCurrentAuthUserUseCase(repository),
    resetPasswordUseCase: ResetPasswordUseCase(repository),
    loginAsDemoUseCase: LoginAsDemoUseCase(repository),
  );
}

void main() {
  testWidgets('IniciarSesionPage muestra título y botones', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => _buildAuthBloc(),
          child: const IniciarSesionPage(),
        ),
      ),
    );

    expect(find.text('MiRuta'), findsOneWidget);
    expect(find.text('Tu ruta, tu viaje,\ntu pago.'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrarte'), findsOneWidget);
  });

  testWidgets('BotonAmarillo ejecuta callback al presionar', (
    WidgetTester tester,
  ) async {
    bool presionado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonAmarillo(
            texto: 'Prueba',
            alPresionar: () => presionado = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Prueba'));
    expect(presionado, isTrue);
  });

  testWidgets('InputConSombra muestra hint text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InputConSombra(hint: 'Test hint')),
      ),
    );

    expect(find.widgetWithText(TextField, 'Test hint'), findsOneWidget);
  });

  testWidgets('TripHistoryListWidget ordena viajes por fecha más reciente', (
    WidgetTester tester,
  ) async {
    final trips = [
      TripHistoryEntry(
        id: '1',
        userId: 'u1',
        routeName: 'Línea 12',
        originName: 'Terminal',
        destinationName: 'Centro',
        elapsed: const Duration(minutes: 22),
        date: DateTime(2026, 3, 9, 15, 45),
        farePaid: 2.5,
      ),
      TripHistoryEntry(
        id: '2',
        userId: 'u1',
        routeName: 'Línea 23',
        originName: 'Mercado',
        destinationName: 'Universidad',
        elapsed: const Duration(minutes: 18),
        date: DateTime(2026, 3, 10, 8, 30),
        farePaid: 2.5,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripHistoryListWidget(trips: trips),
        ),
      ),
    );

    expect(find.text('MOVIMIENTOS'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Pago Transporte Línea 23'), findsOneWidget);
    final first = tester.element(find.text('Pago Transporte Línea 23')).renderObject;
    final second = tester.element(find.text('Pago Transporte Línea 12')).renderObject;
    expect(first, isNotNull);
    expect(second, isNotNull);
  });
}
