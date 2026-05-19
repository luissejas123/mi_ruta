import 'package:flutter/material.dart';

/// Card informativo que muestra un mensaje de estado en el mapa
/// (p.ej. permiso denegado, servicio de ubicación desactivado).
class MapStatusCard extends StatelessWidget {
  final String message;

  const MapStatusCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
