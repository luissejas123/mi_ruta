import 'package:mi_ruta/features/driver/data/datasources/tickeador_operations_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/tickeador_operation.dart';

class TickeadorOperationsService {
  final TickeadorOperationsDatasource _datasource;

  TickeadorOperationsService({
    required TickeadorOperationsDatasource datasource,
  }) : _datasource = datasource;

  Future<List<TickeadorOperation>> getOperations(String tickeadorId) async {
    final operations = await _datasource.getOperations(tickeadorId);
    return sortChronologically(operations, newestFirst: true);
  }

  List<TickeadorOperation> sortChronologically(
    List<TickeadorOperation> operations, {
    bool newestFirst = true,
  }) {
    final copy = List<TickeadorOperation>.from(operations);
    copy.sort((a, b) {
      final comparison = a.timestamp.compareTo(b.timestamp);
      return newestFirst ? -comparison : comparison;
    });
    return copy;
  }

  Future<void> createOperation({
    required String tickeadorId,
    required String stationName,
    required String lineId,
    required String logType,
    String vehiclePlate = '',
    String driverId = '',
    int passengerCount = 0,
    int maxCapacity = 0,
  }) => _datasource.createOperation(
    tickeadorId: tickeadorId,
    stationName: stationName,
    lineId: lineId,
    logType: logType,
    vehiclePlate: vehiclePlate,
    driverId: driverId,
    maxCapacity: maxCapacity,
    passengerCount: passengerCount,
  );
}
