import 'package:mi_ruta/features/user/data/models/user_model.dart';

/// DataSource Remoto - Interfaz para acceso a datos de Firestore
abstract class UserRemoteDataSource {
  /// Obtener usuario actual (autenticado)
  Future<UserModel> getCurrentUser();

  /// Obtener usuario por ID
  Future<UserModel> getUserById(String uid);

  /// Obtener múltiples usuarios por lista de IDs
  Future<List<UserModel>> getUsersByIds(List<String> uids);

  /// Actualizar datos de usuario
  Future<void> updateUser(String uid, Map<String, dynamic> data);

  /// Obtener calificación promedio del usuario
  Future<double> getUserRating(String uid);

  /// Stream en tiempo real de datos del usuario
  Stream<UserModel> getUserStream(String uid);
}
