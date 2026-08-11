import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';
import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String email,
    required String password,
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        governmentId: governmentId,
        phoneNumber: phoneNumber,
        role: role,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      final result = await remoteDataSource.getCurrentUser();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
