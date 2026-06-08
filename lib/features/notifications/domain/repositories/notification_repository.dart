import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(
    String uid, {
    int limit = 20,
  });

  Future<Either<Failure, void>> markAsRead(String notificationId);

  Future<Either<Failure, void>> deleteNotification(String notificationId);

  Future<Either<Failure, void>> createNotification(
    NotificationEntity notification,
  );

  Future<Either<Failure, void>> initializeUserNotifications(String uid);

  Stream<Either<Failure, List<NotificationEntity>>> subscribeToNotifications(
    String uid,
  );
}
