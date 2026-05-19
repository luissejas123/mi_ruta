import 'package:flutter/material.dart';

/// Un paso individual en el resumen del trayecto (ícono + etiqueta + subetiqueta).
class TripStep extends StatelessWidget {
  final Color color;
  final bool isDotted;
  final IconData icon;
  final String label;
  final String sublabel;

  const TripStep({
    super.key,
    required this.color,
    required this.isDotted,
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isDotted ? 1.5 : 2),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sublabel,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Conector vertical entre pasos del trayecto.
class TripConnector extends StatelessWidget {
  const TripConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: Container(width: 2, height: 18, color: Colors.grey.shade300),
    );
  }
}
