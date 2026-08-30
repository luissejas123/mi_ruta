import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_ruta/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:mi_ruta/features/admin/data/models/admin_user_model.dart';
import 'package:mi_ruta/features/admin/domain/entities/role_hierarchy.dart';

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

  /// Otorga [role] sin perder los roles que la cuenta ya tenía — **no**
  /// sobrescribe `role` a secas, porque eso le borraba `driver`/`tickeador`
  /// a cualquiera que promovieran a admin/presidente. Valida contra
  /// [RoleHierarchy] antes de escribir: si la combinación resultante no está
  /// permitida, lanza (el repositorio lo convierte en `Left(Failure)`).
  @override
  Future<void> updateUserRole(String uid, String role) async {
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final currentRoles = _rolesOf(data);

    if (!RoleHierarchy.canGrant(currentRoles, role)) {
      throw Exception(
        'No se puede otorgar "$role": la cuenta ya tiene ${currentRoles.join(", ")} '
        'y esa combinación no está permitida.',
      );
    }

    final newRoles = {...currentRoles, RoleHierarchy.user, role};
    await ref.set({
      'roles': newRoles.toList(),
      'role': RoleHierarchy.primaryRole(newRoles),
    }, SetOptions(merge: true));
  }

  /// Quita [role] de la cuenta (revocar admin/presidente, ej. "volver a
  /// usuario"). Simétrico a [updateUserRole]. Si al quitarlo no queda ningún
  /// rol operativo, la cuenta cae de vuelta a un 'user' llano — nunca se
  /// escribe un array de roles vacío.
  @override
  Future<void> revokeUserRole(String uid, String role) async {
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final currentRoles = _rolesOf(data);

    final newRoles = currentRoles.where((r) => r != role).toSet();
    if (newRoles.isEmpty) newRoles.add(RoleHierarchy.user);

    if (!RoleHierarchy.isValidRoleSet(newRoles)) {
      throw Exception(
        'No se puede quitar "$role": la combinación resultante '
        '(${newRoles.join(", ")}) no es válida.',
      );
    }

    await ref.set({
      'roles': newRoles.toList(),
      'role': RoleHierarchy.primaryRole(newRoles),
    }, SetOptions(merge: true));
  }

  /// Resetea la cuenta a un 'user' llano sin importar qué tenga hoy en
  /// `roles` — a diferencia de [revokeUserRole] (que quita un rol puntual),
  /// esto no depende de que la combinación actual sea válida. Pensado para
  /// "Quitar privilegios de administrador": si la cuenta llegó a tener una
  /// combinación inválida (ej. admin + presidente a la vez, escrita a mano
  /// desde la consola de Firebase, algo que la app nunca permite otorgar),
  /// revokeUserRole(uid, 'admin') dejaría 'presidente' colgado. Esto no.
  @override
  Future<void> resetToPlainUser(String uid) async {
    final ref = _firestore.collection('users').doc(uid);
    await ref.set({
      'roles': [RoleHierarchy.user],
      'role': RoleHierarchy.user,
    }, SetOptions(merge: true));
  }

  /// Roles actuales de un doc de `users`, con fallback al esquema legado
  /// (un solo `role`/`userType`) para cuentas creadas antes de `roles`.
  Set<String> _rolesOf(Map<String, dynamic> data) {
    final raw = data['roles'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((r) => r.toString()).toSet();
    }
    final legacy = (data['role'] ?? data['userType']) as String? ?? RoleHierarchy.user;
    return {legacy};
  }

  @override
  Future<void> updateAdminPermissions(
    String uid,
    Map<String, bool> permissions,
  ) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};

    // Conservar settings existentes (dark_mode_enabled, is_driver_mode, ...)
    // y actualizar únicamente admin_permissions.
    final currentSettings = data['settings'];
    final settings = currentSettings is Map
        ? Map<String, dynamic>.from(currentSettings)
        : <String, dynamic>{};
    settings['admin_permissions'] = permissions;

    await _firestore
        .collection('users')
        .doc(uid)
        .set({'settings': settings}, SetOptions(merge: true));
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
