import 'package:mi_ruta/features/routes/data/datasources/route_deviation_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_deviation_note.dart';

class RouteDeviationService {
  final RouteDeviationDatasource _datasource;

  RouteDeviationService({required RouteDeviationDatasource datasource}) : _datasource = datasource;

  Future<void> createNote({
    required String routeRef,
    required String note,
    required String reportedBy,
  }) {
    return _datasource.createNote(routeRef: routeRef, note: note, reportedBy: reportedBy);
  }

  Future<List<RouteDeviationNote>> getNotesForRoute(String routeRef) {
    return _datasource.getNotesForRoute(routeRef);
  }

  Future<void> setActive(String noteId, bool active) {
    return _datasource.setActive(noteId, active);
  }
}
