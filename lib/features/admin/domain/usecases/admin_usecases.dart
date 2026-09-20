import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mi_ruta/features/admin/domain/repositories/admin_repository.dart';

class GetAdminUsersUseCase {
  final AdminRepository repository;

  GetAdminUsersUseCase(this.repository);

  Future<Either<Failure, List<AdminUserEntity>>> call() async {
    return await repository.getUsers();
  }
}

class GetAdminUserByIdUseCase {
  final AdminRepository repository;

  GetAdminUserByIdUseCase(this.repository);

  Future<Either<Failure, AdminUserEntity>> call(String uid) async {
    return await repository.getUserById(uid);
  }
}

class UpdateUserRoleUseCase {
  final AdminRepository repository;

  UpdateUserRoleUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required String role,
  }) async {
    return await repository.updateUserRole(uid, role);
  }
}

class RevokeUserRoleUseCase {
  final AdminRepository repository;

  RevokeUserRoleUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required String role,
  }) async {
    return await repository.revokeUserRole(uid, role);
  }
}

class ResetToPlainUserUseCase {
  final AdminRepository repository;

  ResetToPlainUserUseCase(this.repository);

  Future<Either<Failure, void>> call({required String uid}) async {
    return await repository.resetToPlainUser(uid);
  }
}

class UpdateAdminPermissionsUseCase {
  final AdminRepository repository;

  UpdateAdminPermissionsUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String uid,
    required Map<String, bool> permissions,
  }) async {
    return await repository.updateAdminPermissions(uid, permissions);
  }
}

class CreateAdminAccountUseCase {
  final AdminRepository repository;

  CreateAdminAccountUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String adminEmail,
    required String adminPassword,
    required String fullName,
    required String email,
    required String password,
    String governmentId = '',
    String phoneNumber = '',
  }) async {
    return await repository.createAdminAccount(
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      fullName: fullName,
      email: email,
      password: password,
      governmentId: governmentId,
      phoneNumber: phoneNumber,
    );
  }
}
