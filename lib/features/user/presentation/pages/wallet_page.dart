import 'package:flutter/material.dart';

import '../widgets/custom_bottom_nav.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  static const _background = Color(0xFFF1F3F4);
  static const _cardColor = Color(0xFFFBC02D);
  static const _buttonDark = Color(0xFF212121);
  static const _buttonLight = Color(0xFFFBC02D);
  static const _textDark = Color(0xFF212121);
  static const _textLight = Color(0xFFFBC02D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 30),
                _buildActionButton(
                  label: 'RECARGAR SALDO',
                  backgroundColor: _buttonDark,
                  textColor: _textLight,
                  onTap: () {
                    // TODO: Implementar recarga de saldo
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  label: 'MOVIMIENTOS',
                  backgroundColor: _buttonDark,
                  textColor: _textLight,
                  onTap: () {
                    // TODO: Navegar a movimientos
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  label: 'PAGAR VIAJE',
                  backgroundColor: _buttonLight,
                  textColor: _textDark,
                  onTap: () {
                    // TODO: Implementar pago de viaje
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  label: 'Acceder a beneficios',
                  backgroundColor: _buttonDark,
                  textColor: _textLight,
                  onTap: () {
                    // TODO: Mostrar beneficios disponibles
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          // TODO: Navegar entre pestañas (Inicio, Billetera, Rutas, Perfil)
        },
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'SALDO DISPONIBLE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'BS. 67',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
