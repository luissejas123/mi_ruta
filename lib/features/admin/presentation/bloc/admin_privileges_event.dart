import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_privileges.dart';

abstract class AdminPrivilegesEvent extends Equatable {
  const AdminPrivilegesEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminPrivileges extends AdminPrivilegesEvent {
  final String adminId;

  const LoadAdminPrivileges(this.adminId);

  @override
  List<Object?> get props => [adminId];
}

class SaveAdminPrivileges extends AdminPrivilegesEvent {
  final String adminId;
  final AdminPrivileges privileges;

  const SaveAdminPrivileges(this.adminId, this.privileges);

  @override
  List<Object?> get props => [adminId, privileges];
}
