import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';

/// Una fila de "ACTIVIDAD RECIENTE": un registro de salida o llegada
/// (`station_logs`) de una unidad en la estación del tickeador.
class TickeadorActividadItem extends StatelessWidget {
  final StationLogEntity log;

  const TickeadorActividadItem({super.key, required this.log});

  String get _logTypeLabel {
    switch (log.logType) {
      case 'departure':
        return 'Salida';
      case 'intermediate':
        return 'Punto intermedio';
      default:
        return 'Llegada';
    }
  }

  IconData get _logTypeIcon {
    switch (log.logType) {
      case 'departure':
        return Icons.login;
      case 'intermediate':
        return Icons.alt_route;
      default:
        return Icons.logout;
    }
  }

  Color _logTypeColor() {
    switch (log.logType) {
      case 'departure':
        return Colors.green.shade700;
      case 'intermediate':
        return Colors.blue.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  String _formatTimestamp(DateTime ts) {
    final local = ts.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_logTypeIcon, color: _logTypeColor(), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.vehiclePlate} · Línea ${log.lineId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_logTypeLabel · ${log.stationName}',
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
                ),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
