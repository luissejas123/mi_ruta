import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

class UserManagementLoaded extends UserManagementState {
  final List<AdminUserEntity> users;
  final String query;

  const UserManagementLoaded({required this.users, this.query = ''});

  /// Filtro local por nombre, correo, teléfono o UID.
  List<AdminUserEntity> get filteredUsers {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phoneNumber.toLowerCase().contains(q) ||
            u.uid.toLowerCase().contains(q))
        .toList();
  }

  @override
  List<Object?> get props => [users, query];
}

/// Estado transitorio para mostrar SnackBar de éxito y luego volver a
/// [UserManagementLoaded] con los datos refrescados.
class UserManagementSuccess extends UserManagementState {
  final String message;

  const UserManagementSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
