import 'package:mi_ruta/features/tickeador/data/datasources/tickeador_datasource.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/repositories/tickeador_repository.dart';

/// Implementación concreta del repositorio de dominio Tickeador.
/// Delega todas las operaciones en el [TickeadorDatasource].
class TickeadorRepositoryImpl implements TickeadorRepository {
  final TickeadorDatasource _datasource;

  TickeadorRepositoryImpl({required TickeadorDatasource datasource})
    : _datasource = datasource;

  @override
  Future<TickeadorEntity?> getTickeadorInfo(String uid) {
    return _datasource.getTickeadorInfo(uid);
  }

  @override
  Future<VehicleEntity?> buscarVehiculoPorPlaca(String placa) {
    return _datasource.buscarVehiculoPorPlaca(placa);
  }

  @override
  Future<void> crearStationLog({
    required String tickeadorId,
    required String stationName,
    required String lineId,
    required String vehiclePlate,
    required String driverId,
    required int maxCapacity,
    required String logType,
  }) {
    return _datasource.crearStationLog(
      tickeadorId: tickeadorId,
      stationName: stationName,
      lineId: lineId,
      vehiclePlate: vehiclePlate,
      driverId: driverId,
      maxCapacity: maxCapacity,
      logType: logType,
    );
  }

  @override
  Future<List<StationLogEntity>> getActividadReciente(
    String tickeadorId, {
    int limit = 20,
  }) {
    return _datasource.getActividadReciente(tickeadorId, limit: limit);
  }
}
