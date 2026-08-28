import 'package:equatable/equatable.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserManagementEvent {
  const LoadUsersEvent();
}

class SearchUsersEvent extends UserManagementEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class PromoteUserToAdminEvent extends UserManagementEvent {
  final String uid;

  const PromoteUserToAdminEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}

/// Promueve una cuenta al rol `presidente` (dirigente de linea).
/// Solo lo dispara un `admin`: un Presidente no otorga Presidente.
class PromoteUserToPresidenteEvent extends UserManagementEvent {
  final String uid;

  const PromoteUserToPresidenteEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}
