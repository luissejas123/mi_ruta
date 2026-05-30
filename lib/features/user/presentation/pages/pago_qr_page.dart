import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/services/pago_qr_utils_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class PagoQRPage extends StatelessWidget {
  const PagoQRPage({super.key});

  @override
  Widget build(BuildContext context) => const _PagoQRView();
}

class _PagoQRView extends StatefulWidget {
  const _PagoQRView();

  @override
  State<_PagoQRView> createState() => _PagoQRViewState();
}

class _PagoQRViewState extends State<_PagoQRView> {
  static const _navIndexWallet = 1;

  String? _getUserId() {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthLoaded ? authState.user.uid : null;
  }

  void _onNavTap(int index) => navigateBottomNav(context, index);

  Future<void> _scanQr() async {
    final userId = _getUserId();
    if (userId == null) {
      _showError('No se pudo obtener tu información');
      return;
    }

    final qrResult = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(title: 'Escanear QR del viaje'),
      ),
    );

    if (PagoQRUtilsService.isValidQrResult(qrResult) && mounted) {
      context.read<TripPaymentBLoC>().add(
        ProcessPaymentEvent(userId: userId, qrData: qrResult!),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(TripPaymentSuccess state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.message), backgroundColor: Colors.green),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: const Text(
      'PAGO CON QR',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
  );

  Widget _buildHeaderText() => const Text(
    'Escanee el código QR del chofer',
    style: TextStyle(color: Colors.black54, fontSize: 16),
  );

  Widget _buildScannerBox(bool isLoading) => InkWell(
    onTap: isLoading ? null : _scanQr,
    child: Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 60, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            isLoading ? 'Procesando...' : 'Toca para escanear',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildQRFrame() => Container(
    width: double.infinity,
    height: 220,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.black, width: 4),
      color: Colors.white,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: 12, left: 12, child: _buildQRCorner()),
        Positioned(top: 12, right: 12, child: _buildQRCorner()),
        Positioned(bottom: 12, left: 12, child: _buildQRCorner()),
        Positioned(bottom: 12, right: 12, child: _buildQRCorner()),
        Positioned(
          left: 0,
          right: 0,
          child: Container(height: 2, color: Colors.red),
        ),
      ],
    ),
  );

  Widget _buildQRCorner() => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black, width: 4),
    ),
  );

  Widget _buildScanButton(bool isLoading) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: isLoading ? null : _scanQr,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        disabledBackgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        isLoading ? 'Procesando pago...' : 'Escanear código',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildSuccessMessage(TripPaymentSuccess state) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Pago exitoso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Monto: ${PagoQRUtilsService.formatAmount(state.amount)}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Saldo: ${PagoQRUtilsService.formatAmount(state.newBalance)}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildErrorMessage(TripPaymentError state) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red, width: 2),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red[700], size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            state.message,
            style: TextStyle(fontSize: 14, color: Colors.red[700]),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F3F4),
    appBar: _buildAppBar(),
    body: BlocListener<TripPaymentBLoC, TripPaymentState>(
      listener: (context, state) {
        if (state is TripPaymentSuccess) _showSuccess(state);
        if (state is TripPaymentError) _showError(state.message);
      },
      child: BlocBuilder<TripPaymentBLoC, TripPaymentState>(
        builder: (context, state) {
          final isLoading = state is TripPaymentLoading;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderText(),
                  const SizedBox(height: 30),
                  _buildScannerBox(isLoading),
                  const SizedBox(height: 40),
                  _buildQRFrame(),
                  const SizedBox(height: 30),
                  _buildScanButton(isLoading),
                  if (state is TripPaymentSuccess) ...[
                    const SizedBox(height: 24),
                    _buildSuccessMessage(state),
                  ] else if (state is TripPaymentError) ...[
                    const SizedBox(height: 24),
                    _buildErrorMessage(state),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
    bottomNavigationBar: CustomBottomNav(
      currentIndex: _navIndexWallet,
      onTap: _onNavTap,
    ),
  );
}
