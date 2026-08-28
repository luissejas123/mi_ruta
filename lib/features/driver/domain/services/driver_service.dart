import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';

class DriverPerformanceSummary {
  final int totalTrips;
  final int paidTrips;
  final double totalIncome;
  final double averageFare;

  const DriverPerformanceSummary({
    required this.totalTrips,
    required this.paidTrips,
    required this.totalIncome,
    required this.averageFare,
  });
}

class DriverService {
  final DriverDatasource _datasource;
  final RouteService _routeService;
  final NotificationService _notificationService;

  DriverService({
    required DriverDatasource datasource,
    required RouteService routeService,
    required NotificationService notificationService,
  })  : _datasource = datasource,
        _routeService = routeService,
        _notificationService = notificationService;

  Future<VehicleEntity?> getAssignedVehicle(String driverUid) =>
      _datasource.getVehicleForOwner(driverUid);

  /// Si [driverUid] no tiene unidad asignada, crea una de demostración ya
  /// aprobada (con la línea de una ruta real del catálogo GTFS) y la
  /// devuelve. Solo la usa el selector de perfiles de la cuenta super-admin.
  Future<VehicleEntity> ensureDemoVehicle(String driverUid) async {
    final existing = await _datasource.getVehicleForOwner(driverUid);
    if (existing != null) return existing;
    final routes = await _routeService.getActiveRoutesLimit(1);
    final lineNumber = routes.isNotEmpty ? routes.first.ref : '1';
    return _datasource.createDemoVehicle(ownerUid: driverUid, lineNumber: lineNumber);
  }

  /// Inicia el servicio de la unidad asignada. Solo se permite si la
  /// unidad está aprobada por el dirigente/administración.
  Future<VehicleEntity> startService(VehicleEntity vehicle) async {
    if (!vehicle.isApproved) {
      throw Exception(
        'La unidad ${vehicle.vehicleId} no está aprobada para operar '
        '(estado actual: ${_statusLabel(vehicle.status)}).',
      );
    }
    await _datasource.setVehicleServiceStatus(vehicle.vehicleId, true);
    return vehicle.copyWith(isOnDuty: true, isOnDutyUpdatedAt: DateTime.now());
  }

