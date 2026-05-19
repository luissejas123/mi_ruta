import 'package:flutter/material.dart';

/// Fila de selección de ubicación (origen o destino) con icono, texto y botón de pin.
class LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;

  /// Texto a mostrar. Si [isPlaceholder] es true se renderiza en gris claro.
  final String label;
  final bool isPlaceholder;

  /// Se llama al tocar la fila (abre búsqueda de dirección).
  final VoidCallback onTap;

  /// Se llama al tocar el icono de pin (activa selección en mapa).
  final VoidCallback onPinTap;

  const LocationRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
    required this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isPlaceholder ? Colors.black45 : Colors.black87,
                  fontWeight: isPlaceholder
                      ? FontWeight.normal
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.push_pin_outlined, size: 20),
              color: Colors.black54,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onPinTap,
              tooltip: 'Seleccionar en mapa',
            ),
          ],
        ),
      ),
    );
  }
}
