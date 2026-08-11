import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/entities/app_notification.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _service;

  NotificationBloc({required NotificationService service})
      : _service = service,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<MarkGiftUsed>(_onMarkGiftUsed);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final items = await _service.getAll(event.userId);
      emit(NotificationLoaded(items));
    } catch (e) {
      emit(NotificationError('Error al cargar notificaciones: $e'));
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _service.markRead(event.userId, event.notifId);
    final current = state;
    if (current is NotificationLoaded) {
      final updated = current.all.map((n) =>
          n.id == event.notifId ? n.copyWith(isRead: true) : n).toList();
      emit(NotificationLoaded(updated));
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    await _service.markAllRead(event.userId);
    final current = state;
    if (current is NotificationLoaded) {
      final updated =
          current.all.map((n) => n.copyWith(isRead: true)).toList();
      emit(NotificationLoaded(updated));
    }
  }

  Future<void> _onMarkGiftUsed(
    MarkGiftUsed event,
    Emitter<NotificationState> emit,
  ) async {
    await _service.markGiftUsed(event.userId, event.notifId);
    final current = state;
    if (current is NotificationLoaded) {
      final updated = current.all.map((n) {
        if (n.id == event.notifId) {
          return AppNotification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            createdAt: n.createdAt,
            discountPercent: n.discountPercent,
            businessName: n.businessName,
            isUsed: true,
            validUntil: n.validUntil,
          );
        }
        return n;
      }).toList();
      emit(NotificationLoaded(updated));
    }
  }
}
