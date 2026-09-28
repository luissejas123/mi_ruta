import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/admin/domain/entities/transported_passengers_report.dart';

/// Cuenta pasajeros transportados por ruta/fecha leyendo el historial real
/// de viajes del pasajero (`trip_history/{uid}/trips`, ver
/// TripHistoryDatasource), cruzando todos los usuarios con una
/// collection-group query filtrada por `route_refs` (array-contains).
///
/// Ojo: el id de colección "trips" también lo usa, en otro nivel, la
/// colección top-level `trips` (cobro chofer<->pasajero, esquema
/// completamente distinto — ver FIRESTORE_COLLECTIONS_GUIDE.md). Una
/// collection-group query sobre "trips" recorre AMBAS por nombre, pero acá
/// no se mezclan: esos documentos no tienen `route_refs`, así que el filtro
/// `arrayContains` los descarta solo.
class TransportedPassengersDatasource {
  final FirebaseFirestore _firestore;

  TransportedPassengersDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<TransportedPassengersReport> getReport({
    required String routeRef,
    required DateTime from,
    required DateTime to,
  }) async {
    // `date` se guarda como string ISO 8601 (ver TripHistoryDatasource), no
    // Timestamp — la comparación lexicográfica de ISO 8601 coincide con el
    // orden cronológico, así que el rango funciona igual con strings.
    final snapshot = await _firestore
        .collectionGroup('trips')
        .where('route_refs', arrayContains: routeRef)
        .where('date', isGreaterThanOrEqualTo: from.toIso8601String())
        .where('date', isLessThanOrEqualTo: to.toIso8601String())
        .get();

    final uniquePassengers = <String>{};
    final tripsPerDay = <DateTime, int>{};
    for (var day = _dateOnly(from);
        !day.isAfter(_dateOnly(to));
        day = day.add(const Duration(days: 1))) {
      tripsPerDay[day] = 0;
    }

    for (final doc in snapshot.docs) {
      // trip_history/{uid}/trips/{tripId} -> el uid es el padre del padre.
      final uid = doc.reference.parent.parent?.id;
      if (uid != null) uniquePassengers.add(uid);

      final dateStr = doc.data()['date'] as String?;
      if (dateStr != null) {
        final day = _dateOnly(DateTime.parse(dateStr));
        tripsPerDay.update(day, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    return TransportedPassengersReport(
      routeRef: routeRef,
      from: from,
      to: to,
      totalTrips: snapshot.docs.length,
      uniquePassengers: uniquePassengers.length,
      tripsPerDay: tripsPerDay.entries
          .map((e) => DailyTripsCount(day: e.key, count: e.value))
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day)),
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
