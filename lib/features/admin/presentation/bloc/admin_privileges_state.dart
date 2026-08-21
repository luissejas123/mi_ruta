import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_privileges.dart';

abstract class AdminPrivilegesState extends Equatable {
  const AdminPrivilegesState();

  @override
  List<Object?> get props => [];
}

class AdminPrivilegesInitial extends AdminPrivilegesState {}

class AdminPrivilegesLoading extends AdminPrivilegesState {}

class AdminPrivilegesLoaded extends AdminPrivilegesState {
  final AdminPrivileges privileges;

  const AdminPrivilegesLoaded(this.privileges);

  @override
  List<Object?> get props => [privileges];
}

class AdminPrivilegesSaving extends AdminPrivilegesState {
  final AdminPrivileges privileges;

  const AdminPrivilegesSaving(this.privileges);

  @override
  List<Object?> get props => [privileges];
}

class AdminPrivilegesSaved extends AdminPrivilegesState {
  final AdminPrivileges privileges;

  const AdminPrivilegesSaved(this.privileges);

  @override
  List<Object?> get props => [privileges];
}

class AdminPrivilegesError extends AdminPrivilegesState {
  final String message;

  const AdminPrivilegesError(this.message);

  @override
  List<Object?> get props => [message];
}
