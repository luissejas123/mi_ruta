import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';

/// Repositorio de dominio para la feature Tickeador.
abstract class TickeadorRepository {
  /// Lee `tickeador_info` del documento users/{uid}.
  Future<TickeadorEntity?> getTickeadorInfo(String uid);

  /// Busca un vehículo por placa (vehicle_id).
  Future<VehicleEntity?> buscarVehiculoPorPlaca(String placa);

  /// Crea un documento en `station_logs`.
  Future<void> crearStationLog({
    required String tickeadorId,
    required String stationName,
    required String lineId,
    required String vehiclePlate,
    required String driverId,
    required int maxCapacity,
    required String logType,
  });

  /// Lee la actividad reciente del tickeador en `station_logs`.
  Future<List<StationLogEntity>> getActividadReciente(
    String tickeadorId, {
    int limit = 20,
  });
}
