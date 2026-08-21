import 'package:equatable/equatable.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar datos de la billetera
class LoadWalletEvent extends WalletEvent {
  final String userId;

  const LoadWalletEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Recargar saldo
class TopUpBalanceEvent extends WalletEvent {
  final String userId;
  final double amount;

  const TopUpBalanceEvent({required this.userId, required this.amount});

  @override
  List<Object?> get props => [userId, amount];
}

/// Pagar viaje
class PayTripEvent extends WalletEvent {
  final String userId;
  final double amount;
  final String routeNumber;
  final String routeName;

  const PayTripEvent({
    required this.userId,
    required this.amount,
    required this.routeNumber,
    required this.routeName,
  });

  @override
  List<Object?> get props => [userId, amount, routeNumber, routeName];
}

/// Cargar historial de transacciones
class LoadTransactionHistoryEvent extends WalletEvent {
  final String userId;

  const LoadTransactionHistoryEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Limpiar estado
class ClearWalletEvent extends WalletEvent {
  const ClearWalletEvent();
}
