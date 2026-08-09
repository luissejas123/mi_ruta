import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';

import '../../data/datasources/gtfs_datasource.dart';

class GtfsScheduleService {
  final GtfsDatasource datasource;

  GtfsScheduleService(this.datasource);

  /// Resuelve la parada GTFS más cercana a [point].
  /// Retorna un map con `stop_id` y `stop_name`, o null si no hay paradas.
  Future<Map<String, String>?> resolveNearestStop(LatLng point) async {
    try {
      final stops = await datasource.parseStops();

      Map<String, String>? nearest;
      double? bestDistance;

      for (final stop in stops) {
        final lat = double.tryParse(stop['stop_lat'] ?? '');
        final lon = double.tryParse(stop['stop_lon'] ?? '');

        if (lat == null || lon == null) continue;

        final distance = DistanceUtils.metersApprox(point, LatLng(lat, lon));

        if (nearest == null || distance < bestDistance!) {
          nearest = {
            'stop_id': stop['stop_id'] ?? '',
            'stop_name': stop['stop_name'] ?? '',
          };
          bestDistance = distance;
        }
      }

      return nearest;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingDepartures({
    required String stopId,
    required DateTime now,
  }) async {
    final stopTimes = await datasource.parseStopTimes();
    final trips = await datasource.parseTrips();
    final frequencies = await datasource.parseFrequencies();
    final calendar = await datasource.parseCalendar();

    final activeService = _getActiveService(calendar, now);

    if (activeService == null) {
      return [];
    }

    final tripIds = <String>{};

    for (final stop in stopTimes) {
      if (stop['stop_id'] == stopId) {
        tripIds.add(stop['trip_id'] ?? '');
      }
    }

    final activeTrips = trips
        .where(
          (trip) =>
              tripIds.contains(trip['trip_id']) &&
              trip['service_id'] == activeService,
        )
        .toList();

    final departures = <Map<String, dynamic>>[];

    for (final trip in activeTrips) {
      final tripId = trip['trip_id'];

      final routeId = trip['route_id'];

      final headsign = trip['trip_headsign'];

      final freq = frequencies.where((f) => f['trip_id'] == tripId);

      for (final f in freq) {
        final start = _parseTime(f['start_time']!);

        final end = _parseTime(f['end_time']!);

        final interval = int.tryParse(f['headway_secs'] ?? '0') ?? 0;

        final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

        var current = start;

        while (current.isBefore(end)) {
          final currentSeconds =
              current.hour * 3600 + current.minute * 60 + current.second;

          if (currentSeconds >= nowSeconds) {
            departures.add({
              'time': _formatTime(current),

              'route_id': routeId,

              'trip_headsign': headsign,
            });
          }

          current = current.add(Duration(seconds: interval));
        }
      }
    }

    departures.sort((a, b) => a['time'].compareTo(b['time']));

    return departures.take(5).toList();
  }

  String? _getActiveService(List<Map<String, String>> calendar, DateTime date) {
    final day = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][date.weekday - 1];

    for (final service in calendar) {
      if (service[day] == '1') {
        return service['service_id'];
      }
    }

    return null;
  }

  DateTime _parseTime(String value) {
    final parts = value.split(':');

    return DateTime(
      2000,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
