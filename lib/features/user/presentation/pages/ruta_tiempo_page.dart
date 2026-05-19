import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_abordaje_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_info_card.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';

class RutaTiempoPage extends StatelessWidget {
  final OsmRoute? route;
  final PlaceResult? destination;

  const RutaTiempoPage({super.key, this.route, this.destination});

  @override
  Widget build(BuildContext context) {
    final routeName = route?.name ?? 'Línea seleccionada';
    final destName = destination?.name ?? 'Destino';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Tiempo estimado',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              if (destination != null)
                RouteMapView(
                  title: destName,
                  initialPosition: destination!.latLng,
                )
              else
                const RouteMapView(title: 'Tiempo estimado'),
              const SizedBox(height: 20),
              RouteInfoCard(
                routeName: routeName,
                destination: destName,
                status: 'Tráfico moderado',
                eta: 'aprox. 25 min',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RutaAbordajePage(
                          route: route,
                          destination: destination,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBC02D),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ver abordaje',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
