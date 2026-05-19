import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_seleccion_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';
import 'package:mi_ruta/features/user/presentation/widgets/suggestion_card.dart';

class RutasSugerenciasPage extends StatelessWidget {
  const RutasSugerenciasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Sugerencias', style: TextStyle(color: Colors.black)),
      ),
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const RouteMapView(title: 'Sugerencias de ruta'),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    SuggestionCard(
                      title: 'Plaza 14 de septiembre',
                      subtitle: 'Destino reciente',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RutasSeleccionPage(),
                          ),
                        );
                      },
                    ),
                    SuggestionCard(
                      title: 'Calle Los Bugambilias',
                      subtitle: 'Lugar guardado',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RutasSeleccionPage(),
                          ),
                        );
                      },
                    ),
                    SuggestionCard(
                      title: 'Pedro de Toledo',
                      subtitle: 'Punto frecuente',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RutasSeleccionPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) => navigateBottomNav(context, index),
      ),
    );
  }
}
