import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/movimientos_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/pago_qr_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/recarga_saldo_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/solicitud_beneficio_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int _currentNavIndex = 1;

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  Widget _actionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Visualización saldo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C210),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Text(
                    'SALDO DISPONIBLE',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'BS. 67',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _actionButton(
              'RECARGAR SALDO',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecargaSaldoPage()),
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              'MOVIMIENTOS',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MovimientosPage()),
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              'PAGAR VIAJE',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PagoQRPage()),
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              'Acceder a beneficios',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SolicitudBeneficioPage()),
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
