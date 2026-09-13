import 'package:equatable/equatable.dart';

/// Entidad de Usuario - Modelo de Negocio Puro (sin dependencias de Firestore)
class UserEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  // TODO: este comentario es aspiracional, no está impuesto por el tipo
  // (userType es String libre, no un enum). El valor real que escribe el
  // registro hoy es 'user' (ver register_page.dart), no 'passenger' — el
  // equipo debería revisar y reconciliar esta discrepancia fuera del
  // alcance de RQ-68.
  final String userType; // 'passenger', 'driver', 'admin'
  final String profileImageUrl;
  final double rating;
  final int reviewsCount;
  final double walletBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.profileImageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.walletBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
        uid,
        fullName,
        email,
        phoneNumber,
        userType,
        profileImageUrl,
        rating,
        reviewsCount,
        walletBalance,
        isActive,
        createdAt,
        updatedAt,
      ];
}
