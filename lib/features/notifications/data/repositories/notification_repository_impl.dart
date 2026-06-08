import 'package:dartz/dartz.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:mi_ruta/features/notifications/data/models/notification_model.dart';
import 'package:mi_ruta/features/notifications/domain/entities/notification_entity.dart';
import 'package:mi_ruta/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<NotificationEntity>>> getUserNotifications(
    String uid, {
    int limit = 20,
  }) async {
    try {
      final notifications =
          await remoteDataSource.getUserNotifications(uid, limit: limit);
      return Right(notifications);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error cargando notificaciones: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error marcando notificación como leída: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      await remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error eliminando notificación: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      await remoteDataSource.createNotification(
        NotificationModel(
          id: notification.id,
          userId: notification.userId,
          category: notification.category,
          title: notification.title,
          content: notification.content,
          isRead: notification.isRead,
          createdAt: notification.createdAt,
          deepLinkModule: notification.deepLinkModule,
          actionLabel: notification.actionLabel,
        ),
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error creando notificación: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> initializeUserNotifications(String uid) async {
    try {
      await remoteDataSource.initializeUserNotifications(uid);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: 'Error inicializando notificaciones: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<NotificationEntity>>> subscribeToNotifications(
    String uid,
  ) {
    return remoteDataSource
        .subscribeToNotifications(uid)
        .map((notifications) => Right<Failure, List<NotificationEntity>>(notifications))
        .handleError((error) => Left(ServerFailure(message: 'Error en stream de notificaciones: $error')));
  }
}
