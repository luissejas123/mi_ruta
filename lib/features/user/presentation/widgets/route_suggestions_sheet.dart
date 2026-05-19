import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';

/// Bottom sheet con las rutas sugeridas cercanas a un destino.
class RouteSuggestionsSheet extends StatelessWidget {
  final PlaceResult destination;
  final List<RouteMatch> matches;

  const RouteSuggestionsSheet({
    super.key,
    required this.destination,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Color(0xFFFBC02D)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rutas sugeridas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Hacia: ${destination.name}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...matches.map((m) {
            final dist = m.distanceMeters < 1000
                ? '${m.distanceMeters.toStringAsFixed(0)} m'
                : '${(m.distanceMeters / 1000).toStringAsFixed(1)} km';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFBC02D),
                radius: 18,
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.black87,
                  size: 18,
                ),
              ),
              title: Text(
                m.route.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: m.route.ref.isNotEmpty
                  ? Text('Línea ${m.route.ref}')
                  : null,
              trailing: Text(
                dist,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RutaLineaPage(route: m.route, destination: destination),
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
