import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_step.dart';

class TripSummaryView extends StatelessWidget {
  final String walkStartSublabel;
  final String busLabel;
  final String walkEndSublabel;
  final String destinationName;

  const TripSummaryView({
    super.key,
    required this.walkStartSublabel,
    required this.busLabel,
    required this.walkEndSublabel,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    final walkColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      children: [
        TripStep(
          color: walkColor,
          isDotted: true,
          icon: Icons.directions_walk,
          label: 'Caminar hasta la parada',
          sublabel: walkStartSublabel,
        ),
        const TripConnector(),
        TripStep(
          color: const Color(0xFFFFC12F),
          isDotted: false,
          icon: Icons.directions_bus,
          label: busLabel,
          sublabel: 'Abordar el micro / trufi',
        ),
        const TripConnector(),
        TripStep(
          color: walkColor,
          isDotted: true,
          icon: Icons.directions_walk,
          // ✅ Texto más claro — solo si hay distancia significativa
          label: walkEndSublabel == '0 m' || walkEndSublabel == '0m'
              ? 'Bajada en el destino'
              : 'Bajarse y caminar al destino',
          sublabel: walkEndSublabel == '0 m' || walkEndSublabel == '0m'
              ? 'Tu destino está en la parada'
              : walkEndSublabel,
        ),
        const TripConnector(),
        TripStep(
          color: Colors.blue,
          isDotted: false,
          icon: Icons.location_on,
          label: destinationName,
          sublabel: '📍 Tu destino',
        ),
      ],
    );
  }
}