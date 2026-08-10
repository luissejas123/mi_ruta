import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String governmentId;
  final String phoneNumber;
  final String? profilePictureUrl;
  final String role;
  final DateTime createdAt;
  final Map<String, dynamic>? wallet;
  final Map<String, dynamic>? settings;
  // Acceso libre a los 5 perfiles para pruebas de QA (ver
  // super_admin_config.dart) — activado/desactivado desde el panel de Admin.
  final bool qaAccess;

  const AuthEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.governmentId,
    required this.phoneNumber,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    this.wallet,
    this.settings,
    this.qaAccess = false,
  });

  @override
  List<Object?> get props => [
    uid,
    fullName,
    email,
    governmentId,
    phoneNumber,
    profilePictureUrl,
    role,
    createdAt,
    wallet,
    settings,
    qaAccess,
  ];
}
