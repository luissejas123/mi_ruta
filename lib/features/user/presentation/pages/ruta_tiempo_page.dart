import 'package:flutter/material.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_abordaje_page.dart';
import 'package:mi_ruta/features/routes/presentation/pages/stop_detail_page.dart';
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
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tiempo estimado',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (destination != null)
                RouteMapView(
                  title: destName,
                  initialPosition: destination!.latLng,
                )
              else
                const RouteMapView(title: 'Tiempo estimado'),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD14D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Línea ${route?.ref ?? ''}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Parada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
