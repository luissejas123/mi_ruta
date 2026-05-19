import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';

/// Panel inferior de la pantalla de navegación.
/// Muestra el icono/fase actual, la distancia restante y el botón de finalizar.
class NavBottomPanel extends StatelessWidget {
  final TripPhase phase;
  final String routeName;
  final String destinationName;
  final double remainingMeters;
  final VoidCallback onFinalize;

  const NavBottomPanel({
    super.key,
    required this.phase,
    required this.routeName,
    required this.destinationName,
    required this.remainingMeters,
    required this.onFinalize,
  });

  _PhaseDisplay _display() {
    switch (phase) {
      case TripPhase.walkStart:
        return _PhaseDisplay(
          icon: Icons.directions_walk,
          color: Colors.blue,
          title: 'Caminando a la parada',
          subtitle: 'Dirígete al punto de abordaje',
        );
      case TripPhase.onBus:
        return _PhaseDisplay(
          icon: Icons.directions_bus,
          color: const Color(0xFFFBC02D),
          title: 'En el bus',
          subtitle: routeName,
        );
      case TripPhase.walkEnd:
        return _PhaseDisplay(
          icon: Icons.directions_walk,
          color: Colors.blue,
          title: 'Caminando al destino',
          subtitle: 'Ya bajaste del bus',
        );
      case TripPhase.arrived:
        return _PhaseDisplay(
          icon: Icons.check_circle,
          color: Colors.green,
          title: '¡Llegaste!',
          subtitle: destinationName,
        );
    }
  }

  String _fmtDist(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final info = _display();
    final arrived = phase == TripPhase.arrived;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila de fase
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: info.color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(info.icon, color: info.color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info.subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtDist(remainingMeters),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: info.color,
                        ),
                      ),
                      Text(
                        'restante',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botón finalizar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: arrived ? null : onFinalize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    arrived ? 'Ver resumen' : 'Finalizar viaje',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseDisplay {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PhaseDisplay({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
