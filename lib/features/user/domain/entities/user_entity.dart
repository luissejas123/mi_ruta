import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/driver_request_entity.dart';

/// Entidad de Usuario - Modelo de Negocio Puro (sin dependencias de Firestore)
class UserEntity extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String userType; // 'passenger', 'driver', 'admin'
  final String profileImageUrl;
  final double rating;
  final int reviewsCount;
  final double walletBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Acceso libre a los 5 perfiles para pruebas de QA (campo `qa_access` en
  // users/{uid}) — activado/desactivado desde el panel de Admin.
  final bool qaAccess;
  // Solicitud para ser chofer (`driver_request` en users/{uid}). `null` cuando
  // la cuenta nunca solicitó. El `role` no cambia hasta la aprobación.
  final DriverRequestEntity? driverRequest;

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
    this.qaAccess = false,
    this.driverRequest,
  });

  /// True cuando hay una solicitud de chofer esperando resolución.
  bool get hasPendingDriverRequest => driverRequest?.isPending ?? false;

  @override
  List<Object?> get props => [
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
        qaAccess,
        driverRequest,
      ];
}
