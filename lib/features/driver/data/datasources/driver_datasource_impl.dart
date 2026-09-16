import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/data/models/vehicle_model.dart';

class DriverDatasourceImpl implements DriverDatasource {
  final FirebaseFirestore _firestore;

  DriverDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _col => _firestore.collection('vehicles');

  @override
  Future<void> createVehicleApplication(VehicleModel vehicle) async {
    await _col.doc(vehicle.id).set({
      ...vehicle.toJson(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<VehicleModel>> getVehicleApplicationsByOwner(
    String userId,
  ) async {
    // Filtra 'owner_uid' sin orderBy para evitar requerir un índice
    // compuesto (mismo criterio que PlannedTripDatasource.getCancelled());
    // se ordena en memoria por updated_at descendente.
    final snap = await _col.where('owner_uid', isEqualTo: userId).get();
    final vehicles = snap.docs
        .map((d) =>
            VehicleModel.fromJson(d.id, d.data() as Map<String, dynamic>))
        .toList();
    vehicles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return vehicles;
  }
}
