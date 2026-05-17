import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

/// Repositorio de Usuario - Contrato de acceso a datos
/// Retorna Either<Failure, Data> para manejo de errores
abstract class UserRepository {
  /// Obtener usuario actual (autenticado)
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Obtener usuario por ID
  Future<Either<Failure, UserEntity>> getUserById(String uid);

  /// Obtener múltiples usuarios por lista de IDs
  Future<Either<Failure, List<UserEntity>>> getUsersByIds(List<String> uids);

  /// Actualizar datos de usuario
  Future<Either<Failure, void>> updateUser(
    String uid,
    Map<String, dynamic> data,
  );

  /// Obtener calificación promedio del usuario
  Future<Either<Failure, double>> getUserRating(String uid);

  /// Stream en tiempo real de datos del usuario
  Stream<Either<Failure, UserEntity>> getUserStream(String uid);
}
