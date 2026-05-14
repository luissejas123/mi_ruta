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
  ];
}
