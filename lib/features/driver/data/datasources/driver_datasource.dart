import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/core/utils/firestore_date.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

/// Acceso directo a Firestore para el módulo de conductores: unidades
/// (`vehicles`) y viajes/cobros (`trips`, `transactions`). La gestión de
/// cuentas de usuario vive en UserManagementDatasource (feature admin).
class DriverDatasource {
  final FirebaseFirestore _firestore;

  DriverDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  VehicleEntity _vehicleFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final legal = d['legal_documentation'] as Map<String, dynamic>? ?? const {};
    return VehicleEntity(
      vehicleId: doc.id,
      ownerUid: d['owner_uid'] as String? ?? '',
      vehicleType: d['vehicle_type'] as String? ?? '',
      lineNumber: d['line_number'] as String? ?? '',
      internalNumber: d['internal_number'] as String? ?? '',
      brand: d['brand'] as String? ?? '',
      model: d['model'] as String? ?? '',
      color: d['color'] as String? ?? '',
      passengerCapacity: (d['passenger_capacity'] as num?)?.toInt() ?? 0,
      status: d['status'] as String? ?? 'pending_review',
      legalDocumentation: legal.map((k, v) => MapEntry(k, v as String?)),
      isOnDuty: d['is_on_duty'] as bool? ?? false,
      isOnDutyUpdatedAt: parseFirestoreDate(d['is_on_duty_updated_at']),
      updatedAt: parseFirestoreDate(d['updated_at']) ?? DateTime.now(),
    );
  }

  DriverTripEntity _tripFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return DriverTripEntity(
      tripId: doc.id,
      driverId: d['driver_id'] as String? ?? '',
      vehicleId: d['vehicle_id'] as String? ?? '',
      routeRef: d['route_ref'] as String? ?? '',
      routeName: d['route_name'] as String? ?? '',
      baseFare: (d['base_fare'] as num?)?.toDouble() ?? 0,
      status: d['status'] as String? ?? 'pending',
      paymentStatus: d['payment_status'] as String? ?? 'pending',
      passengerId: d['passenger_id'] as String?,
      paymentAmount: (d['payment_amount'] as num?)?.toDouble(),
      createdAt: parseFirestoreDate(d['created_at']),
      paidAt: parseFirestoreDate(d['paid_at']),
      verifiedBy: d['verified_by'] as String?,
      verifiedAt: parseFirestoreDate(d['verified_at']),
    );
  }

  /// Ruta asignada al PERFIL del chofer (RQ4-PRE: el presidente asigna rutas
  /// al chofer, no a la unidad). Vive en users/{uid}.assigned_route_ref.
  Future<String?> getAssignedRouteRef(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final ref = doc.data()?['assigned_route_ref'] as String?;
    return (ref != null && ref.isNotEmpty) ? ref : null;
  }

  /// Unidad asignada a un chofer (owner_uid = uid del chofer).
  Future<VehicleEntity?> getVehicleForOwner(String ownerUid) async {
    final snap = await _firestore
        .collection('vehicles')
        .where('owner_uid', isEqualTo: ownerUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _vehicleFromDoc(snap.docs.first);
  }

  /// Crea una unidad de demostración ya aprobada para una cuenta que todavía
  /// no tiene ninguna asignada. Solo la usa el selector de perfiles de la
  /// cuenta super-admin (ver SuperAdminSwitcherPage) — no forma parte del
  /// alta real de un chofer.
  Future<VehicleEntity> createDemoVehicle({
    required String ownerUid,
    required String lineNumber,
  }) async {
    final data = {
      'owner_uid': ownerUid,
      'vehicle_type': 'micro',
      'line_number': lineNumber,
      'internal_number': 'DEMO-1',
      'brand': 'Demo',
      'model': 'Sprinter',
      'color': 'Blanco',
      'passenger_capacity': 20,
      'status': 'approved',
      'is_on_duty': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    final doc = await _firestore.collection('vehicles').add(data);
    final snap = await doc.get();
    return _vehicleFromDoc(snap);
  }

  /// Alta de una unidad nueva con sus documentos (parte del flujo
  /// "Registrarme como chofer"): el propio solicitante la registra antes de
  /// ser aprobado, no el dirigente. ID del documento = placa (mismo criterio
  /// documentado en FIRESTORE_COLLECTIONS_GUIDE.md). Queda en
  /// `pending_review` hasta que `DriverApprovalPage` la revise junto con la
  /// solicitud de chofer.
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
  }) async {
    final vehicleId = plate.trim().toUpperCase();
    final docRef = _firestore.collection('vehicles').doc(vehicleId);
    await docRef.set({
      'owner_uid': ownerUid,
      'vehicle_type': vehicleType,
      'line_number': lineNumber,
      'internal_number': internalNumber,
      'brand': brand,
      'model': '',
      'color': color,
      'passenger_capacity': passengerCapacity,
      'status': 'pending_review',
      'legal_documentation': legalDocumentation,
      'is_on_duty': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    final snap = await docRef.get();
    return _vehicleFromDoc(snap);
  }

  Future<void> setVehicleServiceStatus(String vehicleId, bool isOnDuty) async {
    await _firestore.collection('vehicles').doc(vehicleId).set({
      'is_on_duty': isOnDuty,
      'is_on_duty_updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Actualiza datos editables de la unidad (RQ-64): datos generales y
  /// URLs de documentación legal (ya subidas a Storage por el caller).
  ///
  /// Vuelve a poner la unidad en `pending_review` en **toda** edición — el
  /// presidente ya la había revisado con los datos/documentos anteriores, y
  /// tiene que volver a verificarla con los nuevos antes de que siga
  /// operando como aprobada. Es la misma cuenta la que puede pedir esta
  /// revuelta a revisión (ver `firestore.rules`: el dueño solo puede mover
  /// `status` a `pending_review`, nunca a `approved`).
  Future<void> updateVehicleInfo(
    String vehicleId, {
    String? brand,
    String? model,
    String? color,
    String? internalNumber,
    String? soatUrl,
    String? vehicleInspectionUrl,
    String? driverLicenseUrl,
    String? municipalOperationCardUrl,
    String? ruatUrl,
  }) async {
    final data = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
      'status': 'pending_review',
    };
    if (brand != null) data['brand'] = brand;
    if (model != null) data['model'] = model;
    if (color != null) data['color'] = color;
    if (internalNumber != null) data['internal_number'] = internalNumber;

    final legal = <String, dynamic>{};
    if (soatUrl != null) legal['soat_url'] = soatUrl;
    if (vehicleInspectionUrl != null) {
      legal['vehicle_inspection_url'] = vehicleInspectionUrl;
    }
    if (driverLicenseUrl != null) legal['driver_license_url'] = driverLicenseUrl;
    if (municipalOperationCardUrl != null) {
      legal['municipal_operation_card_url'] = municipalOperationCardUrl;
    }
    if (ruatUrl != null) legal['ruat_url'] = ruatUrl;
    if (legal.isNotEmpty) data['legal_documentation'] = legal;

    await _firestore
        .collection('vehicles')
        .doc(vehicleId)
        .set(data, SetOptions(merge: true));
  }

  /// Unidades esperando revisión del presidente/admin — ya sea de alta o
  /// porque el dueño la editó (`updateVehicleInfo` la vuelve a poner acá).
  /// Filtro de un solo campo: no necesita índice compuesto.
  Future<List<VehicleEntity>> getVehiclesPendingReview() async {
    final snap = await _firestore
        .collection('vehicles')
        .where('status', isEqualTo: 'pending_review')
        .get();
    return snap.docs.map(_vehicleFromDoc).toList();
  }

  /// Resuelve la revisión de una unidad. Solo staff (`isStaffManager` en
  /// firestore.rules) puede aprobar o rechazar — el dueño no puede tocar
  /// `status` hacia ninguno de estos dos valores.
  Future<void> resolveVehicleReview(String vehicleId, {required bool approved}) async {
    await _firestore.collection('vehicles').doc(vehicleId).set({
      'status': approved ? 'approved' : 'rejected',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Crea un viaje pendiente de cobro (RQ-65). El QR que el chofer muestra
  /// al pasajero se arma con `driverId|tripId|amount` (ver TripPaymentService).
  Future<String> createTripCharge({
    required String driverId,
    required String vehicleId,
    required String routeRef,
    required String routeName,
    required double baseFare,
  }) async {
    final doc = await _firestore.collection('trips').add({
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'route_ref': routeRef,
      'route_name': routeName,
      'base_fare': baseFare,
      'status': 'pending',
      'payment_status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Escucha en tiempo real los cambios de un viaje (ej. para saber cuando se pagó)
  Stream<DocumentSnapshot> streamTrip(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots();
  }

  /// Historial de viajes generados por el chofer (RQ-67), más recientes primero.
  Future<List<DriverTripEntity>> getDriverTrips(String driverId, {int limit = 50}) async {
    final snap = await _firestore
        .collection('trips')
        .where('driver_id', isEqualTo: driverId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_tripFromDoc).toList();
  }

  /// Ingresos acreditados al chofer (RQ-69), tal como los registra
  /// TripPaymentService.processPayment en `transactions`.
  Future<List<Map<String, dynamic>>> getDriverIncomeTransactions(
    String driverId, {
    int limit = 50,
  }) async {
    final snap = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: driverId)
        .where('transaction_type', isEqualTo: 'trip_payment_received')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  /// Pasajeros que abordaron esta unidad recientemente (viaje pagado en las
  /// últimas [withinHours] horas, sin marca explícita de fin de viaje en el
  /// modelo actual) — usado para el aviso operacional de parada (RQ-66).
  Future<List<String>> getRecentPassengerIdsForVehicle(
    String vehicleId, {
    int withinHours = 3,
  }) async {
    final since = DateTime.now().subtract(Duration(hours: withinHours));
    final snap = await _firestore
        .collection('trips')
        .where('vehicle_id', isEqualTo: vehicleId)
        .where('payment_status', isEqualTo: 'paid')
        .where('paid_at', isGreaterThan: Timestamp.fromDate(since))
        .get();
    return snap.docs
        .map((d) => d.data()['passenger_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
  }

  /// Viaje puntual por id, usado por el tickeador para validar un cobro (RQ-78).
  Future<DriverTripEntity?> getTripById(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) return null;
    return _tripFromDoc(doc);
  }

  /// Marca un viaje como verificado en ruta por un tickeador (RQ-78).
  Future<void> markTripVerified(String tripId, String tickeadorUid) async {
    await _firestore.collection('trips').doc(tripId).set({
      'verified_by': tickeadorUid,
      'verified_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Historial de validaciones de un tickeador (RQ-79).
  Future<List<DriverTripEntity>> getTripsVerifiedBy(String tickeadorUid, {int limit = 50}) async {
    final snap = await _firestore
        .collection('trips')
        .where('verified_by', isEqualTo: tickeadorUid)
        .orderBy('verified_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_tripFromDoc).toList();
  }

  /// Unidades actualmente en servicio (RQ-75, panel de administración).
  Future<List<VehicleEntity>> getActiveVehicles() async {
    final snap =
        await _firestore.collection('vehicles').where('is_on_duty', isEqualTo: true).get();
    return snap.docs.map(_vehicleFromDoc).toList();
  }

  /// Todas las unidades registradas (para reportes operativos, RQ-77).
  Future<List<VehicleEntity>> getAllVehicles() async {
    final snap = await _firestore.collection('vehicles').get();
    return snap.docs.map(_vehicleFromDoc).toList();
  }
}
