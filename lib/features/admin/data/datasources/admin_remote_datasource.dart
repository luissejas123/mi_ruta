import 'package:mi_ruta/features/admin/data/models/admin_user_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminUserModel>> getUsers();

  Future<AdminUserModel> getUserById(String uid);

  Future<void> updateUserRole(String uid, String role);

  /// Quita [role] de la cuenta (ej: revocar admin y volverla 'user' llano),
  /// simétrico a [updateUserRole]. Nunca deja la cuenta sin ningún rol —
  /// si queda vacía, cae de vuelta a 'user'.
  Future<void> revokeUserRole(String uid, String role);

  /// Resetea la cuenta a un 'user' llano sin importar qué roles tenga hoy
  /// (a diferencia de [revokeUserRole], que quita un rol puntual y solo
  /// funciona si la combinación resultante ya es válida). Pensado para
  /// "Quitar privilegios de administrador": protege contra estados
  /// inválidos escritos a mano en Firestore (ej. admin + presidente a la
  /// vez, algo que la app nunca otorga por sí sola).
  Future<void> resetToPlainUser(String uid);

  Future<void> updateAdminPermissions(
    String uid,
    Map<String, bool> permissions,
  );

  /// Crea una cuenta de administrador nueva en Firebase Authentication y
  /// su documento en la colección `users` (role = "admin").
  ///
  /// IMPORTANTE: createUserWithEmailAndPassword cambia la sesión al usuario
  /// recién creado; por eso se recibe [adminEmail]/[adminPassword] para
  /// restaurar la sesión del administrador que está operando.
  Future<void> createAdminAccount({
    required String adminEmail,
    required String adminPassword,
    required String fullName,
    required String email,
    required String password,
    String governmentId,
    String phoneNumber,
  });
}
