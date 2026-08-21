import 'package:mi_ruta/features/auth/data/models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> register({
    required String email,
    required String password,
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String role,
  });

  Future<AuthModel> login({required String email, required String password});

  Future<void> logout();

  Future<AuthModel> getCurrentUser();

  Future<void> resetPassword(String email);

  /// TEMPORAL — modo prueba 100% estático: construye un [AuthModel] en
  /// memoria con uid fijo por rol, sin tocar Firebase Auth ni Firestore.
  /// Remover junto con el resto del "Modo prueba" cuando ya no se necesite.
  Future<AuthModel> loginAsDemo({required String role});
}
