import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
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
  Future<AuthModel> loginAsDemo({required String role}) async {
    // 100% estático — sin Firebase Auth, sin Firestore. Uid fijo por rol.
    final uid = switch (role) {
      'driver' => kStaticDemoDriverUid,
      'admin' => kStaticDemoAdminUid,
      _ => kStaticDemoPassengerUid,
    };
    return AuthModel(
      uid: uid,
      email: '',
      fullName: 'Demo (${_demoRoleLabel(role)})',
      governmentId: '',
      phoneNumber: '',
      role: role,
      createdAt: DateTime.now(),
    );
  }

  String _demoRoleLabel(String role) {
    switch (role) {
      case 'driver':
        return 'Chofer';
      case 'admin':
        return 'Admin';
      default:
        return 'Pasajero';
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }
      // Firebase exige una sesión reciente para updatePassword.
      // Reautenticamos con la contraseña actual antes de actualizar.
      if (user.email != null && currentPassword.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mensajeErrorContrasena(e.code));
    } catch (e) {
      throw Exception('Error al cambiar la contraseña: $e');
    }
  }

  // ✅ Mensajes de error de cambio de contraseña legibles
  String _mensajeErrorContrasena(String code) {
    switch (code) {
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión antes de cambiar tu contraseña.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'invalid-credential':
      case 'wrong-password':
        return 'La contraseña actual es incorrecta.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error al cambiar la contraseña. Intenta de nuevo.';
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
    switch (code.toLowerCase()) {
      case 'user-not-found':
        return 'No existe una cuenta registrada con ese correo.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      // Firebase Auth con "email enumeration protection" activada (opción por
      // defecto en proyectos nuevos) devuelve este código tanto si el correo
      // no existe como si la contraseña está mal — no se puede distinguir
      // desde el cliente sin filtrar qué correos están registrados. Para
      // volver a tener el detalle, desactivar esa protección en la consola:
      // Authentication → Settings → User account protection.
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'El correo o la contraseña son incorrectos.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
  }
}