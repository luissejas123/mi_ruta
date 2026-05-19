import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletService _walletService;

  WalletBloc({required WalletService walletService})
    : _walletService = walletService,
      super(const WalletInitial()) {
    on<LoadWalletEvent>(_onLoadWallet);
    on<TopUpBalanceEvent>(_onTopUpBalance);
    on<PayTripEvent>(_onPayTrip);
    on<LoadTransactionHistoryEvent>(_onLoadTransactionHistory);
    on<ClearWalletEvent>(_onClearWallet);
  }

  /// Maneja carga de datos de billetera
  Future<void> _onLoadWallet(
    LoadWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    try {
      final wallet = await _walletService.getWallet(event.userId);
      if (wallet == null) {
        emit(const WalletError(message: 'Billetera no encontrada'));
        return;
      }

      // Cargar también el historial
      final transactions = await _walletService.getTransactionHistory(
        event.userId,
      );
      emit(WalletLoaded(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  /// Maneja recarga de saldo
  Future<void> _onTopUpBalance(
    TopUpBalanceEvent event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    final lastWallet = currentState is WalletLoaded
        ? currentState.wallet
        : null;

    emit(
      WalletOperationInProgress(operation: 'topup', currentWallet: lastWallet),
    );

    try {
      await _walletService.topUpBalance(event.userId, event.amount);

      // Recargar billetera
      final updatedWallet = await _walletService.getWallet(event.userId);
      if (updatedWallet == null) {
        emit(const WalletError(message: 'Error al actualizar billetera'));
        return;
      }

      emit(
        WalletOperationSuccess(
          message:
              'Saldo recargado exitosamente: BS. ${event.amount.toStringAsFixed(2)}',
          updatedWallet: updatedWallet,
        ),
      );

      // Recargar datos completos después de un breve delay
      add(LoadWalletEvent(event.userId));
    } catch (e) {
      emit(
        WalletError(
          message: 'Error recargando saldo: $e',
          lastKnownWallet: lastWallet,
        ),
      );
    }
  }

  /// Maneja pago de viaje
  Future<void> _onPayTrip(PayTripEvent event, Emitter<WalletState> emit) async {
    final currentState = state;
    final lastWallet = currentState is WalletLoaded
        ? currentState.wallet
        : null;

    emit(
      WalletOperationInProgress(
        operation: 'payment',
        currentWallet: lastWallet,
      ),
    );

    try {
      await _walletService.payTrip(
        event.userId,
        event.amount,
        routeNumber: event.routeNumber,
        routeName: event.routeName,
      );

      final updatedWallet = await _walletService.getWallet(event.userId);
      if (updatedWallet == null) {
        emit(const WalletError(message: 'Error al actualizar billetera'));
        return;
      }

      emit(
        WalletOperationSuccess(
          message:
              'Pago realizado exitosamente: BS. ${event.amount.toStringAsFixed(2)}',
          updatedWallet: updatedWallet,
        ),
      );

      add(LoadWalletEvent(event.userId));
    } catch (e) {
      emit(
        WalletError(
          message: 'Error realizando pago: $e',
          lastKnownWallet: lastWallet,
        ),
      );
    }
  }

  /// Maneja carga de historial de transacciones
  Future<void> _onLoadTransactionHistory(
    LoadTransactionHistoryEvent event,
    Emitter<WalletState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! WalletLoaded) {
        // Si no hay wallet cargada, cargarla primero
        add(LoadWalletEvent(event.userId));
        return;
      }

      final transactions = await _walletService.getTransactionHistory(
        event.userId,
      );
      emit(
        TransactionHistoryLoaded(
          transactions: transactions,
          wallet: currentState.wallet,
        ),
      );
    } catch (e) {
      emit(WalletError(message: 'Error cargando historial: $e'));
    }
  }

  /// Limpia el estado
  Future<void> _onClearWallet(
    ClearWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletInitial());
  }
}
