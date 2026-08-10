import 'package:equatable/equatable.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Carga usuarios; [userTypeFilter] nulo trae todos los roles.
class LoadManagedUsers extends UserManagementEvent {
  final String? userTypeFilter;

  const LoadManagedUsers({this.userTypeFilter});

  @override
  List<Object?> get props => [userTypeFilter];
}

class SetManagedUserActiveState extends UserManagementEvent {
  final String uid;
  final bool isActive;

  const SetManagedUserActiveState(this.uid, this.isActive);

  @override
  List<Object?> get props => [uid, isActive];
}

/// Activa/desactiva el acceso libre a los 5 perfiles para una cuenta de
/// prueba de QA (ver super_admin_config.dart).
class SetManagedUserQaAccess extends UserManagementEvent {
  final String uid;
  final bool qaAccess;

  const SetManagedUserQaAccess(this.uid, this.qaAccess);

  @override
  List<Object?> get props => [uid, qaAccess];
}
