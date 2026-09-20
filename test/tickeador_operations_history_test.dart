import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/driver/domain/entities/tickeador_operation.dart';
import 'package:mi_ruta/features/driver/domain/services/tickeador_operations_service.dart';
import 'package:mi_ruta/features/driver/data/datasources/tickeador_operations_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final service = TickeadorOperationsService(
    datasource: TickeadorOperationsDatasource(
      firestore: FirebaseFirestore.instance,
    ),
  );

  test('las operaciones del tickeador deben ordenarse cronológicamente de más reciente a más antigua', () {
    final older = TickeadorOperation(
      id: '1',
      tickeadorId: 't-1',
      stationName: 'Terminal Norte',
      lineId: 'L1',
      vehiclePlate: 'ABC-123',
      driverId: 'd-1',
      passengerCount: 10,
      maxCapacity: 30,
      logType: 'departure',
      timestamp: DateTime(2024, 1, 1, 8, 0),
    );

    final newer = TickeadorOperation(
      id: '2',
      tickeadorId: 't-1',
      stationName: 'Terminal Sur',
      lineId: 'L2',
      vehiclePlate: 'XYZ-987',
      driverId: 'd-2',
      passengerCount: 20,
      maxCapacity: 40,
      logType: 'arrival',
      timestamp: DateTime(2024, 1, 1, 12, 0),
    );

    final sorted = service.sortChronologically([older, newer], newestFirst: true);

    expect(sorted.first.id, '2');
    expect(sorted.last.id, '1');
  });
}
