import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_ruta/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mi_ruta/features/auth/data/models/auth_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  /// Verifica si un email ya existe en Firestore
  /// Retorna true si el email ya está registrado
  Future<bool> _emailAlreadyExists(String email) async {
    try {
      final result = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      // Si hay error al verificar, retornamos false para permitir que Firebase Auth maneje el error
      return false;
    }
  }

  @override
  Future<AuthModel> register({
    required String email,
    required String password,
    required String fullName,
    required String governmentId,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      // Verificar si el email ya existe
      if (await _emailAlreadyExists(email)) {
        throw Exception('email-already-in-use');
      }

      // Crear usuario en Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Crear documento de usuario en Firestore
      final authModel = AuthModel(
        uid: uid,
        email: email.toLowerCase(),
        fullName: fullName,
        governmentId: governmentId,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(authModel.toJson(), SetOptions(merge: true));

      return authModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw _handleGenericError(e);
    }
  }

  @override
  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('No se encontró el perfil del usuario.');
      }

      return AuthModel.fromJson(userDoc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw _handleGenericError(e);
    }
  }

  /// Maneja errores específicos de Firebase Auth
  Exception _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception(
          'La contraseña es débil. Debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas y números.',
        );
      case 'email-already-in-use':
        return Exception('Este correo electrónico ya está registrado.');
      case 'invalid-email':
        return Exception('El correo electrónico no tiene un formato válido.');
      case 'operation-not-allowed':
        return Exception('Las cuentas con correo/contraseña no están habilitadas.');
      case 'user-disabled':
        return Exception('Esta cuenta ha sido deshabilitada.');
      case 'user-not-found':
        return Exception('No existe una cuenta con ese correo.');
      case 'wrong-password':
        return Exception('La contraseña es incorrecta.');
      case 'invalid-credential':
        return Exception('Las credenciales son inválidas.');
      case 'too-many-requests':
        return Exception('Demasiados intentos fallidos. Intenta de nuevo más tarde.');
      case 'network-request-failed':
        return Exception('Error de conexión. Verifica tu internet.');
      case 'account-exists-with-different-credential':
        return Exception('Ya existe una cuenta con este correo.');
      default:
        return Exception('Error en autenticación: ${e.message}');
    }
  }

  /// Maneja errores genéricos
  Exception _handleGenericError(dynamic error) {
    if (error is Exception && error.toString().contains('email-already-in-use')) {
      return Exception('Este correo electrónico ya está registrado.');
    }
    return Exception('Error al procesar tu solicitud: ${error.toString()}');
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<AuthModel> getCurrentUser() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en Firestore');
      }

      return AuthModel.fromJson(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw Exception('Error al resetear contraseña: ${e.message}');
    } catch (e) {
      throw Exception('Error general: $e');
    }
  }
}
