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
  final DateTime? decisionAt;
  final String? decisionBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userType;

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
    this.decisionAt,
    this.decisionBy,
    this.rejectedAt,
    this.rejectedBy,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userType,
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
    DateTime? decisionAt,
    String? decisionBy,
    DateTime? rejectedAt,
    String? rejectedBy,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userType,
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
      decisionAt: decisionAt ?? this.decisionAt,
      decisionBy: decisionBy ?? this.decisionBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userType: userType ?? this.userType,
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
    decisionAt,
    decisionBy,
    rejectedAt,
    rejectedBy,
    userName,
    userEmail,
    userPhone,
    userType,
  ];
}
