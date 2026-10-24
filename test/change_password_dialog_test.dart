// Tests del diálogo de cambio de contraseña.
// No dependen de Firebase.

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';
import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_state.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/change_password_dialog.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String email,
    required String password,
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String role,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AuthEntity>> loginAsDemo({required String role}) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    throw UnimplementedError();
  }
}

void main() {
  late ChangePasswordBloc bloc;

  setUp(() {
    bloc = ChangePasswordBloc(
      changePasswordUseCase: ChangePasswordUseCase(_FakeAuthRepository()),
    );
  });

  test('el BLoC emite éxito tras el usecase', () async {
    bloc.add(const ChangePasswordEventSubmit(
      currentPassword: 'vieja123',
      newPassword: 'nueva123',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state, isA<ChangePasswordSuccess>());
  });

  testWidgets('El diálogo se abre y muestra sus campos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: const ChangePasswordDialog(),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Contraseña actual'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Validación: contraseñas no coinciden muestra error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: const ChangePasswordDialog(),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Contraseña actual'),
      'claveVieja1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nueva contraseña'),
      'abc123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirmar contraseña'),
      'abc124',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardar con datos válidos cierra el diálogo con éxito',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: const ChangePasswordDialog(),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Contraseña actual'),
      'claveVieja1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nueva contraseña'),
      'nueva123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirmar contraseña'),
      'nueva123',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump(); // frame de Loading
    // Completa el usecase en async real (los microtasks no se vacían solos en FakeAsync)
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
