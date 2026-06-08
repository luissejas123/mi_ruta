import 'package:mi_ruta/features/notifications/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getUserNotifications(
    String uid, {
    int limit = 20,
  });

  Stream<List<NotificationModel>> subscribeToNotifications(String uid);

  Future<void> markAsRead(String notificationId);

  Future<void> deleteNotification(String notificationId);

  Future<void> createNotification(NotificationModel notification);

  Future<void> initializeUserNotifications(String uid);
}
