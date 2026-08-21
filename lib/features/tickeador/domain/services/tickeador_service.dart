import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/repositories/tickeador_repository.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';

/// Servicio de dominio para la feature Tickeador.
///
/// Centraliza las operaciones de negocio y delega la persistencia
/// en el [TickeadorRepository].
class TickeadorService {
  final TickeadorRepository _repository;
  final DriverDatasource _driverDatasource;

  TickeadorService({required TickeadorRepository repository, DriverDatasource? driverDatasource})
    : _repository = repository,
      _driverDatasource = driverDatasource ?? getIt<DriverDatasource>();

  /// Lee `tickeador_info` del usuario autenticado.
  Future<TickeadorEntity?> getTickeadorInfo(String uid) {
    return _repository.getTickeadorInfo(uid);
  }

  /// Busca un vehículo por placa (vehicle_id).
  Future<VehicleEntity?> buscarVehiculoPorPlaca(String placa) {
    return _repository.buscarVehiculoPorPlaca(placa);
  }

  /// Marca la salida de un vehículo creando un log en `station_logs`.
  ///
  /// Requiere que el tickeador tenga estación asignada y el vehículo
  /// tenga los datos necesarios (placa, owner_uid, line_number, capacidad).
  Future<void> marcarSalida({
    required String tickeadorId,
    required String stationName,
    required VehicleEntity vehicle,
  }) async {
    if (stationName.isEmpty) {
      throw Exception('El tickeador no tiene estación asignada');
    }
    if (vehicle.vehicleId.isEmpty) {
      throw Exception('El vehículo no tiene placa');
    }
    if (vehicle.ownerUid.isEmpty) {
      throw Exception('El vehículo no tiene conductor asignado');
    }
    if (vehicle.lineNumber.isEmpty) {
      throw Exception('El vehículo no tiene línea asignada');
    }
    await _repository.crearStationLog(
      tickeadorId: tickeadorId,
      stationName: stationName,
      lineId: vehicle.lineNumber,
      vehiclePlate: vehicle.vehicleId,
      driverId: vehicle.ownerUid,
      maxCapacity: vehicle.passengerCapacity,
      logType: 'departure',
    );
  }

  /// Marca la llegada de un vehículo creando un log en `station_logs`.
  ///
  /// Requiere que el tickeador tenga estación asignada y el vehículo
  /// tenga los datos necesarios (placa, owner_uid, line_number, capacidad).
  Future<void> marcarLlegada({
    required String tickeadorId,
    required String stationName,
    required VehicleEntity vehicle,
  }) async {
    if (stationName.isEmpty) {
      throw Exception('El tickeador no tiene estación asignada');
    }
    if (vehicle.vehicleId.isEmpty) {
      throw Exception('El vehículo no tiene placa');
    }
    if (vehicle.ownerUid.isEmpty) {
      throw Exception('El vehículo no tiene conductor asignado');
    }
    if (vehicle.lineNumber.isEmpty) {
      throw Exception('El vehículo no tiene línea asignada');
    }
    await _repository.crearStationLog(
      tickeadorId: tickeadorId,
      stationName: stationName,
      lineId: vehicle.lineNumber,
      vehiclePlate: vehicle.vehicleId,
      driverId: vehicle.ownerUid,
      maxCapacity: vehicle.passengerCapacity,
      logType: 'arrival',
    );
  }

  /// Lee la actividad reciente del tickeador desde `station_logs`.
  Future<List<StationLogEntity>> getActividadReciente(
    String tickeadorId, {
    int limit = 20,
  }) {
    return _repository.getActividadReciente(tickeadorId, limit: limit);
  }

  /// Valida un código QR de viaje.
  ///
  /// Busca el viaje en la colección 'trips' y verifica que:
  /// - Exista el viaje
  /// - No esté ya verificado por otro tickeador
  Future<Map<String, dynamic>> validateTripQR(String qrCode) async {
    try {
      // Get trip from Firestore using DriverDatasource (which has trips collection access)
      final trip = await _driverDatasource.getTripById(qrCode);
      if (trip == null) {
        throw Exception('Viaje no encontrado');
      }

      // Check if the trip is already verified by another tickeador
      if (trip.verifiedBy != null && trip.verifiedBy!.isNotEmpty) {
        throw Exception('Este viaje ya ha sido verificado por otro tickeador');
      }

      return {
        'valid': true,
        'tripId': qrCode,
        'driverId': trip.driverId,
        'vehicleId': trip.vehicleId,
        'routeName': trip.routeName,
        'baseFare': trip.baseFare,
        'paymentAmount': trip.paymentAmount,
        'createdAt': trip.createdAt,
      };
    } catch (e) {
      return {
        'valid': false,
        'error': e.toString(),
      };
    }
  }

  /// Carga el historial de verificaciones del tickeador.
  ///
  /// Usa DriverDatasource para obtener los viajes verificados por este tickeador.
  Future<List<dynamic>> loadVerificationHistory(String tickeadorUid) async {
    try {
      final trips = await _driverDatasource.getTripsVerifiedBy(tickeadorUid);
      return trips.map((trip) => {
        'tripId': trip.tripId,
        'driverId': trip.driverId,
        'vehicleId': trip.vehicleId,
        'routeName': trip.routeName,
        'baseFare': trip.baseFare,
        'paymentAmount': trip.paymentAmount,
        'verifiedAt': trip.verifiedAt,
      }).toList();
    } catch (e) {
      throw Exception('Error cargando historial de verificaciones: $e');
    }
  }
}
