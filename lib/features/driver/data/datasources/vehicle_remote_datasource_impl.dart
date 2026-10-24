import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/data/datasources/vehicle_remote_datasource.dart';
import 'package:mi_ruta/features/driver/data/models/vehicle_model.dart';

/// Implementación de VehicleRemoteDataSource - Conexión real a Firestore.
class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final FirebaseFirestore _firestore;

  VehicleRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<VehicleModel?> getVehicleByOwnerUid(String ownerUid) async {
    try {
      final snapshot = await _firestore
          .collection('vehicles')
          .where('owner_uid', isEqualTo: ownerUid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return VehicleModel.fromJson(doc.data(), docId: doc.id);
    } catch (e) {
      throw Exception('Error obteniendo unidad asignada: $e');
    }
  }

  @override
  Stream<VehicleModel?> getVehicleByOwnerUidStream(String ownerUid) {
    return _firestore
        .collection('vehicles')
        .where('owner_uid', isEqualTo: ownerUid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return VehicleModel.fromJson(doc.data(), docId: doc.id);
    });
  }

  @override
  Future<void> setOnDuty(String vehicleId, bool value) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).set({
        'is_on_duty': value,
        'is_on_duty_updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error actualizando estado de unidad: $e');
    }
  }

  @override
  Stream<List<VehicleModel>> getActiveVehiclesStream() {
    return _firestore
        .collection('vehicles')
        .where('is_on_duty', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }
}
