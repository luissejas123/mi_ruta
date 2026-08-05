import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String userId;
  final double currentBalance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.userId,
    required this.currentBalance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  Wallet copyWith({
    String? userId,
    double? currentBalance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      userId: userId ?? this.userId,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    currentBalance,
    currency,
    createdAt,
    updatedAt,
  ];
}