  Future<VehicleEntity> stopService(VehicleEntity vehicle) async {
    await _datasource.setVehicleServiceStatus(vehicle.vehicleId, false);
    return vehicle.copyWith(isOnDuty: false, isOnDutyUpdatedAt: DateTime.now());
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'aprobada';
      case 'pending_review':
        return 'en revisión';
      case 'rejected':
        return 'rechazada';
      default:
        return status;
    }
  }

  /// Datos editables de la unidad y su documentación legal (RQ-64).
  Future<void> updateVehicleInfo({
    required String vehicleId,
    String? brand,
    String? model,
    String? color,
    String? internalNumber,
    String? soatUrl,
    String? vehicleInspectionUrl,
    String? driverLicenseUrl,
    String? municipalOperationCardUrl,
    String? ruatUrl,
  }) {
    return _datasource.updateVehicleInfo(
      vehicleId,
      brand: brand,
      model: model,
      color: color,
      internalNumber: internalNumber,
      soatUrl: soatUrl,
      vehicleInspectionUrl: vehicleInspectionUrl,
      driverLicenseUrl: driverLicenseUrl,
      municipalOperationCardUrl: municipalOperationCardUrl,
      ruatUrl: ruatUrl,
    );
  }

  /// Ruta/línea asignada a la unidad del chofer (RQ-63), resuelta contra
  /// el catálogo real de rutas GTFS-sincronizado.
  Future<RouteEntity?> getAssignedRoute(VehicleEntity vehicle) {
    if (vehicle.lineNumber.isEmpty) return Future.value(null);
    return _routeService.getRouteByRef(vehicle.lineNumber);
  }

  /// Genera un cobro de viaje (RQ-65): crea el `trips` pendiente y arma el
  /// texto del QR en el mismo formato que espera TripPaymentService del
  /// pasajero: "driverId|tripId|amount".
  Future<Map<String, dynamic>> generateTripCharge({
    required VehicleEntity vehicle,
    required double amount,
    RouteEntity? route,
  }) async {
    if (amount <= 0) {
      throw Exception('El monto del cobro debe ser mayor a cero.');
    }
    final tripId = await _datasource.createTripCharge(
      driverId: vehicle.ownerUid,
      vehicleId: vehicle.vehicleId,
      routeRef: vehicle.lineNumber,
      routeName: route?.name ?? vehicle.lineNumber,
      baseFare: amount,
    );
    final qrData = '${vehicle.ownerUid}|$tripId|$amount';
    return {'tripId': tripId, 'qrData': qrData, 'amount': amount};
  }

  /// Escucha en tiempo real los cambios de estado de un viaje
  Stream<Map<String, dynamic>?> streamTripStatus(String tripId) {
    return _datasource.streamTrip(tripId).map((doc) => doc.data() as Map<String, dynamic>?);
  }

  /// Avisa a los pasajeros que abordaron esta unidad recientemente que el
  /// chofer se aproxima a una parada (RQ-66). Devuelve cuántos fueron notificados.
  Future<int> notifyStop(VehicleEntity vehicle, String stopName) async {
    if (stopName.trim().isEmpty) {
      throw Exception('Ingresa el nombre de la parada.');
    }
    final passengerIds =
        await _datasource.getRecentPassengerIdsForVehicle(vehicle.vehicleId);
    for (final passengerId in passengerIds) {
      await _notificationService.saveOperationalNotification(
        passengerId,
        'Tu bus se aproxima',
        'La unidad ${vehicle.internalNumber.isNotEmpty ? vehicle.internalNumber : vehicle.vehicleId} '
            'se aproxima a la parada "$stopName".',
      );
    }
    return passengerIds.length;
  }

  /// Historial de viajes cobrados por el chofer (RQ-67).
  Future<List<DriverTripEntity>> getTripHistory(String driverUid) =>
      _datasource.getDriverTrips(driverUid);

  /// Ingresos acreditados al chofer, tal como los registra el flujo de pago
  /// QR del pasajero (RQ-69).
  Future<List<Map<String, dynamic>>> getIncomeTransactions(String driverUid) =>
      _datasource.getDriverIncomeTransactions(driverUid);

  /// Resumen de rendimiento a partir del historial real de viajes (RQ-68).
  DriverPerformanceSummary buildPerformanceSummary(List<DriverTripEntity> trips) {
    final paid = trips.where((t) => t.isPaid).toList();
    final total = paid.fold<double>(0, (sum, t) => sum + (t.paymentAmount ?? 0));
    return DriverPerformanceSummary(
      totalTrips: trips.length,
      paidTrips: paid.length,
      totalIncome: total,
      averageFare: paid.isEmpty ? 0 : total / paid.length,
    );
  }

  /// Genera un PDF con el historial de viajes e ingresos del chofer (RQ-70)
  /// y devuelve el archivo listo para compartir/descargar.
  Future<File> exportHistoryPdf({
    required String driverName,
    required List<DriverTripEntity> trips,
    required List<Map<String, dynamic>> income,
  }) async {
    final summary = buildPerformanceSummary(trips);
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Mi Ruta — Historial de viajes',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(driverName, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Viajes totales: ${summary.totalTrips}'),
              pw.Text('Pagados: ${summary.paidTrips}'),
              pw.Text('Ingresos: Bs. ${summary.totalIncome.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Viajes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Línea', 'Monto', 'Estado'],
            data: trips
                .map((t) => [
                      t.createdAt?.toString().substring(0, 16) ?? '-',
                      t.routeName,
                      'Bs. ${(t.paymentAmount ?? t.baseFare).toStringAsFixed(2)}',
                      t.isPaid ? 'Pagado' : 'Pendiente',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Ingresos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Monto', 'Descripción'],
            data: income
                .map((tx) => [
                      tx['timestamp'] != null
                          ? _tsToString(tx['timestamp'])
                          : '-',
                      'Bs. ${((tx['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                      tx['description']?.toString() ?? '',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'historial_chofer_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  String _tsToString(dynamic ts) {
    try {
      return (ts as dynamic).toDate().toString().substring(0, 16);
    } catch (_) {
      return '-';
    }
  }

  /// Historial de viajes generados por el chofer (RQ-67), más recientes primero.
  Future<List<DriverTripEntity>> getDriverTrips(String driverId, {int limit = 50}) =>
      _datasource.getDriverTrips(driverId, limit: limit);

  Future<void> shareFile(File file, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }
}
