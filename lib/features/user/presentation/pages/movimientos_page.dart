import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/period_filter_button.dart';
import 'package:mi_ruta/features/user/presentation/widgets/transaction_card.dart';

class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

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

  void _onNavTap(int index) => navigateBottomNav(context, index);

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

  // ✅ Filtrar transacciones según el periodo seleccionado
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
          // ✅ Solo transacciones de hoy
          return transactionDay.isAtSameMomentAs(today);
        case 'Semanal':
          // ✅ Últimos 7 días
          final weekAgo = today.subtract(const Duration(days: 7));
          return transactionDay.isAfter(weekAgo) ||
              transactionDay.isAtSameMomentAs(weekAgo);
        case 'Mensual':
          // ✅ Mismo mes y año
          return date.year == now.year && date.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'MOVIMIENTOS',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
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
            style: const TextStyle(color: Colors.black54),
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
    final isTopUp = transactionType.contains('top_up') ||
        transactionType.contains('recharge');
    final date = _parseTransactionDate(timestamp);

    return TransactionCard(
      icon: isTopUp ? Icons.add_circle : Icons.remove_circle,
      title: title,
      subtitle: isTopUp ? 'Recarga de saldo' : 'Pago de viaje',
      amount: '${isTopUp ? '+' : '-'} Bs. ${amount.toStringAsFixed(2)}',
      date: date,
      iconBackgroundColor: const Color(0xFFFFF9C4),
      iconColor: _amarillo,
      amountColor: isTopUp ? Colors.green : _amarillo,
    );
  }

  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Muestra el periodo y cantidad de resultados
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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
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
    // ✅ Aplicar filtro antes de mostrar
    final filtered = _filterTransactions(transactions);
    if (filtered.isEmpty) return _buildEmptyState();
    return _buildTransactionsList(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

