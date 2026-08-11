import 'package:flutter/material.dart';

/// Card que muestra la información de una ruta durante el abordaje:
/// nombre de línea, destino, ETA y estado.
class RouteInfoCard extends StatelessWidget {
  final String routeName;
  final String destination;
  final String? eta;
  final String? status;

  const RouteInfoCard({
    super.key,
    required this.routeName,
    required this.destination,
    this.eta,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Destino: $destination', style: const TextStyle(fontSize: 14)),
            if (eta != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tiempo estimado de llegada: $eta',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: 8),
              Text('Estado: $status', style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
