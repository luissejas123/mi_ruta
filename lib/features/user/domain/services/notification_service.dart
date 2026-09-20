import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/data/datasources/notification_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/app_notification.dart';

class NotificationService {
  final NotificationDatasource _datasource;
  final FirebaseFirestore _firestore;
  final _rng = Random();

  NotificationService({
    required NotificationDatasource datasource,
    FirebaseFirestore? firestore,
  }) : _datasource = datasource,
       _firestore = firestore ?? FirebaseFirestore.instance;

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<bool> _isNotificationEnabled(String userId, String type) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final settings = userDoc.data()?['settings'] as Map<String, dynamic>?;
      final effectiveSettings = {
        'trip_notifications_enabled': true,
        'recharge_notifications_enabled': true,
        'gift_notifications_enabled': true,
        ...?settings,
      };

      switch (type) {
        case 'trip':
          return effectiveSettings['trip_notifications_enabled'] as bool? ??
              true;
        case 'recharge':
          return effectiveSettings['recharge_notifications_enabled'] as bool? ??
              true;
        case 'gift':
          return effectiveSettings['gift_notifications_enabled'] as bool? ??
              true;
        default:
          return true;
      }
    } catch (_) {
      return true;
    }
  }

  Future<void> saveTripNotification(String userId, String routeName) async {
    if (!await _isNotificationEnabled(userId, 'trip')) return;

    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: userId,
        type: NotificationType.trip,
        title: 'Viaje finalizado',
        body: 'Finalizaste un viaje en $routeName',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Se manda cuando el tickeador ya verificó el comprobante y el saldo
  /// quedó realmente acreditado — no al enviar la solicitud (ver
  /// [saveRechargeSubmittedNotification] para eso). docs/
  /// PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 0: antes esto se mandaba al
  /// enviar el comprobante, prometiendo un saldo que todavía no existía.
  Future<void> saveRechargeNotification(String userId, double amount) async {
    if (!await _isNotificationEnabled(userId, 'recharge')) return;

    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: userId,
        type: NotificationType.recharge,
        title: 'Recarga exitosa',
        body: 'Recargaste Bs. ${amount.toStringAsFixed(2)} a tu billetera',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Se manda al enviar el comprobante — todavía no hay saldo acreditado,
  /// solo confirma que la solicitud llegó y está pendiente de revisión.
  Future<void> saveRechargeSubmittedNotification(
    String userId,
    double amount,
  ) async {
    if (!await _isNotificationEnabled(userId, 'recharge')) return;

    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: userId,
        type: NotificationType.recharge,
        title: 'Comprobante recibido',
        body: 'Tu comprobante de Bs. ${amount.toStringAsFixed(2)} está en '
            'revisión. Te avisaremos cuando se acredite a tu billetera.',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Se manda si el tickeador rechaza el comprobante (monto ilegible, no
  /// corresponde, etc.) — el pasajero necesita saber que no se acreditará.
  Future<void> saveRechargeRejectedNotification(
    String userId,
    double amount,
  ) async {
    if (!await _isNotificationEnabled(userId, 'recharge')) return;

    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: userId,
        type: NotificationType.recharge,
        title: 'Recarga rechazada',
        body: 'Tu comprobante de Bs. ${amount.toStringAsFixed(2)} fue '
            'rechazado. Verifica el comprobante e intenta de nuevo.',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Saves a gift notification. Returns the discount percent assigned.
  Future<int> saveGiftNotification(String userId) async {
    if (!await _isNotificationEnabled(userId, 'gift')) return 0;

    final discount = _datasource.randomDiscount();
    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: userId,
        type: NotificationType.gift,
        title: '¡Recibiste un regalo!',
        body: 'Obtuviste un descuento de $discount% en un negocio local',
        isRead: false,
        createdAt: DateTime.now(),
        discountPercent: discount,
        businessName: 'un negocio local',
        isUsed: false,
        validUntil: DateTime.now().add(const Duration(days: 7)),
      ),
    );
    return discount;
  }

  /// Returns true with 60% probability — used to simulate gift drops.
  bool shouldGiveGift() => _rng.nextDouble() < 0.6;

  /// Aviso operacional del chofer (p.ej. proximidad a una parada) a un
  /// pasajero que ya está a bordo (RQ-66).
  Future<void> saveOperationalNotification(
    String userId,
    String title,
    String body,
  ) async {
    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: userId,
        type: NotificationType.operational,
        title: title,
        body: body,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// El pasajero avisa que baja y elige pagar con QR (segunda opción de
  /// "Aviso de bajada", `RutaNavegacionPage._payViaQr`) — le llega al
  /// chofer con el `tripId` del abordaje ya conectado, así el chofer no
  /// arma un cobro nuevo (que crearía un segundo `trips` desconectado):
  /// solo muestra el QR que ya trae el monto y el viaje correctos.
  Future<void> saveDropOffPaymentRequestNotification(
    String driverId, {
    required String tripId,
    required double amount,
    required String passengerName,
    required String routeName,
  }) async {
    await _datasource.save(
      AppNotification(
        id: _id(),
        userId: driverId,
        type: NotificationType.operational,
        title: 'Pasajero pagando por QR',
        body: '$passengerName avisó que baja en $routeName y va a pagar '
            'Bs. ${amount.toStringAsFixed(2)} escaneando tu QR.',
        isRead: false,
        createdAt: DateTime.now(),
        relatedTripId: tripId,
        relatedAmount: amount,
      ),
    );
  }

  Future<List<AppNotification>> getAll(String userId) =>
      _datasource.getAll(userId);

  Future<int> getUnreadCount(String userId) =>
      _datasource.getUnreadCount(userId);

  Future<void> markRead(String userId, String notifId) =>
      _datasource.markRead(userId, notifId);

  Future<void> markAllRead(String userId) => _datasource.markAllRead(userId);

  Future<void> deleteNotification(String userId, String notifId) =>
      _datasource.delete(userId, notifId);

  Future<void> markGiftUsed(String userId, String notifId) =>
      _datasource.markGiftUsed(userId, notifId);
}
