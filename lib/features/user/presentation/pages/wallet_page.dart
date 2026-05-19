import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/movimientos_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/pago_qr_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/recarga_saldo_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/solicitud_beneficio_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/balance_card.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/wallet_primary_button.dart';

/// Página que muestra la billetera/saldo del usuario.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // ─────────────────────────────────────────────────────────────────────
  // Constantes
  // ─────────────────────────────────────────────────────────────────────

  static const _navIndexWallet = 1;
  static const _defaultUserId = 'user_demo';

  // ─────────────────────────────────────────────────────────────────────
  // Estado
  // ─────────────────────────────────────────────────────────────────────

  final int _currentNavIndex = _navIndexWallet;
  late String _userId;

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Inicialización
  // ─────────────────────────────────────────────────────────────────────

  /// Inicializa el userId y carga los datos de la billetera.
  void _initializeWallet() {
    _userId = _extractUserIdFromAuth();
    _loadWalletData();
  }

  /// Extrae el ID del usuario del estado de AuthBloc.
  String _extractUserIdFromAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      return authState.user.uid;
    }
    return _defaultUserId;
  }

  /// Carga los datos de la billetera del usuario.
  void _loadWalletData() {
    context.read<WalletBloc>().add(LoadWalletEvent(_userId));
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Navegación
  // ─────────────────────────────────────────────────────────────────────

  /// Navega a través del bottom navigation.
  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

  /// Navega a la página de recarga de saldo.
  void _navigateToRecargaSaldo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecargaSaldoPage()),
    );
  }

  /// Navega a la página de movimientos.
  void _navigateToMovimientos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MovimientosPage()),
    );
  }

  /// Navega a la página de pago QR.
  void _navigateToPagoQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PagoQRPage()),
    );
  }

  /// Navega a la página de solicitud de beneficio.
  void _navigateToSolicitudBeneficio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SolicitudBeneficioPage()),
    );
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
        'Visualización saldo',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  /// Construye el estado de carga.
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Construye el estado de error.
  Widget _buildErrorState(WalletError error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(error.message),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.read<WalletBloc>().add(LoadWalletEvent(_userId)),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de acciones de billetera.
  Widget _buildActionsColumn() {
    return Column(
      children: [
        WalletPrimaryButton(
          label: 'RECARGAR SALDO',
          onPressed: _navigateToRecargaSaldo,
        ),
        const SizedBox(height: 12),
        WalletPrimaryButton(
          label: 'MOVIMIENTOS',
          onPressed: _navigateToMovimientos,
        ),
        const SizedBox(height: 12),
        WalletPrimaryButton(label: 'PAGAR VIAJE', onPressed: _navigateToPagoQR),
        const SizedBox(height: 12),
        WalletPrimaryButton(
          label: 'ACCEDER A BENEFICIOS',
          onPressed: _navigateToSolicitudBeneficio,
        ),
      ],
    );
  }

  /// Construye el contenido principal con saldo y acciones.
  Widget _buildMainContent(dynamic wallet) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            BalanceCard(
              balance: wallet.currentBalance,
              currency: wallet.currency,
            ),
            const SizedBox(height: 32),
            _buildActionsColumn(),
          ],
        ),
      ),
    );
  }

  /// Muestra el SnackBar de éxito.
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Muestra el SnackBar de error.
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletOperationSuccess) {
            _showSuccessMessage(state.message);
          } else if (state is WalletError) {
            _showErrorMessage(state.message);
          }
        },
        builder: (context, state) {
          if (state is WalletLoading) {
            return _buildLoadingState();
          }

          if (state is WalletError) {
            return _buildErrorState(state);
          }

          final wallet = state is WalletLoaded
              ? state.wallet
              : state is TransactionHistoryLoaded
              ? state.wallet
              : null;

          if (wallet == null) {
            return const Center(child: Text('No hay datos de billetera'));
          }

          return _buildMainContent(wallet);
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
