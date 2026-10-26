import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/core/utils/firestore_date.dart';
import 'package:mi_ruta/features/driver/domain/entities/live_vehicle_location.dart';

/// Ubicación en tiempo real de las unidades en servicio.
///
/// Colección `vehicle_locations/{vehicleId}`: un documento por unidad que
/// el chofer sobrescribe mientras está en servicio y borra al detenerlo.
/// Los pasajeros escuchan la colección con `snapshots()` para ver las
/// unidades moverse en el mapa. Requiere la regla de `firestore.rules`
/// para `vehicle_locations` desplegada en Firebase.
class LiveLocationDatasource {
  final FirebaseFirestore _firestore;

  LiveLocationDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('vehicle_locations');

  Future<void> publish({
    required String vehicleId,
    required String driverId,
    required double latitude,
    required double longitude,
    String? routeRef,
    String? routeName,
    double? heading,
  }) {
    return _col.doc(vehicleId).set({
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'lat': latitude,
      'lng': longitude,
      'route_ref': ?routeRef,
      'route_name': ?routeName,
      'heading': ?heading,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String vehicleId) => _col.doc(vehicleId).delete();

  /// Unidades publicando posición. Si se pasa [routeRef], solo esa línea.
  Stream<List<LiveVehicleLocation>> watch({String? routeRef}) {
    Query<Map<String, dynamic>> query = _col;
    if (routeRef != null && routeRef.isNotEmpty) {
      query = query.where('route_ref', isEqualTo: routeRef);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map((doc) => _fromDoc(doc.id, doc.data()))
          .whereType<LiveVehicleLocation>()
          .toList(),
    );
  }

  static LiveVehicleLocation? _fromDoc(String id, Map<String, dynamic> d) {
    final lat = d['lat'];
    final lng = d['lng'];
    if (lat is! num || lng is! num) return null;
    return LiveVehicleLocation(
      vehicleId: (d['vehicle_id'] as String?) ?? id,
      driverId: (d['driver_id'] as String?) ?? '',
      routeRef: d['route_ref'] as String?,
      routeName: d['route_name'] as String?,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      heading: (d['heading'] as num?)?.toDouble(),
      // Mientras el serverTimestamp se resuelve llega null: se toma como
      // recién actualizado.
      updatedAt: parseFirestoreDate(d['updated_at']) ?? DateTime.now(),
    );
  }
}
