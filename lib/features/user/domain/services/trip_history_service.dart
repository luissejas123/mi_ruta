import 'package:mi_ruta/features/user/data/datasources/trip_history_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';

class TripHistoryService {
  final TripHistoryDatasource _datasource;

  TripHistoryService({required TripHistoryDatasource datasource})
    : _datasource = datasource;

  Future<void> saveTrip({
    required String userId,
    required String routeName,
    required String originName,
    required String destinationName,
    required Duration elapsed,
    double farePaid = 0.0,
  }) async {
    final entry = TripHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      routeName: routeName,
      originName: originName,
      destinationName: destinationName,
      elapsed: elapsed,
      date: DateTime.now(),
      farePaid: farePaid,
    );
    await _datasource.saveTrip(entry);
  }

  Future<List<TripHistoryEntry>> getTrips(String userId) =>
      _datasource.getTrips(userId);

  Future<String> generateDriverTripHistoryFile(String userId) async {
    final trips = await _datasource.getTrips(userId);
    final content = <String>[
      'Ruta,Origen,Destino,Duracion,Fecha',
      for (final trip in trips)
        '${trip.routeName},${trip.originName},${trip.destinationName},${trip.elapsed.inMinutes},${trip.date.toIso8601String()}',
    ].join('\n');

    return content;
  }

  Future<String> downloadDriverTripHistory(String userId) async {
    final payload = await generateDriverTripHistoryFile(userId);
    return payload;
  }
}
