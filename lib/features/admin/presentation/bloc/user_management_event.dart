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
