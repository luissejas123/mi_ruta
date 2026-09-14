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
import 'package:mi_ruta/features/routes/domain/services/tariff_service.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';

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
  final TariffService _tariffService;
  final TripPaymentService _tripPaymentService;

  DriverService({
    required DriverDatasource datasource,
    required RouteService routeService,
    required NotificationService notificationService,
    required TariffService tariffService,
    required TripPaymentService tripPaymentService,
  })  : _datasource = datasource,
        _routeService = routeService,
        _notificationService = notificationService,
        _tariffService = tariffService,
        _tripPaymentService = tripPaymentService;

  Future<VehicleEntity?> getAssignedVehicle(String driverUid) =>
      _datasource.getVehicleForOwner(driverUid);

  /// Alta de unidad con documentos, parte de "Registrarme como chofer" — el
  /// propio solicitante la registra antes de que el dirigente apruebe su
  /// solicitud (ver `DriverApprovalPage`). Queda `pending_review`.
  Future<VehicleEntity> registerVehicle({
    required String ownerUid,
    required String vehicleType,
    required String plate,
    required String lineNumber,
    required String internalNumber,
    required String brand,
    required String color,
    required int passengerCapacity,
    required Map<String, String?> legalDocumentation,
  }) => _datasource.registerVehicle(
        ownerUid: ownerUid,
        vehicleType: vehicleType,
        plate: plate,
        lineNumber: lineNumber,
        internalNumber: internalNumber,
        brand: brand,
        color: color,
        passengerCapacity: passengerCapacity,
        legalDocumentation: legalDocumentation,
      );

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
    // Si el chofer detiene servicio con pasajeros que abordaron pero nunca
    // avisaron que bajaron, se les cobra la tarifa máxima de su línea antes
    // de cerrar — política ya decidida por el usuario (docs/
    // PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 2, paso 3). Un fallo acá no debe
    // bloquear al chofer de detener servicio.
    try {
      await _chargeOpenBoardingTrips(
        await _datasource.getOpenBoardingTripsForVehicle(vehicle.vehicleId),
      );
    } catch (_) {}
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

  /// Logo del QR fijo de la unidad (ver `DriverDatasource.updateVehicleQrLogo`
  /// — no reenvía la unidad a revisión, a diferencia de `updateVehicleInfo`).
  Future<void> updateVehicleQrLogo(String vehicleId, String qrLogoUrl) {
    return _datasource.updateVehicleQrLogo(vehicleId, qrLogoUrl);
  }

  /// Unidades pendientes de revisión (nuevas o recién editadas por su
  /// dueño), para la pantalla de revisión del presidente/admin.
  Future<List<VehicleEntity>> getVehiclesPendingReview() =>
      _datasource.getVehiclesPendingReview();

  /// Aprueba o rechaza una unidad en revisión.
  Future<void> resolveVehicleReview(String vehicleId, {required bool approved}) =>
      _datasource.resolveVehicleReview(vehicleId, approved: approved);

  /// Ruta/línea asignada al chofer (RQ-63), resuelta contra el catálogo real
  /// de rutas GTFS-sincronizado.
  ///
  /// Prioridad (RQ4-PRE: "el presidente asigna rutas al chofer, no a la
  /// unidad — el chofer elige qué vehículo usar"):
  /// 1. users/{uid}.assigned_route_ref, si el presidente ya asignó una.
  /// 2. vehicles.line_number (comportamiento legado), para no romper choferes
  ///    que ya tenían su línea puesta en la unidad antes de esta corrección.
  Future<RouteEntity?> getAssignedRoute(VehicleEntity vehicle) async {
    final profileRef = await _datasource.getAssignedRouteRef(vehicle.ownerUid);
    final ref = profileRef ?? vehicle.lineNumber;
    if (ref.isEmpty) return null;
    return _routeService.getRouteByRef(ref);
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
      // `route` viene de `getAssignedRoute` (RQ4-PRE: el presidente asigna
      // rutas al chofer) — es la fuente de verdad correcta. `vehicle.lineNumber`
      // es el valor legado que queda si el chofer nunca tuvo una ruta asignada
      // por el presidente; sin este fallback, `routeRef` quedaría vacío para
      // esos choferes y ninguna tarifa por línea (Bloque 2) se les aplicaría.
      routeRef: route?.ref ?? vehicle.lineNumber,
      routeName: route?.name ?? vehicle.lineNumber,
      baseFare: amount,
    );
    final qrData = '${vehicle.ownerUid}|$tripId|$amount';
    return {'tripId': tripId, 'qrData': qrData, 'amount': amount};
  }

  /// Registra el abordaje de un pasajero que escaneó el QR fijo de la
  /// unidad (`UnitQrPage`) — a diferencia de [generateTripCharge] (el chofer
  /// teclea un monto y genera un QR de cobro inmediato), acá no hay monto
  /// todavía: se resuelve después, por distancia, cuando el pasajero avise
  /// que baja (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 2, paso 3).
  Future<String> createBoardingTrip({
    required VehicleEntity vehicle,
    required String passengerId,
    RouteEntity? route,
  }) {
    return _datasource.createBoardingTrip(
      driverId: vehicle.ownerUid,
      vehicleId: vehicle.vehicleId,
      routeRef: route?.ref ?? vehicle.lineNumber,
      routeName: route?.name ?? vehicle.lineNumber,
      passengerId: passengerId,
    );
  }

  /// Cobra la tarifa máxima de su línea a cualquier viaje de abordaje de
  /// [driverId] que lleve más de 2 horas sin que el pasajero avise que baja
  /// — respaldo cuando ni el pasajero avisa ni el chofer detiene servicio.
  /// Se llama al abrir la pantalla de operación del chofer (no hay Cloud
  /// Functions/cron en este proyecto — ver docs/PLAN_SEGURIDAD_TARIFAS_GPS.md,
  /// decisión de "cliente de confianza" del Bloque 0), así que la cobertura
  /// depende de que el chofer abra la app; se complementa con el cobro
  /// inmediato de [stopService] cuando el chofer sí detiene servicio.
  Future<void> chargeStaleBoardingTrips(String driverId) async {
    try {
      await _chargeOpenBoardingTrips(await _datasource.getStaleBoardingTrips(driverId));
    } catch (_) {
      // No bloquea el flujo normal del chofer si esto falla.
    }
  }

  Future<void> _chargeOpenBoardingTrips(List<DriverTripEntity> trips) async {
    for (final trip in trips) {
      final maxFare = await _tariffService.resolveMaxFare(trip.routeRef);
      await _tripPaymentService.processDistanceFare(
        userId: trip.passengerId ?? '',
        driverId: trip.driverId,
        tripId: trip.tripId,
        amount: maxFare,
      );
    }
  }

  /// Escucha en tiempo real los cambios de estado de un viaje
  Stream<Map<String, dynamic>?> streamTripStatus(String tripId) {
    return _datasource.streamTrip(tripId).map((doc) => doc.data() as Map<String, dynamic>?);
  }

  /// Avisa a los pasajeros que abordaron esta unidad recientemente que el
  /// chofer se aproxima a una parada (RQ-66). Devuelve cuántos fueron notificados.
  ///
  /// Ya no pide un nombre de parada escrito a mano — no hay catálogo de
  /// paradas reales sembrado (`stops_meta` vacío, ver
  /// docs/PLAN_SEGURIDAD_TARIFAS_GPS.md Bloque 1), así que inventar un
  /// nombre sería un dato falso. La UI valida proximidad real por GPS
  /// contra `RouteEntity.polyline` antes de llamar a este método (no acá,
  /// para no depender de `DistanceUtils`/`google_maps_flutter` en el
  /// dominio de choferes) y solo permite avisar si el chofer está sobre su
  /// ruta asignada.
  Future<int> notifyStop(VehicleEntity vehicle) async {
    final passengerIds =
        await _datasource.getRecentPassengerIdsForVehicle(vehicle.vehicleId);
    for (final passengerId in passengerIds) {
      await _notificationService.saveOperationalNotification(
        passengerId,
        'Tu bus se aproxima',
        'La unidad ${vehicle.internalNumber.isNotEmpty ? vehicle.internalNumber : vehicle.vehicleId} '
            'se aproxima a tu parada.',
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
