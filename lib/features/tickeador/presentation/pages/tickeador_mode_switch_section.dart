import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_section_title.dart';

const _amarillo = Color(0xFFFFC12F);

/// Sección "CAMBIAR A MODO" del home de tickeador — hoy es solo informativa
/// (indica que el modo activo es Tickeador); las tarjetas Usuario/Chofer no
/// son tocables todavía.
class TickeadorModeSwitchSection extends StatelessWidget {
  const TickeadorModeSwitchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TickeadorSectionTitle('CAMBIAR A MODO'),
        const Row(
          children: [
            _ModeCard(
              mode: 'Usuario',
              icon: Icons.person_outline,
              isActive: false,
            ),
            SizedBox(width: 12),
            _ModeCard(
              mode: 'Chofer',
              icon: Icons.directions_bus_outlined,
              isActive: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'El modo Tickeador está activo',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String mode;
  final IconData icon;
  final bool isActive;

  const _ModeCard({
    required this.mode,
    required this.icon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? _amarillo.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _amarillo : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? _amarillo : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              mode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.grey.shade900 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
