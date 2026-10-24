import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;
  const LoadNotifications(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MarkNotificationRead extends NotificationEvent {
  final String userId;
  final String notifId;
  const MarkNotificationRead(this.userId, this.notifId);
  @override
  List<Object?> get props => [userId, notifId];
}

class MarkAllNotificationsRead extends NotificationEvent {
  final String userId;
  const MarkAllNotificationsRead(this.userId);
  @override
  List<Object?> get props => [userId];
}

class DeleteNotification extends NotificationEvent {
  final String userId;
  final String notifId;
  const DeleteNotification(this.userId, this.notifId);
  @override
  List<Object?> get props => [userId, notifId];
}

class MarkGiftUsed extends NotificationEvent {
  final String userId;
  final String notifId;
  const MarkGiftUsed(this.userId, this.notifId);
  @override
  List<Object?> get props => [userId, notifId];
}
