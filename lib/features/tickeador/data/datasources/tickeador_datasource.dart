import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_payments_report.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';

/// Datasource de Firestore para la feature Tickeador.
///
/// Usa las colecciones reales documentadas:
/// - users/{uid}  → tickeador_info
/// - vehicles     → vehículos (vehicle_id = placa)
/// - station_logs → registros de salida/llegada
class TickeadorDatasource {
  final FirebaseFirestore _firestore;

  TickeadorDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Lee `tickeador_info` del documento users/{uid}.
  Future<TickeadorEntity?> getTickeadorInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final tickeadorInfo = data['tickeador_info'] as Map<String, dynamic>?;
      if (tickeadorInfo == null) return null;
      return TickeadorEntity.fromJson(tickeadorInfo);
    } catch (e) {
      throw Exception('Error obteniendo información del tickeador: $e');
    }
  }

  /// Busca un vehículo por placa en la colección `vehicles`.
  ///
  /// El ID del documento es la placa. Las unidades dadas de alta desde
  /// "Registrarme como chofer" no escriben un campo `vehicle_id`, así que se
  /// busca primero por ID de documento y solo después por ese campo (docs
  /// legados/demo que sí lo traen).
  Future<VehicleEntity?> buscarVehiculoPorPlaca(String placa) async {
    try {
      final placaTrim = placa.trim().toUpperCase();
      if (placaTrim.isEmpty) return null;
      final vehicles = _firestore.collection('vehicles');
      final byId = await vehicles.doc(placaTrim).get();
      if (byId.exists && byId.data() != null) {
        return VehicleEntity.fromJson({
          ...byId.data()!,
          'vehicle_id': byId.data()!['vehicle_id'] ?? byId.id,
        });
      }
      final snapshot =
          await vehicles.where('vehicle_id', isEqualTo: placaTrim).limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return VehicleEntity.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Error buscando vehículo: $e');
    }
  }

  /// Crea un documento en `station_logs`.
  ///
  /// `passenger_count` y `time_since_last_departure` se envían con valores
  /// por defecto (0 y '') porque no existe una fuente real en esta etapa.
  Future<void> crearStationLog({
    required String tickeadorId,
    required String stationName,
    required String lineId,
    required String vehiclePlate,
    required String driverId,
    required int maxCapacity,
    required String logType,
  }) async {
    try {
      await _firestore.collection('station_logs').add({
        'tickeador_id': tickeadorId,
        'station_name': stationName,
        'line_id': lineId,
        'vehicle_plate': vehiclePlate,
        'driver_id': driverId,
        'passenger_count': 0,
        'max_capacity': maxCapacity,
        'log_type': logType,
        'timestamp': FieldValue.serverTimestamp(),
        'time_since_last_departure': '',
      });
    } catch (e) {
      throw Exception('Error registrando $logType: $e');
    }
  }

  /// Auditoría de cobros reales (colección `trips`, pago chofer↔pasajero) de
  /// las unidades que pasaron por LA ESTACIÓN de este tickeador en el rango
  /// [from]-[to]. El tickeador no filtra por línea — marca salida/llegada/
  /// punto intermedio de cualquier vehículo que pase, sin verificar su
  /// recorrido en el mapa — así que el universo correcto es "vehículos con
  /// algún `station_logs` de este tickeador en el rango", no "líneas
  /// asignadas". Es un reporte de lectura: el tickeador no cobra nada de
  /// esto, ver `TickeadorPaymentsReportEntity`.
  Future<TickeadorPaymentsReportEntity> getPaymentsReport({
    required String tickeadorId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final vehicleIds = await _vehiclesSeenByTickeador(tickeadorId, from, to);
      if (vehicleIds.isEmpty) {
        return TickeadorPaymentsReportEntity(
          vehicleIds: const [],
          from: from,
          to: to,
          totalAmount: 0,
          totalTrips: 0,
          byVehicle: const [],
          byDay: const [],
        );
      }

      final amountByVehicle = <String, double>{};
      final tripsByVehicle = <String, int>{};
      final routeNameByVehicle = <String, String>{};
      // Cada cobro queda sin agrupar por día — el desglose diario muestra
      // uno por pasajero, no una suma por vehículo/día.
      final entriesByDay = <DateTime, List<_RawPaymentEntry>>{};
      var totalAmount = 0.0;
      var totalTrips = 0;

      // `whereIn` solo acepta hasta 30 valores — se consulta en lotes.
      for (var i = 0; i < vehicleIds.length; i += 30) {
        final batch = vehicleIds.sublist(i, i + 30 > vehicleIds.length ? vehicleIds.length : i + 30);
        final snapshot = await _firestore
            .collection('trips')
            .where('vehicle_id', whereIn: batch)
            .where('payment_status', isEqualTo: 'paid')
            .where('paid_at', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .where('paid_at', isLessThanOrEqualTo: Timestamp.fromDate(to))
            .get();

        totalTrips += snapshot.docs.length;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final vehicleId = data['vehicle_id'] as String? ?? '';
          final routeName = data['route_name'] as String? ?? '';
          final amount = (data['payment_amount'] as num?)?.toDouble() ??
              (data['base_fare'] as num?)?.toDouble() ??
              0.0;
          final paidAt = (data['paid_at'] as Timestamp?)?.toDate();
          final passengerId = data['passenger_id'] as String? ?? '';

          totalAmount += amount;
          amountByVehicle.update(vehicleId, (v) => v + amount, ifAbsent: () => amount);
          tripsByVehicle.update(vehicleId, (v) => v + 1, ifAbsent: () => 1);
          if (routeName.isNotEmpty) routeNameByVehicle[vehicleId] = routeName;
          if (paidAt != null) {
            final day = DateTime(paidAt.year, paidAt.month, paidAt.day);
            entriesByDay
                .putIfAbsent(day, () => [])
                .add(_RawPaymentEntry(
                  passengerId: passengerId,
                  vehicleId: vehicleId,
                  amount: amount,
                  paidAt: paidAt,
                ));
          }
        }
      }

      final byVehicle = amountByVehicle.entries
          .map((e) => VehiclePaymentsSummary(
                vehicleId: e.key,
                routeName: routeNameByVehicle[e.key] ?? '',
                amount: e.value,
                trips: tripsByVehicle[e.key] ?? 0,
              ))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      final passengerIds = entriesByDay.values
          .expand((entries) => entries)
          .map((e) => e.passengerId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final passengerNames = await _passengerNames(passengerIds);

      final byDay = entriesByDay.entries.map((e) {
        final rawEntries = e.value..sort((a, b) => a.paidAt.compareTo(b.paidAt));
        final entries = rawEntries
            .map((raw) => PaymentEntry(
                  passengerName: passengerNames[raw.passengerId] ?? 'Desconocido',
                  vehicleId: raw.vehicleId,
                  amount: raw.amount,
                  paidAt: raw.paidAt,
                ))
            .toList();
        return DailyPaymentsSummary(
          day: e.key,
          amount: rawEntries.fold(0.0, (total, raw) => total + raw.amount),
          trips: rawEntries.length,
          entries: entries,
        );
      }).toList()
        ..sort((a, b) => a.day.compareTo(b.day));

      return TickeadorPaymentsReportEntity(
        vehicleIds: vehicleIds,
        from: from,
        to: to,
        totalAmount: totalAmount,
        totalTrips: totalTrips,
        byVehicle: byVehicle,
        byDay: byDay,
      );
    } catch (e) {
      throw Exception('No se pudo generar el reporte de cobros: $e');
    }
  }

  /// Placas distintas con algún `station_logs` de [tickeadorId] en el rango.
  /// Usa el mismo fallback sin índice que `getActividadReciente` por si el
  /// índice `tickeador_id`+`timestamp` todavía no está listo.
  Future<List<String>> _vehiclesSeenByTickeador(
    String tickeadorId,
    DateTime from,
    DateTime to,
  ) async {
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
    try {
      final snapshot = await _firestore
          .collection('station_logs')
          .where('tickeador_id', isEqualTo: tickeadorId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .get();
      docs = snapshot.docs;
    } catch (error) {
      if (!isMissingCompositeIndexError(error)) rethrow;
      final fallback = await _firestore
          .collection('station_logs')
          .where('tickeador_id', isEqualTo: tickeadorId)
          .get();
      docs = fallback.docs.where((doc) {
        final ts = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return ts != null && !ts.isBefore(from) && !ts.isAfter(to);
      });
    }
    final plates = docs
        .map((doc) => doc.data()['vehicle_plate'] as String? ?? '')
        .where((plate) => plate.isNotEmpty)
        .toSet();
    return plates.toList();
  }

  /// Nombre completo de cada usuario en [passengerIds] (`users/{uid}`), para
  /// mostrar el desglose diario del reporte por nombre, no por uid. Batchea
  /// en grupos de 30 por el límite de `whereIn` sobre `FieldPath.documentId`.
  Future<Map<String, String>> _passengerNames(Set<String> passengerIds) async {
    final names = <String, String>{};
    if (passengerIds.isEmpty) return names;
    final ids = passengerIds.toList();
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        names[doc.id] = (data['fullName'] ?? data['full_name'] ?? data['name'] ?? 'Desconocido')
            as String;
      }
    }
    return names;
  }

  static bool isMissingCompositeIndexError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('failed-precondition') ||
        message.contains('failed precondition') ||
        message.contains('failed_precondition') ||
        message.contains('FAILED_PRECONDITION') ||
        message.contains('index') && message.contains('query');
  }

  /// Lee la actividad reciente del tickeador en `station_logs`.
  ///
  /// Firestore exige un índice compuesto para `.where('tickeador_id') + orderBy('timestamp')`.
  /// Si aún no existe, hacemos un fallback seguro sin orderBy y ordenamos en memoria.
  Future<List<StationLogEntity>> getActividadReciente(
    String tickeadorId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('station_logs')
          .where('tickeador_id', isEqualTo: tickeadorId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      final logs = snapshot.docs
          .map((doc) => StationLogEntity.fromJson(doc.data()))
          .toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    } catch (error) {
      if (isMissingCompositeIndexError(error)) {
        final fallback = await _firestore
            .collection('station_logs')
            .where('tickeador_id', isEqualTo: tickeadorId)
            .limit(limit)
            .get();
        final logs = fallback.docs
            .map((doc) => StationLogEntity.fromJson(doc.data()))
            .toList();
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return logs;
      }
      throw Exception('No se pudo cargar la actividad reciente del Tickeador.');
    }
  }
}

/// Cobro individual sin resolver todavía el nombre del pasajero (se resuelve
/// en lote al final, ver `_passengerNames`).
class _RawPaymentEntry {
  final String passengerId;
  final String vehicleId;
  final double amount;
  final DateTime paidAt;

  const _RawPaymentEntry({
    required this.passengerId,
    required this.vehicleId,
    required this.amount,
    required this.paidAt,
  });
}
