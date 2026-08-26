import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';

abstract class AdminPrivilegesState extends Equatable {
  const AdminPrivilegesState();

  @override
  List<Object?> get props => [];
}

class AdminPrivilegesInitial extends AdminPrivilegesState {
  const AdminPrivilegesInitial();
}

class AdminPrivilegesLoading extends AdminPrivilegesState {
  const AdminPrivilegesLoading();
}

class AdminsLoaded extends AdminPrivilegesState {
  final List<AdminUserEntity> admins;

  const AdminsLoaded(this.admins);

  @override
  List<Object?> get props => [admins];
}

class AdminPermissionsLoaded extends AdminPrivilegesState {
  final AdminUserEntity admin;

  const AdminPermissionsLoaded(this.admin);

  @override
  List<Object?> get props => [admin];
}

/// Estado transitorio para mostrar SnackBar de éxito.
class AdminPrivilegesSuccess extends AdminPrivilegesState {
  final String message;

  const AdminPrivilegesSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminPrivilegesError extends AdminPrivilegesState {
  final String message;

  const AdminPrivilegesError(this.message);

  @override
  List<Object?> get props => [message];
}
