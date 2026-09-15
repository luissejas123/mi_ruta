import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

class DriverDatasource {
  final FirebaseFirestore _firestore;

  DriverDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<VehicleEntity?> getVehicleForOwner(String ownerUid) async {
    final snapshot = await _firestore
        .collection('vehicles')
        .where('owner_uid', isEqualTo: ownerUid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    return VehicleEntity(
      vehicleId: doc.id,
      ownerUid: data['owner_uid'] as String? ?? ownerUid,
      lineNumber: data['line_number'] as String? ?? '',
      inService: data['in_service'] as bool? ?? false,
      serviceStartedAt: (data['service_started_at'] as Timestamp?)?.toDate(),
    );
  }

  Future<void> startService(String vehicleId) async {
    await _firestore.collection('vehicles').doc(vehicleId).set({
      'in_service': true,
      'service_started_at': FieldValue.serverTimestamp(),
      'service_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> createTripCharge({
    required String driverId,
    required String vehicleId,
    required String routeRef,
    required String routeName,
    required double baseFare,
  }) async {
    final document = await _firestore.collection('trips').add({
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'route_ref': routeRef,
      'route_name': routeName,
      'base_fare': baseFare,
      'status': 'pending',
      'payment_status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
    return document.id;
  }
}