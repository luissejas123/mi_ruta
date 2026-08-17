import 'package:flutter/material.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_abordaje_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_info_card.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';

/// Velocidad promedio de un micro/trufi en tráfico urbano (m/min),
/// misma convención usada en PlannedTripLeg.estimatedMinutes.
const double _kTransitMetersPerMinute = 250;

class RutaTiempoPage extends StatelessWidget {
  final OsmRoute? route;
  final PlaceResult? destination;

  const RutaTiempoPage({super.key, this.route, this.destination});

  /// ETA real basado en GTFS: distancia desde el punto de la ruta más
  /// cercano al destino, convertida a minutos con la velocidad promedio
  /// de transporte público.
  String _calcularEta() {
    final r = route;
    final dest = destination;
    if (r == null || dest == null || r.allPoints.isEmpty) {
      return 'Sin datos';
    }
    var closestMeters = double.infinity;
    for (final point in r.allPoints) {
      final d = DistanceUtils.metersApprox(point, dest.latLng);
      if (d < closestMeters) closestMeters = d;
    }
    final minutes = (closestMeters / _kTransitMetersPerMinute)
        .ceil()
        .clamp(1, 999);
    return 'aprox. $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final routeName = route?.name ?? 'Línea seleccionada';
    final destName = destination?.name ?? 'Destino';
    final eta = _calcularEta();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Tiempo estimado',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                eta: eta,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
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
                    backgroundColor: const Color(0xFFFFC12F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ver abordaje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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
