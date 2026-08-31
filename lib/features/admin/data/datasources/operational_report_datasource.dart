import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/admin/domain/entities/operational_report.dart';

class OperationalReportDatasource {
  final FirebaseFirestore _firestore;

  OperationalReportDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<OperationalReport> getReport() async {
    final snapshots = await Future.wait([
      _firestore
          .collection('users')
          .get(const GetOptions(source: Source.server)),
      _firestore
          .collection('trips')
          .get(const GetOptions(source: Source.server)),
      _firestore
          .collection('vehicles')
          .get(const GetOptions(source: Source.server)),
      _firestore
          .collection('ratings')
          .get(const GetOptions(source: Source.server)),
    ]);

    final users = snapshots[0].docs;
    final trips = snapshots[1].docs;
    final vehicles = snapshots[2].docs;
    final ratings = snapshots[3].docs;

    final tripsByDriver = <String, List<Map<String, dynamic>>>{};
    for (final doc in trips) {
      final trip = doc.data();
      final driverId = (trip['driver_uid'] ?? trip['driver_id'] ?? '')
          .toString();
      if (driverId.isNotEmpty) {
        tripsByDriver.putIfAbsent(driverId, () => []).add(trip);
      }
    }

    final lineByDriver = <String, String>{};
    for (final doc in vehicles) {
      final vehicle = doc.data();
      final driverId = (vehicle['owner_uid'] ?? '').toString();
      final line = (vehicle['line_number'] ?? vehicle['line_id'] ?? '')
          .toString();
      if (driverId.isNotEmpty && line.isNotEmpty) lineByDriver[driverId] = line;
    }

    final ratingsByDriver = <String, List<num>>{};
    for (final doc in ratings) {
      final rating = doc.data();
      final driverId = (rating['target_uid'] ?? '').toString();
      final stars = rating['stars'];
      if (driverId.isNotEmpty && stars is num) {
        ratingsByDriver.putIfAbsent(driverId, () => []).add(stars);
      }
    }

    final drivers = <DriverOperationalStatus>[];
    for (final doc in users) {
      final user = doc.data();
      final role = (user['role'] ?? user['userType'] ?? '')
          .toString()
          .toLowerCase();
      if (role != 'driver' && role != 'chofer') continue;

      final id = (user['uid'] ?? doc.id).toString();
      final userRatings = ratingsByDriver[id] ?? const <num>[];
      final rating = userRatings.isEmpty
          ? (user['rating'] as num?)?.toDouble() ?? 0
          : userRatings.fold<double>(0, (sum, value) => sum + value) /
                userRatings.length;
      final driverTrips = tripsByDriver[id] ?? const <Map<String, dynamic>>[];
      final tripLine = driverTrips.isEmpty
          ? ''
          : (driverTrips.last['route_line'] ?? '').toString();
      final active = user['isActive'] ?? user['is_active'] ?? true;

      drivers.add(
        DriverOperationalStatus(
          id: id,
          name: (user['full_name'] ?? user['fullName'] ?? 'Sin nombre')
              .toString(),
          line: lineByDriver[id] ?? tripLine,
          completedTrips: driverTrips.length,
          rating: rating,
          isSuspended: active is bool ? !active : false,
        ),
      );
    }

    return OperationalReport(drivers: drivers);
  }
}
