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
}
