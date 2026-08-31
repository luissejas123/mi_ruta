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
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, size: 24, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stopName ?? routeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC12F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status ?? 'A bordo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (effectiveLines.isNotEmpty)
            Row(
              children: [
                for (int i = 0; i < effectiveLines.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC12F).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      effectiveLines[i],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      distance ?? 'A 1.2 km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.traffic_outlined, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      trafficStatus ?? 'Tráfico moderado',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Estado: ${status ?? 'A bordo'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      'Tiempo de llegada aprox. ${estimatedArrival ?? eta ?? '25 min'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
