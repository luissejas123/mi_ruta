import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:mi_ruta/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:mi_ruta/features/notifications/presentation/bloc/notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetUserNotificationsUseCase getUserNotificationsUseCase;
  final SubscribeToNotificationsUseCase subscribeToNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;

  NotificationsBloc({
    required this.getUserNotificationsUseCase,
    required this.subscribeToNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.deleteNotificationUseCase,
  }) : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    final result = await getUserNotificationsUseCase(event.uid, limit: 12);

    await result.fold(
      (failure) async {
        emit(NotificationsError(message: failure.message));
      },
      (_) async {
        await emit.forEach(
          subscribeToNotificationsUseCase(event.uid),
          onData: (either) => either.fold(
            (failure) => NotificationsError(message: failure.message),
            (notifications) => NotificationsLoaded(notifications: notifications),
          ),
          onError: (_, _) => const NotificationsError(
            message: 'Error al cargar notificaciones en tiempo real.',
          ),
        );
      },
    );
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final previousState = state;
    final result = await markNotificationAsReadUseCase(event.notificationId);
    result.fold(
      (failure) {
        emit(NotificationsError(message: failure.message));
        emit(previousState);
      },
      (_) {},
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final previousState = state;
    final result = await deleteNotificationUseCase(event.notificationId);
    result.fold(
      (failure) {
        emit(NotificationsError(message: failure.message));
        emit(previousState);
      },
      (_) {},
    );
  }
}
