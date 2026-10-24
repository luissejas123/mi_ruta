import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

/// Eventos del BLoC de Usuario
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

/// Obtener usuario actual
class GetCurrentUserEvent extends UserEvent {
  const GetCurrentUserEvent();
}

/// Obtener usuario por ID
class GetUserByIdEvent extends UserEvent {
  final String uid;

  const GetUserByIdEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

/// Obtener múltiples usuarios por IDs
class GetUsersByIdsEvent extends UserEvent {
  final List<String> uids;

  const GetUsersByIdsEvent({required this.uids});

  @override
  List<Object> get props => [uids];
}

/// Actualizar usuario
class UpdateUserEvent extends UserEvent {
  final String uid;
  final Map<String, dynamic> data;

  const UpdateUserEvent({required this.uid, required this.data});

  @override
  List<Object> get props => [uid, data];
}

/// Obtener calificación del usuario
class GetUserRatingEvent extends UserEvent {
  final String uid;

  const GetUserRatingEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

/// Iniciar stream en tiempo real
class StartUserStreamEvent extends UserEvent {
  final String uid;

  const StartUserStreamEvent({required this.uid});

  @override
  List<Object> get props => [uid];
}

/// Detener stream
class StopUserStreamEvent extends UserEvent {
  const StopUserStreamEvent();
}

class UserStreamUpdatedEvent extends UserEvent {
  final UserEntity user;

  const UserStreamUpdatedEvent(this.user);

  @override
  List<Object> get props => [user];
}

class UserStreamFailedEvent extends UserEvent {
  final String message;

  const UserStreamFailedEvent(this.message);

  @override
  List<Object> get props => [message];
}
