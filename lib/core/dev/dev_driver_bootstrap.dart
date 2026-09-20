import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mi_ruta/features/auth/data/models/auth_model.dart';

/// ============================================================
/// SOLO DESARROLLO — ELIMINAR ANTES DE PRODUCCIÓN
/// ============================================================
///
/// Crea automáticamente (si no existe) la cuenta de chofer de
/// desarrollo en Firebase Authentication + Firestore:
///
///   correo:     chofer@miruta.com
///   contraseña: unanoche  (débil a propósito, solo para desarrollo)
///   nombre:     Chofer Prueba
///   rol:        driver
///
/// - Solo se ejecuta en modo DEBUG (kDebugMode); en release no hace nada.
/// - Usa el modelo real AuthModel (toJson) para crear el documento en la
///   colección `users` existente.
/// - CASO A: documento Firestore ya existe → asegura role == "driver".
/// - CASO B: cuenta en Auth sin documento → crea documento con el UID real.
/// - CASO C: no existe en Auth → crea cuenta y documento.
/// - Cualquier inicio de sesión interno se revierte con signOut para no
///   secuestrar la sesión del usuario actual.
///
/// NO es una puerta trasera de producción: está compilado condicionalmente
/// bajo kDebugMode.
class DevDriverBootstrap {
  static const String devDriverEmail = 'chofer@miruta.com';
  static const String devDriverPassword = 'unanoche';
  static const String devDriverName = 'Chofer Prueba';

  /// Ejecutar tras Firebase.initializeApp(). Nunca lanza: en caso de error
  /// solo registra el problema para no bloquear el arranque.
  static Future<void> ensureDevDriver() async {
    if (!kDebugMode) return;

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // CASO A: documento Firestore ya existe → asegurar role == "driver".
      final existing = await firestore
          .collection('users')
          .where('email', isEqualTo: devDriverEmail)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        await firestore.collection('users').doc(doc.id).set({
          'role': 'driver',
          'full_name': devDriverName,
        }, SetOptions(merge: true));
        debugPrint('[DevDriverBootstrap] Chofer de desarrollo listo: '
            '$devDriverEmail (role=driver)');
        return;
      }

      // Sin documento. Comprobar si la cuenta existe en Auth iniciando
      // sesión con la contraseña de desarrollo.
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: devDriverEmail,
          password: devDriverPassword,
        );
        // CASO B: existe en Auth pero sin documento → crear con UID real.
        await _ensureDoc(firestore, credential.user!.uid);
        await auth.signOut();
        debugPrint('[DevDriverBootstrap] Documento Firestore creado para '
            '$devDriverEmail');
        return;
      } on FirebaseAuthException {
        // La cuenta no existe (o no coincide la contraseña): crear.
      }

      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: devDriverEmail,
          password: devDriverPassword,
        );
        // CASO C: cuenta nueva creada → documento con su UID real.
        await _ensureDoc(firestore, credential.user!.uid);
        await auth.signOut();
        debugPrint('[DevDriverBootstrap] Cuenta de chofer creada: '
            '$devDriverEmail');
      } on FirebaseAuthException catch (e) {
        debugPrint('[DevDriverBootstrap] Error creando la cuenta: ${e.code}');
      }
    } catch (e) {
      debugPrint('[DevDriverBootstrap] Error: $e');
    }
  }

  static Future<void> _ensureDoc(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final doc = firestore.collection('users').doc(uid);
    final snapshot = await doc.get();
    if (snapshot.exists) return;

    final model = AuthModel(
      uid: uid,
      fullName: devDriverName,
      email: devDriverEmail,
      governmentId: 'DRIVER-DEV',
      phoneNumber: '00000001',
      profilePictureUrl: null,
      role: 'driver',
      createdAt: DateTime.now(),
      wallet: {'current_balance': 0.0, 'currency': 'Bs'},
      settings: {'dark_mode_enabled': false, 'is_driver_mode': true},
    );
    await doc.set(model.toJson());
  }
}
