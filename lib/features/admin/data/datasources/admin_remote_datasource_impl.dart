import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:mi_ruta/features/admin/data/models/admin_user_model.dart';

/// Datasource del panel administrativo sobre la colección real `users`.
class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  AdminRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth;

  @override
  Future<List<AdminUserModel>> getUsers() async {
    final snapshot = await _firestore.collection('users').limit(500).get();
    return snapshot.docs
        .map((doc) => AdminUserModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<AdminUserModel> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Usuario no encontrado');
    }
    return AdminUserModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set({'role': role}, SetOptions(merge: true));
  }

  @override
  Future<void> updateAdminPermissions(
    String uid,
    Map<String, bool> permissions,
  ) async {
    // Actualiza solo este campo sin sobrescribir otras preferencias del usuario.
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'settings.admin_permissions': permissions});
  }

  @override
  Future<void> createAdminAccount({
    required String adminEmail,
    required String adminPassword,
    required String fullName,
    required String email,
    required String password,
    String governmentId = '',
    String phoneNumber = '',
  }) async {
    // 1. Crear la cuenta en Firebase Authentication.
    //    Ojo: la sesión del cliente pasa al usuario recién creado.
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // 2. Crear el documento Firestore con el UID real, esquema snake_case
    //    compatible con AuthModel, role = "admin".
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'government_id': governmentId,
      'phone_number': phoneNumber,
      'profile_picture_url': null,
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
      'wallet': {'current_balance': 0.0, 'currency': 'Bs'},
      'settings': {
        'dark_mode_enabled': false,
        'is_driver_mode': false,
        'admin_permissions': {
          'manage_users': false,
          'manage_admins': false,
          'manage_permissions': false,
          'manage_routes': false,
        },
      },
    });

    // 3. Restaurar la sesión del administrador que está operando.
    try {
      await _firebaseAuth.signOut();
      await _firebaseAuth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } catch (e) {
      throw Exception(
        'El administrador fue creado, pero no se pudo restaurar tu sesión '
        '(revisa tu contraseña actual). Vuelve a iniciar sesión.',
      );
    }
  }
}
