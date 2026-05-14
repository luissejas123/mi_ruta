import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

/// Estados del BLoC de Usuario
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

/// Estado inicial
class UserInitial extends UserState {
  const UserInitial();
}

/// Cargando datos
class UserLoading extends UserState {
  const UserLoading();
}

/// Usuario cargado correctamente
class UserLoaded extends UserState {
  final UserEntity user;

  const UserLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

/// Múltiples usuarios cargados
class UsersLoaded extends UserState {
  final List<UserEntity> users;

  const UsersLoaded({required this.users});

  @override
  List<Object> get props => [users];
}

/// Calificación del usuario cargada
class UserRatingLoaded extends UserState {
  final double rating;

  const UserRatingLoaded({required this.rating});

  @override
  List<Object> get props => [rating];
}

/// Usuario en stream de tiempo real
class UserStreamLoaded extends UserState {
  final UserEntity user;

  const UserStreamLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

/// Operación exitosa (actualización)
class UserOperationSuccess extends UserState {
  final String message;

  const UserOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

/// Error
class UserError extends UserState {
  final String message;

  const UserError({required this.message});

  @override
  List<Object> get props => [message];
}
