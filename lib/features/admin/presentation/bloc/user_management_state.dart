import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

class UserManagementLoaded extends UserManagementState {
  final List<UserEntity> users;
  final String? activeFilter;
  final String? updatingUid;

  const UserManagementLoaded(this.users, {this.activeFilter, this.updatingUid});

  @override
  List<Object?> get props => [users, activeFilter, updatingUid];
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
