import 'package:mi_ruta/features/admin/data/models/admin_user_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminUserModel>> getUsers();

  Future<AdminUserModel> getUserById(String uid);

  Future<void> updateUserRole(String uid, String role);

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
