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

    final uniqueUsers = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in users) {
      final id = (doc.data()['uid'] ?? doc.id).toString();
      uniqueUsers.putIfAbsent(id, () => doc);
    }

    final uniqueTrips = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in trips) {
      final id = (doc.data()['trip_id'] ?? doc.data()['tripId'] ?? doc.id)
          .toString();
      uniqueTrips.putIfAbsent(id, () => doc);
    }

    final uniqueVehicles =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in vehicles) {
      final id = (doc.data()['vehicle_id'] ?? doc.data()['vehicleId'] ?? doc.id)
          .toString();
      uniqueVehicles.putIfAbsent(id, () => doc);
    }

    final consolidatedUsers = uniqueUsers.values;
    final consolidatedTrips = uniqueTrips.values;
    final consolidatedVehicles = uniqueVehicles.values;

    final serviceVehicleIds = <String>{};
    for (final doc in consolidatedTrips) {
      final trip = doc.data();
      final status = (trip['status'] ?? '').toString().toLowerCase();
      final vehicleId = (trip['vehicle_id'] ?? trip['vehicleId'] ?? '')
          .toString();
      if ((status == 'active' || status == 'in_progress') &&
          vehicleId.isNotEmpty) {
        serviceVehicleIds.add(vehicleId);
      }
    }

    int countVehicleStatus(String status) => consolidatedVehicles.where((doc) {
      final value = (doc.data()['status'] ?? '').toString().toLowerCase();
      return value == status;
    }).length;

    int countUsersWithRole(Set<String> roles) => consolidatedUsers.where((doc) {
      final user = doc.data();
      final role = (user['role'] ?? user['userType'] ?? '')
          .toString()
          .toLowerCase();
      return roles.contains(role);
    }).length;

    final blockedAccounts = consolidatedUsers.where((doc) {
      final value = doc.data()['isActive'] ?? doc.data()['is_active'];
      return value is bool && !value;
    }).length;

    final tripsByDriver = <String, List<Map<String, dynamic>>>{};
    final tripLinesByDriver = <String, Set<String>>{};
    for (final doc in consolidatedTrips) {
      final trip = doc.data();
      final driverId = (trip['driver_uid'] ?? trip['driver_id'] ?? '')
          .toString();
      if (driverId.isNotEmpty) {
        tripsByDriver.putIfAbsent(driverId, () => []).add(trip);
        final line = (trip['route_line'] ?? trip['line_number'] ?? '')
            .toString();
        if (line.isNotEmpty) {
          tripLinesByDriver.putIfAbsent(driverId, () => {}).add(line);
        }
      }
    }

    final linesByDriver = <String, Set<String>>{};
    for (final doc in consolidatedVehicles) {
      final vehicle = doc.data();
      final driverId = (vehicle['owner_uid'] ?? '').toString();
      final line = (vehicle['line_number'] ?? vehicle['line_id'] ?? '')
          .toString();
      if (driverId.isNotEmpty && line.isNotEmpty) {
        linesByDriver.putIfAbsent(driverId, () => {}).add(line);
      }
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
    for (final doc in consolidatedUsers) {
      final user = doc.data();
      final role = (user['role'] ?? user['userType'] ?? '')
          .toString()
          .toLowerCase();
      if (role != 'driver' && role != 'chofer' && role != 'conductor') continue;

      final id = (user['uid'] ?? doc.id).toString();
      final userRatings = ratingsByDriver[id] ?? const <num>[];
      final rating = userRatings.isEmpty
          ? (user['rating'] as num?)?.toDouble() ?? 0
          : userRatings.fold<double>(0, (sum, value) => sum + value) /
                userRatings.length;
      final driverTrips = tripsByDriver[id] ?? const <Map<String, dynamic>>[];
      final lines = <String>{
        ...?linesByDriver[id],
        ...?tripLinesByDriver[id],
      }.toList()..sort();
      final active = user['isActive'] ?? user['is_active'] ?? true;

      drivers.add(
        DriverOperationalStatus(
          id: id,
          name: (user['full_name'] ?? user['fullName'] ?? 'Sin nombre')
              .toString(),
          line: lines.join(', '),
          completedTrips: driverTrips.length,
          rating: rating,
          isSuspended: active is bool ? !active : false,
        ),
      );
    }

    return OperationalReport(
      drivers: drivers,
      unitsInService: serviceVehicleIds.length,
      approvedUnits: countVehicleStatus('approved'),
      unitsUnderReview:
          countVehicleStatus('pending') +
          countVehicleStatus('under_review') +
          countVehicleStatus('review'),
      rejectedUnits: countVehicleStatus('rejected'),
      registeredPassengers: countUsersWithRole({'user', 'passenger'}),
      registeredTicketers: countUsersWithRole({'tickeador', 'ticketing'}),
      blockedAccounts: blockedAccounts,
    );
  }
}
