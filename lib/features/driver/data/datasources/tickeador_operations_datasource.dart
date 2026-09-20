import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/domain/entities/tickeador_operation.dart';

class TickeadorOperationsDatasource {
  final FirebaseFirestore _firestore;

  TickeadorOperationsDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<List<TickeadorOperation>> getOperations(String tickeadorId) async {
    try {
      final snapshot = await _firestore
          .collection('station_logs')
          .where('tickeador_id', isEqualTo: tickeadorId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      return _mapOperations(snapshot.docs, tickeadorId);
    } catch (error) {
      if (!error.toString().contains('failed-precondition') &&
          !error.toString().contains('index')) {
        throw Exception('Error obteniendo operaciones: $error');
      }

      final snapshot = await _firestore
          .collection('station_logs')
          .where('tickeador_id', isEqualTo: tickeadorId)
          .limit(100)
          .get();
      final operations = _mapOperations(snapshot.docs, tickeadorId);
      operations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return operations;
    }
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
  }) async {
    if (tickeadorId.isEmpty ||
        stationName.trim().isEmpty ||
        lineId.trim().isEmpty) {
      throw ArgumentError('Tickeador, estación y línea son obligatorios');
    }
    if (logType != 'departure' && logType != 'arrival') {
      throw ArgumentError('Tipo de operación no válido');
    }

    await _firestore.collection('station_logs').add({
      'tickeador_id': tickeadorId,
      'station_name': stationName.trim(),
      'line_id': lineId.trim(),
      'vehicle_plate': vehiclePlate.trim(),
      'driver_id': driverId.trim(),
      'passenger_count': passengerCount,
      'max_capacity': maxCapacity,
      'log_type': logType,
      'timestamp': FieldValue.serverTimestamp(),
      'time_since_last_departure': null,
    });
  }

  List<TickeadorOperation> _mapOperations(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String tickeadorId,
  ) {
    return docs.map((doc) {
      final data = doc.data();
      return TickeadorOperation(
        id: doc.id,
        tickeadorId: data['tickeador_id'] as String? ?? tickeadorId,
        stationName:
            data['station_name'] as String? ?? 'Estación no registrada',
        lineId: data['line_id'] as String? ?? '-',
        vehiclePlate: data['vehicle_plate'] as String? ?? '-',
        driverId: data['driver_id'] as String? ?? '-',
        passengerCount: (data['passenger_count'] as num?)?.toInt() ?? 0,
        maxCapacity: (data['max_capacity'] as num?)?.toInt() ?? 0,
        logType: data['log_type'] as String? ?? 'arrival',
        timestamp: _readTimestamp(data['timestamp']),
        timeSinceLastDeparture: (data['time_since_last_departure'] as num?)
            ?.toInt(),
      );
    }).toList();
  }

  DateTime _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
