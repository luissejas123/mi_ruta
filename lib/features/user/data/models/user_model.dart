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
  });

  /// Convertir JSON de Firestore a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      userType: json['userType'] as String? ?? 'passenger',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      walletBalance: (json['wallet']?['balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convertir UserModel a JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'wallet': {
        'balance': walletBalance,
      },
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
