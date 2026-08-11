import 'package:equatable/equatable.dart';

class Recharge extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status; // pending, verified, approved, rejected
  final String? proofImageUrl;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  const Recharge({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.proofImageUrl,
    required this.createdAt,
    this.verifiedAt,
  });

  Recharge copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    String? status,
    String? proofImageUrl,
    DateTime? createdAt,
    DateTime? verifiedAt,
  }) {
    return Recharge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    currency,
    status,
    proofImageUrl,
    createdAt,
    verifiedAt,
  ];
}
