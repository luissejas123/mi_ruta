import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';

/// Una fila de "ACTIVIDAD RECIENTE": un registro de salida o llegada
/// (`station_logs`) de una unidad en la estación del tickeador.
class TickeadorActividadItem extends StatelessWidget {
  final StationLogEntity log;

  const TickeadorActividadItem({super.key, required this.log});

  String get _logTypeLabel => log.logType == 'departure' ? 'Salida' : 'Llegada';

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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            log.logType == 'departure' ? Icons.login : Icons.logout,
            color: log.logType == 'departure'
                ? Colors.green.shade700
                : Colors.orange.shade700,
            size: 22,
          ),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
