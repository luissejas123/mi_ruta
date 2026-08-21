import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';

/// UseCase para obtener usuario actual
class GetCurrentUserUseCase {
  final UserRepository repository;

  GetCurrentUserUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getCurrentUser();
  }
}

/// UseCase para obtener usuario por ID
class GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call(String uid) async {
    return await repository.getUserById(uid);
  }
}

/// UseCase para obtener múltiples usuarios por IDs
class GetUsersByIdsUseCase {
  final UserRepository repository;

  GetUsersByIdsUseCase({required this.repository});

  Future<Either<Failure, List<UserEntity>>> call(List<String> uids) async {
    return await repository.getUsersByIds(uids);
  }
}

/// UseCase para actualizar usuario
class UpdateUserUseCase {
  final UserRepository repository;

  UpdateUserUseCase({required this.repository});

  Future<Either<Failure, void>> call(
    String uid,
    Map<String, dynamic> data,
  ) async {
    return await repository.updateUser(uid, data);
  }
}

/// UseCase para obtener calificación del usuario
class GetUserRatingUseCase {
  final UserRepository repository;

  GetUserRatingUseCase({required this.repository});

  Future<Either<Failure, double>> call(String uid) async {
    return await repository.getUserRating(uid);
  }
}

/// UseCase para stream en tiempo real
class GetUserStreamUseCase {
  final UserRepository repository;

  GetUserStreamUseCase({required this.repository});

  Stream<Either<Failure, UserEntity>> call(String uid) {
    return repository.getUserStream(uid);
  }
}
