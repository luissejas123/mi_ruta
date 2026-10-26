import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Grupo de FABs flotantes del mapa de inicio:
/// centrar en mi ubicación, activar modo pin y limpiar búsqueda.
///
/// Debe colocarse dentro de un [Stack] con `Positioned.fill`.
class MapActionFabs extends StatelessWidget {
  final bool hasDestination;
  final VoidCallback onMyLocation;
  final VoidCallback onTogglePin;
  final VoidCallback onClearSearch;

  const MapActionFabs({
    super.key,
    required this.hasDestination,
    required this.onMyLocation,
    required this.onTogglePin,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.small(
            heroTag: 'inicio_my_location',
            backgroundColor: Colors.white,
            onPressed: onMyLocation,
            tooltip: 'Mi ubicación',
            child: Icon(Icons.my_location, color: AppColors.of(context).textPrimary),
          ),
        ),
        Positioned(
          right: 16,
          bottom: hasDestination ? 136 : 80,
          child: FloatingActionButton.small(
            heroTag: 'inicio_pin_mode',
            backgroundColor: Colors.white,
            onPressed: onTogglePin,
            tooltip: 'Mover pin al destino',
            child: Icon(
              Icons.push_pin,
              color: AppColors.of(context).textPrimary,
              size: 20,
            ),
          ),
        ),
        if (hasDestination)
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.small(
              heroTag: 'inicio_clear_search',
              backgroundColor: Colors.white,
              onPressed: onClearSearch,
              tooltip: 'Limpiar búsqueda',
              child: Icon(Icons.close, color: AppColors.of(context).textPrimary),
            ),
          ),
      ],
    );
  }
}
