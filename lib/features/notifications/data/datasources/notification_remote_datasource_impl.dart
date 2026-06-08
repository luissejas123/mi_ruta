import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:mi_ruta/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  NotificationRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  @override
  Future<List<NotificationModel>> getUserNotifications(
    String uid, {
    int limit = 20,
  }) async {
    final query = _notificationsCollection
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit);

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      await _createDefaultNotificationsForUser(uid);
      final fallback = await query.get();
      return fallback.docs
          .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
          .toList();
    }

    return snapshot.docs
        .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  @override
  Stream<List<NotificationModel>> subscribeToNotifications(String uid) {
    return _notificationsCollection
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({
      'is_read': true,
    });
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    await _notificationsCollection.doc().set(notification.toJson());
  }

  @override
  Future<void> initializeUserNotifications(String uid) async {
    await _createDefaultNotificationsForUser(uid);
  }

  Future<void> _createDefaultNotificationsForUser(String uid) async {
    final now = DateTime.now();
    Timestamp createdAt(int minutes) => Timestamp.fromDate(now.subtract(Duration(minutes: minutes)));

    final defaultNotifications = [
      {
        'user_id': uid,
        'category': 'system',
        'title': 'Registro completado',
        'content': 'Ocurre cuando el registro de usuario es finalizado. El botón redirige a la página principal.',
        'is_read': false,
        'created_at': createdAt(1),
        'deep_link_module': 'module_routes',
        'action_label': 'Ir al inicio',
      },
      {
        'user_id': uid,
        'category': 'system',
        'title': 'Pestaña de carga',
        'content': 'Aparece cuando la conexión a internet es deficiente o la carga de nuevas pestañas demora más de lo esperado.',
        'is_read': false,
        'created_at': createdAt(2),
      },
      {
        'user_id': uid,
        'category': 'wallet',
        'title': 'Abonaste saldo de manera exitosa!',
        'content': 'Esta notificación se muestra cuando la recarga por QR o similar fue realizada con éxito.',
        'is_read': false,
        'created_at': createdAt(3),
      },
      {
        'user_id': uid,
        'category': 'wallet',
        'title': 'Pago exitoso!',
        'content': 'Esta notificación salta cuando el pago de pasaje mediante QR se realiza sin ningún problema.',
        'is_read': false,
        'created_at': createdAt(4),
      },
      {
        'user_id': uid,
        'category': 'system',
        'title': 'Carnet subido exitosamente',
        'content': 'Carnet subido exitosamente + Documento válido: esta notificación aparece cuando el carnet fue subido con éxito y el documento ha sido verificado.',
        'is_read': false,
        'created_at': createdAt(5),
      },
      {
        'user_id': uid,
        'category': 'system',
        'title': 'Servicio activo',
        'content': 'Esta alerta aparece cuando una línea previamente en suspensión vuelve a operar.',
        'is_read': false,
        'created_at': createdAt(6),
      },
      {
        'user_id': uid,
        'category': 'system',
        'title': 'Servicio suspendido',
        'content': 'Esta alerta aparece cuando una línea activa suspende sus servicios.',
        'is_read': false,
        'created_at': createdAt(7),
      },
      {
        'user_id': uid,
        'category': 'driver',
        'title': 'Anunciaste tu parada al micro',
        'content': 'Esta alerta se muestra después de presionar el botón de bajar o similar.',
        'is_read': false,
        'created_at': createdAt(8),
        'deep_link_module': 'module_payment',
        'action_label': 'Pagar',
      },
      {
        'user_id': uid,
        'category': 'system',
        'title': 'Completaste tu viaje',
        'content': 'Esta notificación aparece al completar tu viaje, con botón de calificar.',
        'is_read': false,
        'created_at': createdAt(9),
        'action_label': 'Calificar',
      },
      {
        'user_id': uid,
        'category': 'gift',
        'title': 'Recibiste un descuento especial',
        'content': 'Al pulsar el icono de regalo mostrar la alerta “Recibiste un descuento en un negocio local”.',
        'is_read': false,
        'created_at': createdAt(10),
        'action_label': 'Ver descuento',
      },
      {
        'user_id': uid,
        'category': 'wallet',
        'title': 'Saldo bajo',
        'content': 'Aparece cuando el saldo es menor al monto recomendado.',
        'is_read': false,
        'created_at': createdAt(11),
        'action_label': 'Recargar',
      },
      {
        'user_id': uid,
        'category': 'ia_prediction',
        'title': 'Parece que hubo un cambio de ruta',
        'content': 'Aparece cuando la ruta varía respecto a la primera ruta sugerida.',
        'is_read': false,
        'created_at': createdAt(12),
      },
    ];

    final batch = _firestore.batch();
    for (final notification in defaultNotifications) {
      final docRef = _notificationsCollection.doc();
      batch.set(docRef, notification);
    }
    await batch.commit();
  }
}
