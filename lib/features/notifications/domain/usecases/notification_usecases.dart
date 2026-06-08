import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/notifications/domain/entities/notification_entity.dart';
import 'package:mi_ruta/features/notifications/domain/repositories/notification_repository.dart';

class GetUserNotificationsUseCase {
  final NotificationRepository repository;

  GetUserNotificationsUseCase(this.repository);

  Future<Either<Failure, List<NotificationEntity>>> call(
    String uid, {
    int limit = 20,
  }) async {
    return await repository.getUserNotifications(uid, limit: limit);
  }
}

class SubscribeToNotificationsUseCase {
  final NotificationRepository repository;

  SubscribeToNotificationsUseCase(this.repository);

  Stream<Either<Failure, List<NotificationEntity>>> call(String uid) {
    return repository.subscribeToNotifications(uid);
  }
}

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String notificationId) async {
    return await repository.markAsRead(notificationId);
  }
}

class DeleteNotificationUseCase {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call(String notificationId) async {
    return await repository.deleteNotification(notificationId);
  }
}

class CreateNotificationUseCase {
  final NotificationRepository repository;

  CreateNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call(
    NotificationEntity notification,
  ) async {
    return await repository.createNotification(notification);
  }
}

class InitializeUserNotificationsUseCase {
  final NotificationRepository repository;

  InitializeUserNotificationsUseCase(this.repository);

  Future<Either<Failure, void>> call(String uid) async {
    return await repository.initializeUserNotifications(uid);
  }
}
