import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  final String uid;

  const LoadNotificationsEvent({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class MarkNotificationReadEvent extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationReadEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class DeleteNotificationEvent extends NotificationsEvent {
  final String notificationId;

  const DeleteNotificationEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}
