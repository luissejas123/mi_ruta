import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_entity.dart';
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

  /// Busca un vehículo por placa (vehicle_id) en la colección `vehicles`.
  Future<VehicleEntity?> buscarVehiculoPorPlaca(String placa) async {
    try {
      final placaTrim = placa.trim().toUpperCase();
      if (placaTrim.isEmpty) return null;
      final snapshot = await _firestore
          .collection('vehicles')
          .where('vehicle_id', isEqualTo: placaTrim)
          .limit(1)
          .get();
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

  /// Lee la actividad reciente del tickeador en `station_logs`.
  ///
  /// Filtra por tickeador_id y ordena por timestamp descendente.
  /// Si Firestore requiere un índice compuesto, se propaga el error.
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
      return snapshot.docs
          .map((doc) => StationLogEntity.fromJson(doc.data()))
          .toList();
    } catch (e) {
      // Antes esta excepción llegaba cruda a la UI (pantalla roja) cada vez
      // que faltaba el índice compuesto de station_logs. Mismo fallback que
      // ya existe para 'transactions' en wallet_datasource.dart: sin el
      // índice, se pide sin ordenar y se ordena en memoria.
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        try {
          final snapshot = await _firestore
              .collection('station_logs')
              .where('tickeador_id', isEqualTo: tickeadorId)
              .limit(limit * 2)
              .get();
          final logs = snapshot.docs
              .map((doc) => StationLogEntity.fromJson(doc.data()))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return logs.take(limit).toList();
        } catch (e2) {
          throw Exception('Error obteniendo actividad reciente: $e2');
        }
      }
      throw Exception('Error obteniendo actividad reciente: $e');
    }
  }
}
