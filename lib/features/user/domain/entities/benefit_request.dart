import 'package:equatable/equatable.dart';

class BenefitRequest extends Equatable {
  final String id;
  final String userId;
  final String benefitType; // 'student', 'university', 'senior'
  final String status; // 'pending', 'approved', 'rejected'
  final List<String> documentUrls; // URLs de documentos subidos
  final String description;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? adminNotes;

  const BenefitRequest({
    required this.id,
    required this.userId,
    required this.benefitType,
    required this.status,
    required this.documentUrls,
    required this.description,
    required this.createdAt,
    this.approvedAt,
    this.adminNotes,
  });

  BenefitRequest copyWith({
    String? id,
    String? userId,
    String? benefitType,
    String? status,
    List<String>? documentUrls,
    String? description,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? adminNotes,
  }) {
    return BenefitRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      benefitType: benefitType ?? this.benefitType,
      status: status ?? this.status,
      documentUrls: documentUrls ?? this.documentUrls,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    benefitType,
    status,
    documentUrls,
    description,
    createdAt,
    approvedAt,
    adminNotes,
  ];
}
