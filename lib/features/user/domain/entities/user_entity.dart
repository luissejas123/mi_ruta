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
  final List<String> activeBenefits;
  // Solicitud para ser chofer (`driver_request` en users/{uid}). `null` cuando
  // la cuenta nunca solicitó. El `role` no cambia hasta la aprobación.
  final DriverRequestEntity? driverRequest;
  // Rol "activo" por defecto (mismo campo que `AuthEntity.role`). Ver `roles`
  // para el conjunto completo — una cuenta puede tener varios a la vez.
  final String role;
  // Todos los roles simultáneos de la cuenta (siempre incluye 'user'). Ver
  // RoleHierarchy para las combinaciones válidas.
  final List<String> roles;

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
    this.activeBenefits = const [],
    this.driverRequest,
    this.role = 'user',
    this.roles = const ['user'],
  });

  /// True cuando hay una solicitud de chofer esperando resolución.
  bool get hasPendingDriverRequest => driverRequest?.isPending ?? false;

  bool get isAdmin => roles.contains('admin');

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
    activeBenefits,
    driverRequest,
    role,
    roles,
  ];
}
