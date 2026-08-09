import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/user/data/models/user_model.dart';

/// Acceso directo a Firestore para el módulo de conductores: unidades
/// asignadas (`vehicles`) y cuentas de chofer (`users` con userType = 'driver').
class DriverDatasource {
  final FirebaseFirestore _firestore;

  DriverDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  VehicleEntity _vehicleFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
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
      status: vehicleStatusFromString(d['status'] as String? ?? 'pending_review'),
      inService: d['in_service'] as bool? ?? false,
      serviceStartedAt: (d['service_started_at'] as Timestamp?)?.toDate(),
    );
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

  Future<void> setVehicleServiceStatus(String vehicleId, bool inService) async {
    await _firestore.collection('vehicles').doc(vehicleId).set({
      'in_service': inService,
      'service_started_at': inService ? FieldValue.serverTimestamp() : null,
      'service_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Cuentas de chofer, para la pantalla de aprobación/bloqueo del dirigente.
  Future<List<UserModel>> getDriverUsers() async {
    final snap = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'driver')
        .get();
    return snap.docs.map((d) => UserModel.fromJson(d.data())).toList();
  }

  Future<void> setUserActiveState(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).set({
      'isActive': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
