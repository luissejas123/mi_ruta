import 'package:flutter/material.dart';

/// Panel inferior que aparece en modo pin arrastrable.
/// Muestra la dirección reverse-geocodificada y los botones Cancelar / Confirmar.
class MapPinConfirmPanel extends StatelessWidget {
  final bool isCameraMoving;
  final String? address;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const MapPinConfirmPanel({
    super.key,
    required this.isCameraMoving,
    required this.address,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicador de arrastre
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Dirección
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFBC02D), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: isCameraMoving
                    ? Text(
                        'Moviendo mapa...',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.54),
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        address ?? 'Buscando dirección...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botones
          Row(
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBC02D),
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Confirmar destino',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
