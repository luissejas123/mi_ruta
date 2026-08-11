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
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

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
      final userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final now = DateTime.now().toIso8601String();

      // ✅ Guardamos TODOS los campos que UserModel necesita
      final userData = {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'governmentId': governmentId,
        'phoneNumber': phoneNumber,
        // ✅ role y userType apuntan al mismo valor
        'role': role,
        'userType': role,
        // ✅ Campos requeridos por UserModel
        'profileImageUrl': '',
        'rating': 0.0,
        'reviewsCount': 0,
        'isActive': true,
        'wallet': {
          'balance': 0.0,
          'currency': 'Bs.',
        },
        'createdAt': now,
        'updatedAt': now,
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      final authModel = AuthModel(
        uid: uid,
        email: email,
        fullName: fullName,
        governmentId: governmentId,
        phoneNumber: phoneNumber,
        role: role,
        createdAt: DateTime.now(),
      );

      return authModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeErrorRegistro(e.code));
    } catch (e) {
      throw Exception('Error general: $e');
    }
  }

  @override
  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('No se encontró el perfil del usuario.');
      }

      return AuthModel.fromJson(userDoc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeError(e.code));
    } catch (e) {
      throw Exception('$e');
    }
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
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Error al resetear contraseña: ${e.message}');
    } catch (e) {
      throw Exception('Error general: $e');
    }
  }

  // ✅ Mensajes de error de registro legibles
  String _mensajeErrorRegistro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error al registrarse. Intenta de nuevo.';
    }
  }

  // ✅ Mensajes de error de login legibles
  String _mensajeError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error al iniciar sesión. Intenta de nuevo.';
    }
  }
}