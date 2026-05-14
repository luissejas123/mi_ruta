import 'package:flutter/material.dart';
import 'pago_qr.dart';

class SolicitudBeneficioPage extends StatelessWidget {
  const SolicitudBeneficioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              children: [

// Imagen de ejemplo local
            Container(
              height: 150,
              width: double.infinity,
              color: const Color(0xFFCCCCCC),
              child: const Center(
                child: Icon(
                  Icons.directions_bus,
                  size: 72,
                  color: Colors.white,
                ),
              ),
                ),

                const SizedBox(height: 20),

                // ENCABEZADO
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),

                  child: Row(
                    children: [

                      // Flecha atrás
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 28,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Título
                      const Expanded(
                        child: Text(
                          'Solicitud de Beneficio',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BOTÓN ESTUDIANTE
                BeneficioButton(
                  texto: 'Estudiante',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PagoQrPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // BOTÓN UNIVERSITARIO
                BeneficioButton(
                  texto: 'Universitario',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PagoQrPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // BOTÓN ADULTO MAYOR
                BeneficioButton(
                  texto: 'Adulto mayor',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PagoQrPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Billetera',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Rutas',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ===================================
// WIDGET BOTÓN BENEFICIO
// ===================================
class BeneficioButton extends StatelessWidget {

  final String texto;
  final VoidCallback onTap;

  const BeneficioButton({
    super.key,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Center(
      child: GestureDetector(
        onTap: onTap,

        child: Container(
          width: 220,
          height: 90,

          decoration: BoxDecoration(
            color: const Color(0xFFF7C52B),

            borderRadius: BorderRadius.circular(15),

            border: Border.all(
              color: Colors.greenAccent,
              width: 1.5,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Center(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}