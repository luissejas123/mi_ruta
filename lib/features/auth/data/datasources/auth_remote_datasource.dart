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
}
