import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_seleccion_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/suggestion_card.dart';

class RutasSugerenciasPage extends StatelessWidget {
  const RutasSugerenciasPage({super.key});

  // ✅ Coordenadas de Cochabamba como centro por defecto
  static const _defaultCenter = LatLng(-17.3895, -66.1568);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Sugerencias de ruta',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destinos frecuentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    SuggestionCard(
                      title: 'Plaza 14 de septiembre',
                      subtitle: 'Destino reciente',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RutasSeleccionPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SuggestionCard(
                      title: 'Calle Los Bugambilias',
                      subtitle: 'Lugar guardado',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RutasSeleccionPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SuggestionCard(
                      title: 'Pedro de Toledo',
                      subtitle: 'Punto frecuente',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RutasSeleccionPage(),
                        ),
                      ),
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