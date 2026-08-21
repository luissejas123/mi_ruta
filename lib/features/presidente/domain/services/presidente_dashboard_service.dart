import 'package:mi_ruta/core/local_db/route_local_database.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class PresidenteDashboardService {
  final RouteLocalDatabase _localDb;

  PresidenteDashboardService({required RouteLocalDatabase localDb})
    : _localDb = localDb;

  /// Control de rutas: lee la base SQLite local ya sincronizada (metadatos livianos,
  /// sin polylines). NO usa RouteService.getAllRoutes() porque ese metodo trae la
  /// coleccion 'routes' completa de Firestore con polylines pesadas sin paginar,
  /// lo que puede tumbar la app por OOM (ver comentarios ANTI-OOM en route_datasource.dart).
  Future<List<RouteEntity>> getRoutesOverview() async {
    final rows = await _localDb.getAllRoutesMeta();
    return rows
        .map(
          (r) => RouteEntity(
            id: r['id'] as String,
            name: r['name'] as String,
            ref: r['ref'] as String,
            color: r['color'] as String?,
            directionId: r['direction_id'] as String?,
          ),
        )
        .toList();
  }
}
