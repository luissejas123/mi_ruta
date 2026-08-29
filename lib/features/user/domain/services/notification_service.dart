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
