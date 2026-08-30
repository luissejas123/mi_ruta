import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mi_ruta/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AdminUserEntity>>> getUsers() async {
    try {
      final result = await remoteDataSource.getUsers();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminUserEntity>> getUserById(String uid) async {
    try {
      final result = await remoteDataSource.getUserById(uid);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(
    String uid,
    String role,
  ) async {
    try {
      await remoteDataSource.updateUserRole(uid, role);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeUserRole(
    String uid,
    String role,
  ) async {
    try {
      await remoteDataSource.revokeUserRole(uid, role);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetToPlainUser(String uid) async {
    try {
      await remoteDataSource.resetToPlainUser(uid);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAdminPermissions(
    String uid,
    Map<String, bool> permissions,
  ) async {
    try {
      await remoteDataSource.updateAdminPermissions(uid, permissions);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createAdminAccount({
    required String adminEmail,
    required String adminPassword,
    required String fullName,
    required String email,
    required String password,
    String governmentId = '',
    String phoneNumber = '',
  }) async {
    try {
      await remoteDataSource.createAdminAccount(
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        fullName: fullName,
        email: email,
        password: password,
        governmentId: governmentId,
        phoneNumber: phoneNumber,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
