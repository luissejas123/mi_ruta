import 'package:flutter/material.dart';

/// Card que muestra la información de una ruta durante el abordaje:
/// nombre de línea, destino, ETA y estado.
class RouteInfoCard extends StatelessWidget {
  final String routeName;
  final String destination;
  final String? eta;
  final String? status;
  final String? stopName;
  final List<String>? routeLines;
  final String? distance;
  final String? trafficStatus;
  final String? estimatedArrival;
  final VoidCallback? onTap;

  const RouteInfoCard({
    super.key,
    required this.routeName,
    required this.destination,
    this.eta,
    this.status,
    this.stopName,
    this.routeLines,
    this.distance,
    this.trafficStatus,
    this.estimatedArrival,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLines = routeLines ?? const <String>[];
    final content = Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFFFFC12F),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stopName ?? routeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stopName != null || routeLines != null) ...[
              Text(
                'Líneas disponibles: ${effectiveLines.isEmpty ? '—' : effectiveLines.join(', ')}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 10),
            ],
            const Divider(color: Colors.black26, thickness: 1),
            const SizedBox(height: 10),
            Text(
              routeName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Destino: $destination',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiempo estimado',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        distance ?? 'A 1.2 km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.traffic_outlined,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trafficStatus ?? 'Tráfico moderado',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status ?? 'A bordo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        estimatedArrival ?? eta ?? 'aprox. 25 min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (eta != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tiempo estimado de llegada: $eta',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(
                'Estado: $status',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}
