import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_seleccion_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';

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
                    _SuggestionCard(
                      title: 'Plaza 14 de septiembre',
                      subtitle: 'Destino reciente',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RutasSeleccionPage()),
                        );
                      },
                    ),
                    _SuggestionCard(
                      title: 'Calle Los Bugambilias',
                      subtitle: 'Lugar guardado',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RutasSeleccionPage()),
                        );
                      },
                    ),
                    _SuggestionCard(
                      title: 'Pedro de Toledo',
                      subtitle: 'Punto frecuente',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RutasSeleccionPage()),
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

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }
}
