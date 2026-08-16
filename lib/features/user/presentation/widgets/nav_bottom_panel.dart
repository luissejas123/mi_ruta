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
          title: 'Caminando',
          subtitle: 'Dirígete a la parada',
          statusText: 'A pie',
        );
      case TripPhase.onBus:
        return _PhaseDisplay(
          icon: Icons.directions_bus,
          color: const Color(0xFFFBC02D),
          title: 'En el bus',
          subtitle: routeName,
          statusText: 'A bordo',
        );
      case TripPhase.walkEnd:
        return _PhaseDisplay(
          icon: Icons.directions_walk,
          color: Colors.blue,
          title: 'Llegando',
          subtitle: 'Ya bajaste del bus',
          statusText: 'Último tramo',
        );
      case TripPhase.arrived:
        return _PhaseDisplay(
          icon: Icons.check_circle,
          color: Colors.green,
          title: 'Llegaste',
          subtitle: destinationName,
          statusText: 'Finalizado',
        );
    }
  }

  String _fmtDist(double meters) {
    if (meters >= 1000) return 'A ${(meters / 1000).toStringAsFixed(1)} km';
    return 'A ${meters.round()} m';
  }

  String _arrivalText() {
    if (phase == TripPhase.arrived) return 'Ya llegaste';
    if (phase == TripPhase.onBus) return 'Tiempo de llegada aprox. 25 min';
    if (phase == TripPhase.walkEnd) return 'Tiempo de llegada aprox. 5 min';
    return 'Tiempo de llegada aprox. 15 min';
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transporte',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'Usuario',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: info.color.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(info.icon, color: info.color, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            info.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          _fmtDist(remainingMeters),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.traffic_outlined, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        const Text(
                          'Tráfico moderado',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC12F).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            info.statusText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
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
                          'Estado: ${info.statusText}',
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
                        const Icon(Icons.access_time_outlined, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _arrivalText(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: arrived ? null : onFinalize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: arrived ? Colors.green : Colors.red.shade600,
                    foregroundColor: Colors.white,
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
  final String statusText;

  const _PhaseDisplay({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.statusText,
  });
}
