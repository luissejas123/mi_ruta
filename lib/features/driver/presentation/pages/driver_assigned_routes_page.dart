import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_route_map.dart';

const _amarillo = Color(0xFFFFC12F);

/// "Ruta asignada" del propio chofer — de solo lectura.
///
/// Antes esta pantalla dejaba "elegir" cualquier línea del catálogo GTFS
/// completo y la guardaba en `driver_profile.assigned_route_id`, un campo
/// que el flujo real nunca lee (ver DEUDA_TECNICA.md #1). El presidente es
/// quien asigna la línea (`AsignarRutaChoferPage` → `assigned_route_ref`);
/// acá el chofer solo puede ver cuál le asignaron — mismo dato que ya usa
/// su propio Inicio (`DriverService.getAssignedRoute`).
class DriverAssignedRoutesPage extends StatefulWidget {
  const DriverAssignedRoutesPage({super.key});

  @override
  State<DriverAssignedRoutesPage> createState() => _DriverAssignedRoutesPageState();
}

class _DriverAssignedRoutesPageState extends State<DriverAssignedRoutesPage> {
  late Future<RouteEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RouteEntity?> _load() async {
    final authState = context.read<AuthBloc>().state;
    final driverId = authState is AuthLoaded ? authState.user.uid : '';
    if (driverId.isEmpty) return null;
    final service = getIt<DriverService>();
    final vehicle = await service.getAssignedVehicle(driverId);
    if (vehicle == null) return null;
    return service.getAssignedRoute(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Ruta asignada',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: FutureBuilder<RouteEntity?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          final route = snapshot.data;
          if (route == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alt_route_outlined,
                        size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text(
                      'Todavía no tienes una línea asignada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El dirigente te la asigna desde su panel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AssignedRouteCard(route: route),
          );
        },
      ),
    );
  }
}

/// Tarjeta con línea + mapa del recorrido — la reutilizan la vista del
/// chofer y la del presidente (`ver_ruta_chofer_page.dart`).
class AssignedRouteCard extends StatelessWidget {
  final RouteEntity route;

  const AssignedRouteCard({super.key, required this.route});

  static List<LatLng> _routePoints(RouteEntity route) {
    final source = route.polyline?.isNotEmpty == true ? route.polyline! : route.stops ?? [];
    return source
        .map((point) => LatLng(point['lat'] ?? 0, point['lng'] ?? 0))
        .where((point) => point.latitude != 0 || point.longitude != 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final points = _routePoints(route);
    return Card(
      color: _amarillo,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, size: 38, color: Colors.black87),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Línea ${route.ref}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(route.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(
                        '${route.stops?.length ?? 0} paradas · ${points.length} puntos de recorrido',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (points.length >= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: TripRouteMap(
                initialTarget: points.first,
                polylines: {
                  Polyline(
                    polylineId: PolylineId('assigned_${route.id}'),
                    points: points,
                    color: const Color(0xFF111111),
                    width: 5,
                  ),
                },
                markers: {
                  for (var i = 0; i < (route.stops?.length ?? 0); i++)
                    Marker(
                      markerId: MarkerId('${route.id}_stop_$i'),
                      position: LatLng(route.stops![i]['lat'] ?? 0, route.stops![i]['lng'] ?? 0),
                      infoWindow: InfoWindow(title: 'Parada ${i + 1}'),
                    ),
                },
                boundsPoints: points,
                height: 240,
              ),
            ),
        ],
      ),
    );
  }
}
