import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/mis_solicitudes_beneficio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/movimientos_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/pago_qr_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/historial_beneficios_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/recarga_saldo_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/solicitud_beneficio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/estado_beneficios_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/balance_card.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class WalletPage extends StatefulWidget {
  /// A qué pantalla vuelve la pestaña "Inicio" del pie de navegación.
  /// Nulo = MiRutaScreen (pasajero); los demás perfiles pasan su propio home.
  final WidgetBuilder? homeBuilder;

  const WalletPage({super.key, this.homeBuilder});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  static const _navIndexWallet = 1;
  static const _defaultUserId = 'user_demo';

  final int _currentNavIndex = _navIndexWallet;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  void _initializeWallet() {
    _userId = _extractUserIdFromAuth();
    _loadWalletData();
  }

  String _extractUserIdFromAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      return authState.user.uid;
    }
    return _defaultUserId;
  }

  void _loadWalletData() {
    context.read<WalletBloc>().add(LoadWalletEvent(_userId));
  }

  void _onNavTap(int index) {
    navigateBottomNav(context, index, homeBuilder: widget.homeBuilder);
  }

  void _navigateToRecargaSaldo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecargaSaldoPage()),
    );
    if (!mounted) return;
    _loadWalletData();
  }

  void _navigateToMovimientos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistorialViajesPage()),
    );
  }

  void _navigateToPagoQR() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PagoQRPage(homeBuilder: widget.homeBuilder)),
    );
    if (!mounted) return;
    _loadWalletData();
  }

  void _navigateToSolicitudBeneficio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SolicitudBeneficioPage()),
    );
  }

  void _navigateToMisSolicitudesBeneficio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisSolicitudesBeneficioPage()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        'Mi Billetera',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
    );
  }

  Widget _buildErrorState(WalletError error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(error.message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.read<WalletBloc>().add(LoadWalletEvent(_userId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC12F),
              foregroundColor: Colors.black,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsColumn() {
    return Column(
      children: [
        _ActionButton(
          label: 'RECARGAR SALDO',
          icon: Icons.add_circle_outline,
          onPressed: _navigateToRecargaSaldo,
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'MOVIMIENTOS',
          icon: Icons.receipt_long_outlined,
          onPressed: _navigateToMovimientos,
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'PAGAR VIAJE',
          icon: Icons.qr_code_scanner,
          onPressed: _navigateToPagoQR,
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'ACCEDER A BENEFICIOS',
          icon: Icons.star_outline,
          onPressed: _navigateToSolicitudBeneficio,
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'MIS SOLICITUDES DE BENEFICIO',
          icon: Icons.history,
          onPressed: _navigateToMisSolicitudesBeneficio,
        ),
      ],
    );
  }

  Widget _buildMainContent(dynamic wallet) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BalanceCard(
              balance: wallet.currentBalance,
              currency: wallet.currency,
            ),
            const SizedBox(height: 32),
            const Text(
              'Acciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionsColumn(),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (state is WalletLoading) return _buildLoadingState();
          if (state is WalletError) return _buildErrorState(state);

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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC12F),
          elevation: 0,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
