import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/wallet.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Cargando datos
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Datos cargados exitosamente
class WalletLoaded extends WalletState {
  final Wallet wallet;
  final List<Map<String, dynamic>> transactions;

  const WalletLoaded({required this.wallet, this.transactions = const []});

  @override
  List<Object?> get props => [wallet, transactions];
}

/// Operación en progreso (recarga, pago)
class WalletOperationInProgress extends WalletState {
  final String operation; // 'topup', 'payment', etc.
  final Wallet? currentWallet;

  const WalletOperationInProgress({
    required this.operation,
    this.currentWallet,
  });

  @override
  List<Object?> get props => [operation, currentWallet];
}

/// Operación completada exitosamente
class WalletOperationSuccess extends WalletState {
  final String message;
  final Wallet updatedWallet;

  const WalletOperationSuccess({
    required this.message,
    required this.updatedWallet,
  });

  @override
  List<Object?> get props => [message, updatedWallet];
}

/// Error al cargar o realizar operación
class WalletError extends WalletState {
  final String message;
  final Wallet? lastKnownWallet;

  const WalletError({required this.message, this.lastKnownWallet});

  @override
  List<Object?> get props => [message, lastKnownWallet];
}

/// Historial de transacciones cargado
class TransactionHistoryLoaded extends WalletState {
  final List<Map<String, dynamic>> transactions;
  final Wallet wallet;

  const TransactionHistoryLoaded({
    required this.transactions,
    required this.wallet,
  });

  @override
  List<Object?> get props => [transactions, wallet];
}
