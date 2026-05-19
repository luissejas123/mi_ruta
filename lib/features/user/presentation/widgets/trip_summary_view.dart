import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_step.dart';

/// Resumen visual del trayecto completo:
/// inicio a pie → bus → bajada a pie → destino final.
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
    return Column(
      children: [
        TripStep(
          color: Colors.grey.shade700,
          isDotted: true,
          icon: Icons.directions_walk,
          label: 'Caminar hasta la parada',
          sublabel: walkStartSublabel,
        ),
        const TripConnector(),
        TripStep(
          color: const Color(0xFFFBC02D),
          isDotted: false,
          icon: Icons.directions_bus,
          label: busLabel,
          sublabel: 'Tomar el micro / trufi',
        ),
        const TripConnector(),
        TripStep(
          color: Colors.grey.shade700,
          isDotted: true,
          icon: Icons.directions_walk,
          label: 'Caminar hasta el destino',
          sublabel: walkEndSublabel,
        ),
        const TripConnector(),
        TripStep(
          color: Colors.blue,
          isDotted: false,
          icon: Icons.location_on,
          label: destinationName,
          sublabel: 'Destino final',
        ),
      ],
    );
  }
}
