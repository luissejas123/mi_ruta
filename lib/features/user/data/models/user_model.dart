import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

/// Modelo de Usuario - Capa de Data con Serialización JSON
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    required super.userType,
    required super.profileImageUrl,
    required super.rating,
    required super.reviewsCount,
    required super.walletBalance,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.activeBenefits,
  });

  /// Convertir JSON de Firestore a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber:
          (json['phone_number'] ?? json['phoneNumber']) as String? ?? '',
      userType: (json['role'] ?? json['userType']) as String? ?? 'passenger',
      profileImageUrl:
          (json['profile_picture_url'] ?? json['profileImageUrl']) as String? ??
          '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      walletBalance:
          (json['wallet']?['current_balance'] ??
                  json['wallet']?['balance'] as num?)
              ?.toDouble() ??
          0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      activeBenefits: List<String>.from(json['active_benefits'] ?? const []),
    );
  }

  /// Convertir UserModel a JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': userType,
      'profile_picture_url': profileImageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'wallet': {'current_balance': walletBalance},
      'isActive': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'active_benefits': activeBenefits,
    };
  }
}
