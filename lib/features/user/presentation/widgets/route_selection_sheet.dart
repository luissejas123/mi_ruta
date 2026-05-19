import 'package:flutter/material.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_card.dart';

/// Bottom sheet arrastrable con la lista de rutas disponibles para un trayecto.
///
/// Se muestra mediante [showModalBottomSheet] envolviendo este widget en un
/// [DraggableScrollableSheet].
class RouteSelectionSheet extends StatelessWidget {
  final List<RouteMatch> matches;
  final PlaceResult destination;

  /// Llamado cuando el usuario selecciona una ruta.
  final void Function(RouteMatch match) onRouteSelected;
  final ScrollController scrollController;

  const RouteSelectionSheet({
    super.key,
    required this.matches,
    required this.destination,
    required this.onRouteSelected,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Indicador de arrastre
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rutas disponibles',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hacia ${destination.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text(
                      'No hay rutas cercanas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: matches.length,
                    itemBuilder: (_, i) {
                      final match = matches[i];
                      final dist = DistanceUtils.formatMeters(
                        match.distanceMeters,
                      );
                      final etaMin = (match.distanceMeters / 83.3).ceil().clamp(
                        1,
                        999,
                      );
                      return RouteCard(
                        routeName: match.route.name,
                        routeRef: match.route.ref.isNotEmpty
                            ? 'Línea ${match.route.ref}'
                            : '',
                        distance: dist,
                        etaMinutes: etaMin,
                        onTap: () => onRouteSelected(match),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
