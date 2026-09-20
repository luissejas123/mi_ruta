import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_actividad_item.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_section_title.dart';

const _amarillo = Color(0xFFFFC12F);

/// Sección "ACTIVIDAD RECIENTE" — lista de salidas/llegadas registradas por
/// el tickeador, o el estado vacío si todavía no hay ninguna, más el botón
/// "Ver Historial" para recargarla.
class TickeadorActividadSection extends StatelessWidget {
  final List<StationLogEntity> logs;
  final bool isDarkMode;
  final bool isBusy;
  final VoidCallback onVerHistorial;

  const TickeadorActividadSection({
    super.key,
    required this.logs,
    required this.isDarkMode,
    required this.isBusy,
    required this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TickeadorSectionTitle('ACTIVIDAD RECIENTE'),
        if (logs.isNotEmpty)
          ...logs.map((log) => TickeadorActividadItem(log: log))
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.history, color: Colors.grey.shade400, size: 40),
                const SizedBox(height: 8),
                Text(
                  'No hay actividad registrada todavía',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onVerHistorial,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Ver Historial'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _amarillo,
              foregroundColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
