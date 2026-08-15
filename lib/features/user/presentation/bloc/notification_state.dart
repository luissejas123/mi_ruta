import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/app_notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> all;

  const NotificationLoaded(this.all);

  // Las notificaciones operacionales (aviso de parada del chofer) se
  // muestran junto con las de viaje: son avisos del mismo contexto.
  List<AppNotification> get trips => all
      .where((n) =>
          n.type == NotificationType.trip || n.type == NotificationType.operational)
      .toList();

  List<AppNotification> get recharges =>
      all.where((n) => n.type == NotificationType.recharge).toList();

  List<AppNotification> get gifts =>
      all.where((n) => n.type == NotificationType.gift).toList();

  int get unreadCount => all.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [all];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}
