import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// SOLO DESARROLLO — ELIMINAR ANTES DE PRODUCCIÓN
/// ============================================================
///
/// Crea automáticamente (si no existe) la cuenta de administrador de
/// desarrollo en Firebase Authentication + Firestore:
///
///   correo:     admin@miruta.com
///   contraseña: unanoche  (débil a propósito, solo para desarrollo)
///
/// - Solo se ejecuta en modo DEBUG (kDebugMode); en release no hace nada.
/// - Si el documento Firestore ya existe, solo verifica/asegura que
///   role == "admin" (CASO A).
/// - Si la cuenta existe en Auth pero no tiene documento, lo crea con el
///   UID real de Firebase (CASO B).
/// - Si no existe en Auth, crea cuenta y documento (CASO C).
/// - Cualquier inicio de sesión interno se revierte con signOut para no
///   secuestrar la sesión del usuario actual.
///
/// NOTA: firebase_auth 6.x ya no expone fetchSignInMethodsForEmail, por lo
/// que la existencia en Auth se determina intentando iniciar sesión con las
/// credenciales de desarrollo y creando la cuenta si eso falla.
///
/// NO es una puerta trasera de producción: está compilado condicionalmente
/// bajo kDebugMode.
///
/// ⚠️ DESDE EL SPRINT 4 ESTO YA NO FUNCIONA CONTRA UN ENTORNO NUEVO.
/// `firestore.rules` impide que un cliente se escriba `role` a sí mismo, así
/// que la escritura de `role: 'admin'` se deniega y el método falla en
/// silencio (captura el error para no bloquear el arranque). En un entorno
/// donde la cuenta ya es admin sigue funcionando como verificación.
/// Para sembrar un entorno nuevo hay que usar el procedimiento manual de
/// SECURITY.md ("SuperAdmin: cómo se siembra el primero"), que pasa por la
/// consola de Firebase / Admin SDK e ignora las reglas de cliente.
/// Nota: `admin@miruta.com` ya NO es superadmin por su correo — esa allowlist
/// se eliminó; el privilegio total ahora es el campo `is_super_admin`.
class DevAdminBootstrap {
  static const String devAdminEmail = 'admin@miruta.com';
  static const String devAdminPassword = 'unanoche';
  static const String devAdminName = 'Administrador';

  /// Ejecutar tras Firebase.initializeApp(). Nunca lanza: en caso de error
  /// solo registra el problema para no bloquear el arranque.
  static Future<void> ensureDevAdmin() async {
    if (!kDebugMode) return;

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // CASO A: documento Firestore ya existe → asegurar role == "admin".
      final existing = await firestore
          .collection('users')
          .where('email', isEqualTo: devAdminEmail)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        await _ensureRoleAndPermissions(firestore, doc.id, doc.data());
        debugPrint('[DevAdminBootstrap] Admin de desarrollo listo: '
            '$devAdminEmail (role=admin)');
        return;
      }

      // Sin documento. Comprobar si la cuenta existe en Auth iniciando
      // sesión con la contraseña de desarrollo.
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: devAdminEmail,
          password: devAdminPassword,
        );
        // CASO B: existe en Auth pero sin documento → crear con UID real.
        await _ensureDoc(firestore, credential.user!.uid);
        await auth.signOut();
        debugPrint('[DevAdminBootstrap] Documento Firestore creado para '
            '$devAdminEmail');
        return;
      } on FirebaseAuthException {
        // La cuenta no existe (o no coincide la contraseña): crear.
      }

      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: devAdminEmail,
          password: devAdminPassword,
        );
        // CASO C: cuenta nueva creada → documento con su UID real.
        await _ensureDoc(firestore, credential.user!.uid);
        await auth.signOut();
        debugPrint('[DevAdminBootstrap] Cuenta de desarrollo creada: '
            '$devAdminEmail');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint('[DevAdminBootstrap] La cuenta $devAdminEmail ya existe '
              'en Auth con otra contraseña: crea su documento Firestore '
              'manualmente o usa la contraseña de desarrollo.');
        } else {
          debugPrint('[DevAdminBootstrap] Error creando la cuenta: ${e.code}');
        }
      }
    } catch (e) {
      debugPrint('[DevAdminBootstrap] Error: $e');
    }
  }

  static Future<void> _ensureRoleAndPermissions(
    FirebaseFirestore firestore,
    String uid,
    Map<String, dynamic> data,
  ) async {
    final settingsMap = data['settings'] is Map
        ? Map<String, dynamic>.from(data['settings'] as Map)
        : <String, dynamic>{};
    final permissions = settingsMap['admin_permissions'] is Map
        ? Map<String, dynamic>.from(settingsMap['admin_permissions'] as Map)
        : <String, dynamic>{};
    permissions.putIfAbsent('manage_users', () => true);
    permissions.putIfAbsent('manage_admins', () => true);
    permissions.putIfAbsent('manage_permissions', () => true);
    permissions.putIfAbsent('manage_routes', () => true);
    settingsMap['admin_permissions'] = permissions;

    await firestore.collection('users').doc(uid).set({
      'role': 'admin',
      'full_name': data['full_name'] ?? devAdminName,
      'settings': settingsMap,
    }, SetOptions(merge: true));
  }

  static Future<void> _ensureDoc(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final doc = firestore.collection('users').doc(uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    await doc.set({
      'uid': uid,
      'full_name': devAdminName,
      'email': devAdminEmail,
      'government_id': 'ADMIN-DEV',
      'phone_number': '00000000',
      'profile_picture_url': null,
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
      'wallet': {'current_balance': 0.0, 'currency': 'Bs'},
      'settings': {
        'dark_mode_enabled': false,
        'is_driver_mode': false,
        'admin_permissions': {
          'manage_users': true,
          'manage_admins': true,
          'manage_permissions': true,
          'manage_routes': true,
        },
      },
    });
  }
}
