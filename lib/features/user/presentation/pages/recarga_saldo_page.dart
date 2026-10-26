import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/widgets/payment_button.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/recarga_qr_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class RecargaSaldoPage extends StatefulWidget {
  const RecargaSaldoPage({super.key});

  @override
  State<RecargaSaldoPage> createState() => _RecargaSaldoPageState();
}

class _RecargaSaldoPageState extends State<RecargaSaldoPage> {
  final int _currentNavIndex = 1;
  late String _userId;

  /// Evita que un segundo toque abra dos veces la pantalla de recarga con QR.
  bool _isOpeningRecargaQR = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      _userId = authState.user.uid;
    } else {
      _userId = 'user_demo';
    }

    if (context.read<WalletBloc>().state is! WalletLoaded) {
      context.read<WalletBloc>().add(LoadWalletEvent(_userId));
    }
  }

  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

  Future<void> _openRecargaQR() async {
    if (_isOpeningRecargaQR) return;
    setState(() => _isOpeningRecargaQR = true);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecargaQRPage()),
    );
    if (mounted) setState(() => _isOpeningRecargaQR = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Recargar saldo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          final wallet = state is WalletLoaded ? state.wallet : null;
          final displayBalance = wallet != null
              ? '${wallet.currency} ${wallet.currentBalance.toStringAsFixed(2)}'
              : 'Bs. 0.00';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // Saldo card — amarillo siempre (branding), colores negros son sobre fondo amarillo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC12F), Color(0xFFE6A800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SALDO DISPONIBLE',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayBalance,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                PaymentButton(
                  label: 'RECARGA CON QR',
                  loadingLabel: 'Abriendo...',
                  isLoading: _isOpeningRecargaQR,
                  onPressed: _openRecargaQR,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
