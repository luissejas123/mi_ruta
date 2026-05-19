import 'package:flutter/material.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_card.dart';

/// Cuerpo de [RutasSeleccionPage].
///
/// Gestiona los estados: cargando, error (con reintento), sin resultados y
/// lista de rutas encontradas. Debe envolverse con [Expanded] en la página.
class RutasSeleccionBody extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<RouteMatch> matches;
  final VoidCallback onRetry;
  final void Function(RouteMatch match) onRouteTap;

  const RutasSeleccionBody({
    super.key,
    required this.isLoading,
    required this.error,
    required this.matches,
    required this.onRetry,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (error != null) return _buildError();
    if (matches.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Buscando rutas cercanas...'),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.directions_bus_filled, size: 56, color: Colors.black26),
        SizedBox(height: 16),
        Text(
          'No hay rutas disponibles\ncerca de este destino',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _buildList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${matches.length} rutas encontradas',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          itemCount: matches.length,
          itemBuilder: (ctx, i) {
            final match = matches[i];
            final dist = DistanceUtils.formatMeters(match.distanceMeters);
            final etaMin = (match.distanceMeters / 83.3).ceil().clamp(1, 999);
            return RouteCard(
              routeName: match.route.name,
              routeRef: match.route.ref.isNotEmpty
                  ? 'Línea ${match.route.ref}'
                  : '',
              distance: dist,
              etaMinutes: etaMin,
              onTap: () => onRouteTap(match),
            );
          },
        ),
      ),
    ],
  );
}
