import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';

class RutasSeleccionPage extends StatelessWidget {
  const RutasSeleccionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Selecciona línea', style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const RouteMapView(title: 'Rutas disponibles'),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _RouteCard(
                      line: 'Línea 133',
                      route: 'Av. Chapare → Av. Río Parapití',
                      time: '12 min',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RutaLineaPage()),
                        );
                      },
                    ),
                    _RouteCard(
                      line: 'Línea 134',
                      route: 'Av. Blanco Galindo → Calle Mendoza',
                      time: '14 min',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RutaLineaPage()),
                        );
                      },
                    ),
                    _RouteCard(
                      line: 'Línea 12',
                      route: 'Av. Ballivián → Mercado Lanza',
                      time: '18 min',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RutaLineaPage()),
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

class _RouteCard extends StatelessWidget {
  final String line;
  final String route;
  final String time;
  final VoidCallback onTap;

  const _RouteCard({
    required this.line,
    required this.route,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        title: Text(line, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(route),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_forward_ios, size: 18),
            const SizedBox(height: 6),
            Text(time, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
