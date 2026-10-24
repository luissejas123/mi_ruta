import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
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
/// `transactions` — recargas, pagos de viaje, reembolsos), no el historial
/// de planificación con montos estimados que mostraba `HistorialViajesPage`
/// (deuda técnica #11).
///
/// Desde acá el pasajero también puede cancelar un viaje que ya pagó: el
/// reembolso vuelve a su saldo y aparece como un movimiento más de esta
/// misma lista.
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

  DateTime _parseDate(dynamic timestamp) {
    try {
      if (timestamp != null) return timestamp.toDate();
    } catch (_) {
      // Un movimiento recién escrito puede llegar con el serverTimestamp
      // todavía nulo: se muestra con la hora local hasta que Firestore lo
      // resuelva.
    }
    return DateTime.now();
  }

  List<Map<String, dynamic>> _filterByPeriod(
    List<Map<String, dynamic>> transactions,
  ) {
    if (_selectedFilter == 'Todos') return transactions;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return transactions.where((tx) {
      final date = _parseDate(tx['timestamp']);
      final day = DateTime(date.year, date.month, date.day);

      switch (_selectedFilter) {
        case 'Hoy':
          return day.isAtSameMomentAs(today);
        case 'Semanal':
          final weekAgo = today.subtract(const Duration(days: 7));
          return day.isAfter(weekAgo) || day.isAtSameMomentAs(weekAgo);
        case 'Mensual':
          return date.year == now.year && date.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  /// El signo de `amount` no es confiable como fuente de verdad: el mismo
  /// tipo `trip_payment` se escribe en negativo desde `TripPaymentService`
  /// y en positivo desde `WalletDatasource.deductTripPayment`. La dirección
  /// del movimiento se deduce del TIPO, y el monto se muestra en absoluto.
  bool _isIncome(String type) {
    switch (type) {
      case 'recharge':
      case 'top_up':
      case 'refund':
      case 'trip_payment_received':
        return true;
      default:
        return false;
    }
  }

  String _labelFor(String type) {
    switch (type) {
      case 'recharge':
      case 'top_up':
        return 'Recarga de saldo';
      case 'trip_payment':
        return 'Pago de viaje';
      case 'trip_payment_received':
        return 'Cobro recibido';
      case 'refund':
        return 'Reembolso';
      case 'refund_issued':
        return 'Reembolso emitido';
      case 'benefit_request':
        return 'Solicitud de beneficio';
      default:
        return 'Movimiento';
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'recharge':
      case 'top_up':
        return Icons.add_card;
      case 'refund':
        return Icons.undo;
      case 'benefit_request':
        return Icons.school_outlined;
      default:
        return Icons.directions_bus_filled_outlined;
    }
  }

  Future<void> _openDetail(Map<String, dynamic> tx) async {
    final type = tx['transaction_type']?.toString() ?? '';
    final tripId = tx['trip_id']?.toString();

    // Solo un pago de viaje con `trip_id` puede cancelarse; el servicio
    // decide si ese viaje todavía es reembolsable (no reembolsado antes,
    // pagado, y de este pasajero).
    var refundable = false;
    if (type == 'trip_payment' && tripId != null && tripId.isNotEmpty) {
      refundable = await getIt<TripPaymentService>().isTripRefundable(
        userId: _userId,
        tripId: tripId,
      );
    }

    if (!mounted) return;

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
              _labelFor(type),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(tx['description']?.toString() ?? 'Movimiento de billetera'),
            const SizedBox(height: 8),
            Text(
              'Bs. ${((tx['amount'] ?? 0) as num).toDouble().abs().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
            ] else if (type == 'trip_payment') ...[
              const SizedBox(height: 16),
              Text(
                'Este viaje ya no se puede cancelar.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
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

  Widget _buildItem(Map<String, dynamic> tx) {
    final type = tx['transaction_type']?.toString() ?? '';
    final amount = ((tx['amount'] ?? 0) as num).toDouble().abs();
    final isIncome = _isIncome(type);
    final color = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return InkWell(
      onTap: () => _openDetail(tx),
      borderRadius: BorderRadius.circular(12),
      child: TransactionCard(
        icon: _iconFor(type),
        title: tx['description']?.toString() ?? _labelFor(type),
        subtitle: _labelFor(type),
        amount: '${isIncome ? '+' : '-'} Bs. ${amount.toStringAsFixed(2)}',
        date: _parseDate(tx['timestamp']),
        iconBackgroundColor: isIncome
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
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
          // El saldo y el ledger cambiaron: recargar para que el reembolso
          // aparezca en la lista sin tener que salir y volver a entrar.
          _load();
        } else if (state is TripPaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
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
              SizedBox(
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
                      onTap: () => setState(() => _selectedFilter = filter),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, state) {
                    if (state is WalletLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: _amarillo),
                      );
                    }

                    final balance = switch (state) {
                      WalletLoaded(:final wallet) => wallet.currentBalance,
                      TransactionHistoryLoaded(:final wallet) =>
                        wallet.currentBalance,
                      _ => 0.0,
                    };
                    final transactions = switch (state) {
                      WalletLoaded(:final transactions) => transactions,
                      TransactionHistoryLoaded(:final transactions) =>
                        transactions,
                      _ => const <Map<String, dynamic>>[],
                    };
                    final filtered = _filterByPeriod(transactions);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(balance),
                        const SizedBox(height: 20),
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
                                        _buildItem(filtered[index]),
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
