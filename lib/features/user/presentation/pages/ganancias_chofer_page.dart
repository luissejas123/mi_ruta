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

class GananciasChoferPage extends StatefulWidget {
  const GananciasChoferPage({super.key});

  @override
  State<GananciasChoferPage> createState() => _GananciasChoferPageState();
}

class _GananciasChoferPageState extends State<GananciasChoferPage> {
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
    context.read<WalletBloc>().add(LoadDriverEarningsEvent(_userId));
  }

  String _extractUserIdFromAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) return authState.user.uid;
    return _defaultUserId;
  }

  void _onNavTap(int index) => navigateBottomNav(context, index);

  void _selectFilter(String filter) {
    setState(() => _selectedFilter = filter);
  }

  List<Map<String, dynamic>> _extractEarningsFromState(WalletState state) {
    if (state is DriverEarningsLoaded) return state.transactions;
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

  double _sumFiltered(List<Map<String, dynamic>> transactions) {
    double total = 0.0;
    for (final tx in transactions) {
      total += (tx['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
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
        'MIS GANANCIAS',
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

  Widget _buildEarningsCard(double total) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'GANANCIAS DEL CHOFER',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bs. ${total.toStringAsFixed(2)}',
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
                ? 'Aún no tienes ganancias registradas'
                : 'No hay ganancias en este período',
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsItem(Map<String, dynamic> transaction) {
    final title = transaction['description'] ?? 'Pago recibido';
    final amount = (transaction['amount'] ?? 0.0).toDouble().abs();
    final date = _parseTransactionDate(transaction['timestamp']);

    return TransactionCard(
      icon: Icons.attach_money,
      title: title,
      subtitle: 'Pago de viaje recibido',
      amount: '+ Bs. ${amount.toStringAsFixed(2)}',
      date: date,
      iconBackgroundColor: const Color(0xFFE8F5E9),
      iconColor: Colors.green.shade700,
      amountColor: Colors.green.shade700,
    );
  }

  Widget _buildEarningsList(List<Map<String, dynamic>> transactions) {
    final filtered = _filterTransactions(transactions);
    final total = _sumFiltered(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEarningsCard(total),
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
              '${filtered.length} pago${filtered.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildEarningsItem(filtered[index]),
                ),
        ),
      ],
    );
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
                  final transactions = _extractEarningsFromState(state);
                  return _buildEarningsList(transactions);
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
