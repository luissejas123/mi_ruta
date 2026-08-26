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
    final textColor = Colors.black87;
    final secondaryTextColor = Colors.black.withValues(alpha: 0.72);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(minHeight: 86),
        decoration: BoxDecoration(
          color: const Color(0xFFFBC02D),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.route,
                color: Color(0xFFFBC02D),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    routeName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (routeRef.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      routeRef,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '~$etaMinutes min a pie',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    distance,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, size: 15, color: textColor),
          ],
        ),
      ),
    );
  }
}
