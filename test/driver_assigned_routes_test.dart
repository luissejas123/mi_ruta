import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_assigned_routes_service.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

void main() {
  test('prioriza la ruta actual antes que el resto del catálogo', () {
    final routes = [
      const RouteEntity(id: 'route-2', name: 'Ruta verde', ref: 'B'),
      const RouteEntity(id: 'route-1', name: 'Ruta actual', ref: 'A'),
      const RouteEntity(id: 'route-3', name: 'Ruta azul', ref: 'C'),
    ];

    final ordered = DriverAssignedRoutesService.prioritizeActiveRoute(
      routes: routes,
      currentRouteIdOrRef: 'route-1',
    );

    expect(ordered.first.id, 'route-1');
    expect(ordered.map((route) => route.id).toList(), ['route-1', 'route-2', 'route-3']);
  });

  test('prioriza por referencia si la ruta guardada es una línea en lugar de ID', () {
    final routes = [
      const RouteEntity(id: 'route-z', name: 'Z', ref: 'Z'),
      const RouteEntity(id: 'route-a', name: 'A', ref: 'A'),
    ];

    final ordered = DriverAssignedRoutesService.prioritizeActiveRoute(
      routes: routes,
      currentRouteIdOrRef: 'A',
    );

    expect(ordered.first.ref, 'A');
  });
}
