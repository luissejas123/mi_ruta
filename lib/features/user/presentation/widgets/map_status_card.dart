import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card informativo que muestra un mensaje de estado en el mapa
/// (p.ej. permiso denegado, servicio de ubicación desactivado).
class MapStatusCard extends StatelessWidget {
  final String message;

  const MapStatusCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: AppColors.of(context).textPrimary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
