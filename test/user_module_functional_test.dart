import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';
import 'package:mi_ruta/features/user/domain/usecases/user_usecases.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late UserBloc bloc;

  final sampleUser = UserEntity(
    uid: 'u-123',
    fullName: 'Ana Flores',
    email: 'ana@test.com',
    phoneNumber: '71234567',
    userType: 'passenger',
    profileImageUrl: '',
    rating: 4.8,
    reviewsCount: 12,
    walletBalance: 40.0,
    isActive: true,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 2, 1),
    qaAccess: true,
  );

  setUp(() {
    repository = MockUserRepository();
    bloc = UserBloc(
      getCurrentUserUseCase: GetCurrentUserUseCase(repository: repository),
      getUserByIdUseCase: GetUserByIdUseCase(repository: repository),
      getUsersByIdsUseCase: GetUsersByIdsUseCase(repository: repository),
      updateUserUseCase: UpdateUserUseCase(repository: repository),
      getUserRatingUseCase: GetUserRatingUseCase(repository: repository),
      getUserStreamUseCase: GetUserStreamUseCase(repository: repository),
    );
  });

  tearDown(() => bloc.close());

  test('UserBloc carga usuario por id y emite UserLoaded', () async {
    when(() => repository.getUserById('u-123'))
        .thenAnswer((_) async => Right(sampleUser));

    final states = <UserState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const GetUserByIdEvent(uid: 'u-123'));
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<UserLoading>());
    expect(states.last, isA<UserLoaded>());
    expect((states.last as UserLoaded).user.uid, 'u-123');

    await sub.cancel();
  });

  test('UserBloc emite UserError cuando falla la búsqueda por id', () async {
    when(() => repository.getUserById('missing'))
        .thenAnswer((_) async => Left(ServerFailure(message: 'Usuario no encontrado')));

    final states = <UserState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const GetUserByIdEvent(uid: 'missing'));
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<UserLoading>());
    expect(states.last, isA<UserError>());
    expect((states.last as UserError).message, contains('Usuario no encontrado'));

    await sub.cancel();
  });

  test('UserBloc actualiza usuario y emite UserOperationSuccess', () async {
    when(() => repository.updateUser('u-123', {'fullName': 'Ana Actualizada'}))
        .thenAnswer((_) async => const Right(null));

    final states = <UserState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const UpdateUserEvent(uid: 'u-123', data: {'fullName': 'Ana Actualizada'}));
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<UserLoading>());
    expect(states.last, isA<UserOperationSuccess>());
    expect((states.last as UserOperationSuccess).message, contains('actualizado'));

    await sub.cancel();
  });

  test('UserBloc carga calificación del usuario', () async {
    when(() => repository.getUserRating('u-123'))
        .thenAnswer((_) async => const Right(4.7));

    final states = <UserState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const GetUserRatingEvent(uid: 'u-123'));
    await Future<void>.delayed(Duration.zero);

    expect(states.first, isA<UserLoading>());
    expect(states.last, isA<UserRatingLoaded>());
    expect((states.last as UserRatingLoaded).rating, 4.7);

    await sub.cancel();
  });

  test('UserBloc entrega stream en tiempo real del usuario', () async {
    when(() => repository.getUserStream('u-123'))
        .thenAnswer((_) => Stream.value(Right(sampleUser)));

    final states = <UserState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const StartUserStreamEvent(uid: 'u-123'));
    await Future<void>.delayed(Duration.zero);

    expect(states.any((state) => state is UserStreamLoaded), isTrue);
    await sub.cancel();
  });
}
