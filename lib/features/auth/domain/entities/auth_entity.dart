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

  Map<String, dynamic> get effectiveSettings => {
    'notifications_enabled': true,
    'trip_notifications_enabled': true,
    'recharge_notifications_enabled': true,
    'gift_notifications_enabled': true,
    ...?settings,
  };

  bool notificationPreferenceEnabled(String type) {
    final normalizedType = type.trim().toLowerCase();
    final values = effectiveSettings;

    switch (normalizedType) {
      case 'trip':
      case 'viaje':
        return values['trip_notifications_enabled'] is bool
            ? values['trip_notifications_enabled'] as bool
            : true;
      case 'recharge':
      case 'recarga':
        return values['recharge_notifications_enabled'] is bool
            ? values['recharge_notifications_enabled'] as bool
            : true;
      case 'gift':
      case 'regalo':
        return values['gift_notifications_enabled'] is bool
            ? values['gift_notifications_enabled'] as bool
            : true;
      case 'all':
        return true;
      default:
        return true;
    }
  }

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
