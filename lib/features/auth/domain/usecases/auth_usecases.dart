import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';
import 'package:mi_ruta/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, AuthEntity>> call({
    required String email,
    required String password,
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String role,
  }) async {
    return await repository.register(
      email: email,
      password: password,
      fullName: fullName,
      governmentId: governmentId,
      phoneNumber: phoneNumber,
      role: role,
    );
  }
}

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, AuthEntity>> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(email: email, password: password);
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}

class GetCurrentAuthUserUseCase {
  final AuthRepository repository;

  GetCurrentAuthUserUseCase(this.repository);

  Future<Either<Failure, AuthEntity>> call() async {
    return await repository.getCurrentUser();
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    return await repository.resetPassword(email);
  }
}
