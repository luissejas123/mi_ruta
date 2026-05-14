import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/data/datasources/user_remote_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';
import 'package:mi_ruta/features/user/domain/repositories/user_repository.dart';

/// Implementación de UserRepository - Manejo de errores y delegación a DataSource
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserById(String uid) async {
    try {
      final user = await remoteDataSource.getUserById(uid);
      return Right(user);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error obteniendo usuario: $uid'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsersByIds(
    List<String> uids,
  ) async {
    try {
      final users = await remoteDataSource.getUsersByIds(uids);
      return Right(users);
    } on Exception catch (e) {
      return Left(
        ServerFailure(message: 'Error obteniendo múltiples usuarios'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await remoteDataSource.updateUser(uid, data);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error actualizando usuario'));
    }
  }

  @override
  Future<Either<Failure, double>> getUserRating(String uid) async {
    try {
      final rating = await remoteDataSource.getUserRating(uid);
      return Right(rating);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error obteniendo calificación'));
    }
  }

  @override
  Stream<Either<Failure, UserEntity>> getUserStream(String uid) {
    return remoteDataSource
        .getUserStream(uid)
        .map((user) => Right<Failure, UserEntity>(user))
        .handleError(
          (error) => Left<Failure, UserEntity>(
            ServerFailure(message: 'Error en stream de usuario'),
          ),
        );
  }
}
