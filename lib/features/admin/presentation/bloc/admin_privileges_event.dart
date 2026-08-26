import 'package:equatable/equatable.dart';

abstract class AdminPrivilegesEvent extends Equatable {
  const AdminPrivilegesEvent();

  @override
  List<Object?> get props => [];
}

class LoadAdminsEvent extends AdminPrivilegesEvent {
  const LoadAdminsEvent();
}

class LoadAdminPermissionsEvent extends AdminPrivilegesEvent {
  final String uid;

  const LoadAdminPermissionsEvent(this.uid);

  @override
  List<Object?> get props => [uid];
}

class UpdateAdminPermissionsEvent extends AdminPrivilegesEvent {
  final String uid;
  final Map<String, bool> permissions;

  const UpdateAdminPermissionsEvent({
    required this.uid,
    required this.permissions,
  });

  @override
  List<Object?> get props => [uid, permissions];
}

class CreateAdminAccountEvent extends AdminPrivilegesEvent {
  final String adminEmail;
  final String adminPassword;
  final String fullName;
  final String email;
  final String password;
  final String governmentId;
  final String phoneNumber;

  const CreateAdminAccountEvent({
    required this.adminEmail,
    required this.adminPassword,
    required this.fullName,
    required this.email,
    required this.password,
    this.governmentId = '',
    this.phoneNumber = '',
  });

  @override
  List<Object?> get props => [
    adminEmail,
    adminPassword,
    fullName,
    email,
    password,
    governmentId,
    phoneNumber,
  ];
}
