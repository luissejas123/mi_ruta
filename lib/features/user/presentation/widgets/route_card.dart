import 'package:flutter/material.dart';

/// Tarjeta visual para una ruta de transporte en los listados de rutas.
class RouteCard extends StatelessWidget {
  final String routeName;
  final String routeRef;

  /// Texto de distancia ya formateado (ej. "350 m", "1.2 km").
  final String distance;

  /// Tiempo estimado a pie en minutos hasta la parada de abordaje.
  final int etaMinutes;

  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.routeName,
    required this.routeRef,
    required this.distance,
    required this.etaMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFBC02D),
              radius: 20,
              child: Icon(Icons.route, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (routeRef.isNotEmpty)
                    Text(
                      routeRef,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.arrow_forward_ios, size: 14),
                const SizedBox(height: 2),
                Text(
                  '~$etaMinutes min a pie',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  distance,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
