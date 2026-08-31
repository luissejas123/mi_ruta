import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';

abstract class AdminRepository {
  /// Lista los usuarios de la colección real `users` de Firestore.
  Future<Either<Failure, List<AdminUserEntity>>> getUsers();

  /// Obtiene un usuario por su UID.
  Future<Either<Failure, AdminUserEntity>> getUserById(String uid);

  /// Actualiza el `role` de un usuario (ej: promover a "admin").
  Future<Either<Failure, void>> updateUserRole(String uid, String role);

  /// Quita [role] de la cuenta (revocar), simétrico a [updateUserRole].
  Future<Either<Failure, void>> revokeUserRole(String uid, String role);

  /// Resetea la cuenta a un 'user' llano sin importar qué roles tenga hoy.
  /// Ver [AdminRemoteDataSource.resetToPlainUser].
  Future<Either<Failure, void>> resetToPlainUser(String uid);

  /// Guarda `admin_permissions` dentro de `settings` sin tocar el resto
  /// de los campos del usuario.
  Future<Either<Failure, void>> updateAdminPermissions(
    String uid,
    Map<String, bool> permissions,
  );

  /// Crea una cuenta de administrador nueva (Auth + documento en `users`).
  Future<Either<Failure, void>> createAdminAccount({
    required String adminEmail,
    required String adminPassword,
    required String fullName,
    required String email,
    required String password,
    String governmentId,
    String phoneNumber,
  });
}
