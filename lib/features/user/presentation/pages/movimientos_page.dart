import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/movement_entity.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/period_filter_button.dart';
import 'package:mi_ruta/features/user/presentation/widgets/transaction_card.dart';

/// "MOVIMIENTOS" del pasajero: el ledger REAL de la billetera (colección
/// `transactions` — recargas, pagos de viaje, reembolsos).
///
/// Implementa Obs 4 (modelo único de movimientos con tipo, monto, línea, ruta,
/// viaje_id, fecha, y conciliación de saldo con el historial), además de permitir
/// al pasajero cancelar un viaje elegible y recibir el reembolso inmediato.
class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  static const _filterOptions = ['Hoy', 'Semanal', 'Mensual', 'Todos'];
  static const _amarillo = Color(0xFFFFC12F);

  String _selectedFilter = 'Todos';
  late String _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthLoaded ? authState.user.uid : '';
    _load();
  }

  void _load() {
    if (_userId.isEmpty) return;
    context.read<WalletBloc>().add(LoadWalletEvent(_userId));
  }

  void _selectFilter(String filter) {
    setState(() => _selectedFilter = filter);
  }

  List<MovementEntity> _extractTransactionsFromState(WalletState state) {
    if (state is WalletLoaded) return state.transactions;
    if (state is TransactionHistoryLoaded) return state.transactions;
    return [];
  }

  List<MovementEntity> _filterTransactions(List<MovementEntity> transactions) {
    if (_selectedFilter == 'Todos') return transactions;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return transactions.where((m) {
      final day = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);

      switch (_selectedFilter) {
        case 'Hoy':
          return day.isAtSameMomentAs(today);
        case 'Semanal':
          final weekAgo = today.subtract(const Duration(days: 7));
          return day.isAfter(weekAgo) || day.isAtSameMomentAs(weekAgo);
        case 'Mensual':
          return m.fecha.year == now.year && m.fecha.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _confirmRefund(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text(
          '¿Seguro que deseas cancelar este viaje? '
          'El monto pagado volverá a tu saldo y quedará registrado como un '
          'reembolso en tus movimientos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<TripPaymentBLoC>().add(
      RefundTripEvent(userId: _userId, tripId: tripId),
    );
  }

  Future<void> _openDetail(MovementEntity movement) async {
    final tripId = movement.viajeId;
    final isTrip = movement.tipo == MovementType.pagoViaje;

    var refundable = false;
    if (isTrip && tripId != null && tripId.isNotEmpty) {
      refundable = await getIt<TripPaymentService>().isTripRefundable(
        userId: _userId,
        tripId: tripId,
      );
    }

    if (!mounted) return;
    final colors = AppColors.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movement.tipoLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(movement.descripcion),
            if (movement.linea != null && movement.linea!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Línea: ${movement.linea}${movement.ruta != null ? ' • Ruta: ${movement.ruta}' : ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
            if (movement.viajeId != null) ...[
              const SizedBox(height: 4),
              Text(
                'ID de viaje: ${movement.viajeId}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${movement.isIncome ? '+' : '-'} Bs. ${movement.monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: movement.isIncome ? colors.success : colors.textPrimary,
              ),
            ),
            if (refundable) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.undo),
                  label: const Text('Cancelar viaje y reembolsar'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _confirmRefund(tripId!);
                  },
                ),
              ),
            ] else if (isTrip) ...[
              const SizedBox(height: 16),
              Text(
                'Este viaje ya no se puede cancelar.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC12F), Color(0xFFE6A800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SALDO ACTUAL',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner que valida si el saldo cuadra con el historial (Obs 4)
  Widget _buildReconciliationBanner(WalletState state) {
    final double? currentBalance = state is WalletLoaded
        ? state.wallet.currentBalance
        : state is TransactionHistoryLoaded
        ? state.wallet.currentBalance
        : null;

    final double? calculatedBalance = state is WalletLoaded
        ? state.calculatedBalance
        : state is TransactionHistoryLoaded
        ? state.calculatedBalance
        : null;

    final bool isReconciled = state is WalletLoaded
        ? state.isBalanceReconciled
        : state is TransactionHistoryLoaded
        ? state.isBalanceReconciled
        : true;

    if (currentBalance == null || calculatedBalance == null) {
      return const SizedBox.shrink();
    }
    // El historial se carga con un límite de 50 movimientos: con más, la
    // suma no incluye todo y el "no cuadra" sería falso.
    final loadedCount = state is WalletLoaded
        ? state.transactions.length
        : state is TransactionHistoryLoaded
        ? state.transactions.length
        : 0;
    if (loadedCount >= 50) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final tone = isReconciled ? colors.success : colors.warning;

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isReconciled ? Icons.check_circle : Icons.info_outline,
            size: 20,
            color: tone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isReconciled
                  ? 'Saldo conciliado: Bs. ${currentBalance.toStringAsFixed(2)} cuadra con el historial'
                  : 'Saldo en cuenta: Bs. ${currentBalance.toStringAsFixed(2)} (Calculado según movimientos: Bs. ${calculatedBalance.toStringAsFixed(2)})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          return PeriodFilterButton(
            label: filter,
            isSelected: _selectedFilter == filter,
            onTap: () => _selectFilter(filter),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(MovementEntity movement) {
    String subtitle;
    if (movement.linea != null && movement.linea!.isNotEmpty) {
      subtitle = 'Línea ${movement.linea}';
      if (movement.ruta != null && movement.ruta!.isNotEmpty) {
        subtitle = '$subtitle • ${movement.ruta}';
      }
    } else {
      subtitle = movement.tipoLabel;
    }

    final colors = AppColors.of(context);
    final color = movement.isIncome ? colors.success : colors.danger;

    return InkWell(
      onTap: () => _openDetail(movement),
      borderRadius: BorderRadius.circular(12),
      child: TransactionCard(
        icon: movement.isIncome
            ? (movement.tipo == MovementType.reembolso
                  ? Icons.undo
                  : Icons.add_card)
            : Icons.directions_bus_filled_outlined,
        title: movement.descripcion,
        subtitle: subtitle,
        amount: movement.formattedSignedAmount,
        date: movement.fecha,
        iconBackgroundColor: color.withValues(alpha: 0.14),
        iconColor: color,
        amountColor: color,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: _amarillo),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'Todos'
                ? 'Todavía no tienes movimientos'
                : 'No hay movimientos en este período',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripPaymentBLoC, TripPaymentState>(
      listenWhen: (_, state) =>
          state is TripRefundSuccess || state is TripPaymentError,
      listener: (context, state) {
        if (state is TripRefundSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          _load();
        } else if (state is TripPaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        context.read<TripPaymentBLoC>().add(const ClearPaymentEvent());
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'MOVIMIENTOS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  final balance = switch (state) {
                    WalletLoaded(:final wallet) => wallet.currentBalance,
                    TransactionHistoryLoaded(:final wallet) =>
                      wallet.currentBalance,
                    _ => 0.0,
                  };
                  return Column(
                    children: [
                      _buildBalanceCard(balance),
                      _buildReconciliationBanner(state),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildFilterRow(),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, state) {
                    if (state is WalletLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: _amarillo),
                      );
                    }

                    final transactions = _extractTransactionsFromState(state);
                    final filtered = _filterTransactions(transactions);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedFilter,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${filtered.length} movimiento${filtered.length != 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: () async => _load(),
                                  child: ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) =>
                                        _buildTransactionItem(filtered[index]),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
