import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/services/receipt_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/period_filter_button.dart';
import 'package:mi_ruta/features/user/presentation/widgets/transaction_card.dart';

class MovimientosPage extends StatefulWidget {
  final WidgetBuilder? homeBuilder;
  
  const MovimientosPage({super.key, this.homeBuilder});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  static const _navIndexWallet = 1;
  static const _filterOptions = ['Hoy', 'Semanal', 'Mensual', 'Todos'];
  static const _defaultFilter = 'Todos';
  static const _defaultUserId = 'user_demo';
  static const _amarillo = Color(0xFFFFC12F);

  final int _currentNavIndex = _navIndexWallet;
  final _receiptService = ReceiptService();
  String _selectedFilter = _defaultFilter;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    _userId = _extractUserIdFromAuth();
    _loadTransactionHistory();
  }

  String _extractUserIdFromAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) return authState.user.uid;
    return _defaultUserId;
  }

  void _loadTransactionHistory() {
    context.read<WalletBloc>().add(LoadTransactionHistoryEvent(_userId));
  }

  void _onNavTap(int index) => navigateBottomNav(
        context, 
        index,
        homeBuilder: widget.homeBuilder,
      );

  void _selectFilter(String filter) {
    setState(() => _selectedFilter = filter);
  }

  List<Map<String, dynamic>> _extractTransactionsFromState(WalletState state) {
    if (state is WalletLoaded) return state.transactions;
    if (state is TransactionHistoryLoaded) return state.transactions;
    return [];
  }

  DateTime _parseTransactionDate(dynamic timestamp) {
    try {
      if (timestamp != null) return timestamp.toDate();
    } catch (e) {
      // ignorar
    }
    return DateTime.now();
  }

  List<Map<String, dynamic>> _filterTransactions(
    List<Map<String, dynamic>> transactions,
  ) {
    if (_selectedFilter == 'Todos') return transactions;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return transactions.where((transaction) {
      final date = _parseTransactionDate(transaction['timestamp']);
      final transactionDay = DateTime(date.year, date.month, date.day);

      switch (_selectedFilter) {
        case 'Hoy':
          return transactionDay.isAtSameMomentAs(today);
        case 'Semanal':
          final weekAgo = today.subtract(const Duration(days: 7));
          return transactionDay.isAfter(weekAgo) ||
              transactionDay.isAtSameMomentAs(weekAgo);
        case 'Mensual':
          return date.year == now.year && date.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'MOVIMIENTOS',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: _amarillo),
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
                ? 'No hay movimientos registrados'
                : 'No hay movimientos en este período',
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final title = transaction['description'] ?? 'Transacción';
    final amount = (transaction['amount'] ?? 0.0).toDouble().abs();
    final timestamp = transaction['timestamp'];
    final transactionType = transaction['transaction_type'] ?? '';
    
    final isTopUp = transactionType.contains('top_up') || transactionType.contains('recharge');
    final isTripIncome = transactionType == 'trip_payment_received';
    final isPositive = isTopUp || isTripIncome;
    
    final date = _parseTransactionDate(timestamp);

    IconData iconData;
    String subtitle;
    
    if (isTopUp) {
      iconData = Icons.add_circle;
      subtitle = 'Recarga de saldo';
    } else if (isTripIncome) {
      iconData = Icons.local_taxi; // Icono representativo para choferes
      subtitle = 'Cobro de pasaje';
    } else {
      iconData = Icons.remove_circle;
      subtitle = 'Pago de viaje';
    }

    return GestureDetector(
      onTap: () => _showReceiptSheet(transaction, isPositive, amount, date),
      child: TransactionCard(
        icon: iconData,
        title: title,
        subtitle: subtitle,
        amount: '${isPositive ? '+' : '-'} Bs. ${amount.toStringAsFixed(2)}',
        date: date,
        iconBackgroundColor: isTripIncome ? Colors.green.shade50 : const Color(0xFFFFF9C4),
        iconColor: isTripIncome ? Colors.green.shade700 : _amarillo,
        amountColor: isPositive ? Colors.green : _amarillo,
      ),
    );
  }

  void _showReceiptSheet(
    Map<String, dynamic> transaction,
    bool isPositive,
    double amount,
    DateTime date,
  ) {
    final isTripIncome = transaction['transaction_type'] == 'trip_payment_received';
    final subtitle = isTripIncome 
        ? 'Cobro de pasaje' 
        : (isPositive ? 'Recarga de saldo' : 'Pago de viaje');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ReceiptSheet(
        title: transaction['description'] ?? 'Transacción',
        subtitle: subtitle,
        amount: amount,
        isTopUp: isPositive, // isPositive usa el estilo verde en el comprobante
        date: date,
        onDownload: () => _downloadReceipt(sheetContext, transaction),
      ),
    );
  }

  Future<void> _downloadReceipt(
    BuildContext sheetContext,
    Map<String, dynamic> transaction,
  ) async {
    try {
      final file = await _receiptService.buildTransactionReceipt(transaction);
      if (!sheetContext.mounted) return;
      await _receiptService.share(file, subject: 'Comprobante Mi Ruta');
    } catch (e) {
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar el comprobante: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
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
              '${transactions.length} movimiento${transactions.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) =>
                _buildTransactionItem(transactions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsContainer(List<Map<String, dynamic>> transactions) {
    final filtered = _filterTransactions(transactions);
    if (filtered.isEmpty) return _buildEmptyState();
    return _buildTransactionsList(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterRow(),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  if (state is WalletLoading) return _buildLoadingState();
                  final transactions = _extractTransactionsFromState(state);
                  return _buildTransactionsContainer(transactions);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _ReceiptSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isTopUp;
  final DateTime date;
  final Future<void> Function() onDownload;

  const _ReceiptSheet({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isTopUp,
    required this.date,
    required this.onDownload,
  });

  @override
  State<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<_ReceiptSheet> {
  static const _amarillo = Color(0xFFFFC12F);
  bool _downloading = false;

  Future<void> _handleDownload() async {
    setState(() => _downloading = true);
    await widget.onDownload();
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Icon(
            Icons.receipt_long,
            size: 48,
            color: _amarillo,
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.isTopUp ? '+' : '-'} Bs. ${widget.amount.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.isTopUp ? Colors.green : _amarillo,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _handleDownload,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.download_outlined, color: Colors.black),
              label: Text(
                _downloading ? 'Generando...' : 'Descargar comprobante',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarillo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
