import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_section_title.dart';

const _amarillo = Color(0xFFFFC12F);

/// Sección "MI ESTACIÓN" — muestra la estación asignada al tickeador
/// (`tickeador_info.assigned_station`), o "No asignada" si todavía no la
/// tiene.
class TickeadorStationSection extends StatelessWidget {
  final String? stationName;
  final bool isDarkMode;

  const TickeadorStationSection({
    super.key,
    required this.stationName,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TickeadorSectionTitle('MI ESTACIÓN'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _amarillo,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estación asignada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stationName ?? 'No asignada',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
