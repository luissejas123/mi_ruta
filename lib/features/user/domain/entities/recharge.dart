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
  // Nombre del usuario que pidió la recarga — se resuelve aparte (no vive en
  // el doc de `recharges`), solo se usa en listas de revisión del tickeador.
  final String? userName;

  const Recharge({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.proofImageUrl,
    required this.createdAt,
    this.verifiedAt,
    this.userName,
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
    String? userName,
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
      userName: userName ?? this.userName,
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
    userName,
  ];
}
