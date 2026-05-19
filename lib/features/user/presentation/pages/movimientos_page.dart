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

/// Página que muestra el historial de movimientos/transacciones del usuario.
class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage> {
  // ─────────────────────────────────────────────────────────────────────
  // Constantes
  // ─────────────────────────────────────────────────────────────────────

  static const _navIndexWallet = 1;
  static const _filterOptions = ['Hoy', 'Semanal', 'Mensual', 'Todos'];
  static const _defaultFilter = 'Todos';
  static const _defaultUserId = 'user_demo';

  // ─────────────────────────────────────────────────────────────────────
  // Estado
  // ─────────────────────────────────────────────────────────────────────

  final int _currentNavIndex = _navIndexWallet;
  String _selectedFilter = _defaultFilter;
  late String _userId;

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Inicialización
  // ─────────────────────────────────────────────────────────────────────

  /// Obtiene el ID del usuario del AuthBloc y carga el historial de transacciones.
  void _initializeUser() {
    _userId = _extractUserIdFromAuth();
    _loadTransactionHistory();
  }

  /// Extrae el ID del usuario del estado de AuthBloc.
  String _extractUserIdFromAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      return authState.user.uid;
    }
    return _defaultUserId;
  }

  /// Dispara el evento para cargar el historial de transacciones.
  void _loadTransactionHistory() {
    context.read<WalletBloc>().add(LoadTransactionHistoryEvent(_userId));
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Navegación y Filtros
  // ─────────────────────────────────────────────────────────────────────

  /// Navega a través del bottom navigation.
  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

  /// Actualiza el filtro seleccionado.
  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Lógica de Transacciones
  // ─────────────────────────────────────────────────────────────────────

  /// Extrae la lista de transacciones del estado del WalletBloc.
  List<Map<String, dynamic>> _extractTransactionsFromState(WalletState state) {
    if (state is WalletLoaded) {
      return state.transactions;
    } else if (state is TransactionHistoryLoaded) {
      return state.transactions;
    }
    return [];
  }

  /// Parsea la fecha de la transacción de forma segura.
  DateTime _parseTransactionDate(dynamic timestamp) {
    try {
      if (timestamp != null) {
        return timestamp.toDate();
      }
    } catch (e) {
      // Ignorar error de parsing
    }
    return DateTime.now();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Construcción de Widgets
  // ─────────────────────────────────────────────────────────────────────

  /// Construye el AppBar.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
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

  /// Construye la fila de filtros de período.
  Widget _buildFilterRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
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

  /// Construye el estado de carga.
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Construye el estado cuando no hay transacciones.
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Color(0xFFF5C210)),
          SizedBox(height: 16),
          Text(
            'No hay movimientos registrados',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Construye un item individual de transacción.
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final title = transaction['description'] ?? 'Transacción';
    final amount = transaction['amount'] ?? 0.0;
    final timestamp = transaction['timestamp'];
    final isTopUp = (transaction['transaction_type'] ?? '').contains('top_up');

    final date = _parseTransactionDate(timestamp);

    return TransactionCard(
      icon: isTopUp ? Icons.add_circle : Icons.remove_circle,
      title: title,
      subtitle: isTopUp ? 'Recarga de saldo' : 'Pago de viaje',
      amount: '${isTopUp ? '+' : '-'} Bs. ${amount.toStringAsFixed(2)}',
      date: date,
      iconBackgroundColor: const Color(0xFFFFF9C4),
      iconColor: const Color(0xFFF5C210),
      amountColor: isTopUp ? Colors.green : const Color(0xFFF5C210),
    );
  }

  /// Construye la lista de transacciones.
  Widget _buildTransactionsList(List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedFilter,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  /// Construye el contenedor principal de transacciones.
  Widget _buildTransactionsContainer(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) return _buildEmptyState();
    return _buildTransactionsList(transactions);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

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
                  if (state is WalletLoading) {
                    return _buildLoadingState();
                  }

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
