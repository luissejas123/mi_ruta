import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_assigned_routes_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_assigned_routes_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_assigned_routes_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_assigned_routes_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_route_map.dart';

class DriverAssignedRoutesPage extends StatelessWidget {
  const DriverAssignedRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final driverId = authState is AuthLoaded ? authState.user.uid : '';

    return BlocProvider(
      create: (_) => DriverAssignedRoutesBloc(
        service: getIt<DriverAssignedRoutesService>(),
      )..add(LoadDriverAssignedRoutes(driverId)),
      child: _DriverAssignedRoutesView(driverId: driverId),
    );
  }
}

class _DriverAssignedRoutesView extends StatelessWidget {
  final String driverId;

  const _DriverAssignedRoutesView({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Gestión de Rutas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocConsumer<DriverAssignedRoutesBloc, DriverAssignedRoutesState>(
        listener: (context, state) {
          if (state is DriverAssignedRoutesSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ruta asignada guardada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is DriverAssignedRoutesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DriverAssignedRoutesInitial ||
              state is DriverAssignedRoutesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is DriverAssignedRoutesError) {
            return _ErrorState(message: state.message);
          }
          if (state is DriverAssignedRoutesLoaded ||
              state is DriverAssignedRoutesSaving ||
              state is DriverAssignedRoutesSaved) {
            final routes = state is DriverAssignedRoutesLoaded
                ? state.routes
                : state is DriverAssignedRoutesSaving
                ? state.routes
                : (state as DriverAssignedRoutesSaved).routes;
            if (routes.isEmpty) return const _EmptyState();
            return _AssignedRoutesList(
              routes: routes,
              driverId: driverId,
              isSaving: state is DriverAssignedRoutesSaving,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AssignedRoutesList extends StatefulWidget {
  final List<RouteEntity> routes;
  final String driverId;
  final bool isSaving;

  const _AssignedRoutesList({
    required this.routes,
    required this.driverId,
    required this.isSaving,
  });

  @override
  State<_AssignedRoutesList> createState() => _AssignedRoutesListState();
}

class _AssignedRoutesListState extends State<_AssignedRoutesList> {
  final _searchController = TextEditingController();
  String? _selectedRouteId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.routes.isNotEmpty) {
      _selectedRouteId = widget.routes.first.id;
    }
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RouteEntity> get _filteredRoutes => widget.routes.where((route) {
    return route.name.toLowerCase().contains(_query) ||
        route.ref.toLowerCase().contains(_query);
  }).toList();

  void _confirmChanges() {
    final routeId = _selectedRouteId;
    if (routeId == null) return;
    context.read<DriverAssignedRoutesBloc>().add(
      SaveDriverAssignedRoute(driverId: widget.driverId, routeId: routeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('Seleccione la ruta asignada:'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              ..._filteredRoutes.map(
                (route) => _AssignedRouteCard(
                  route: route,
                  isSelected: _selectedRouteId == route.id,
                  onChanged: (value) {
                    if (value) setState(() => _selectedRouteId = route.id);
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '@Buscar una ruta asignada',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.isSaving ? null : _confirmChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC12F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : const Text(
                          'Confirmar Cambios',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignedRouteCard extends StatelessWidget {
  final RouteEntity route;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _AssignedRouteCard({
    required this.route,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final points = _routePoints(route);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFFFC12F),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, size: 38, color: Colors.black87),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Línea: ${route.ref}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        route.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${route.stops?.length ?? 0} paradas · ${points.length} puntos de recorrido',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isSelected,
                  onChanged: onChanged,
                  activeThumbColor: Colors.black,
                  activeTrackColor: Colors.black,
                ),
              ],
            ),
          ),
          if (points.length >= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _RouteMap(route: route, points: points),
            ),
        ],
      ),
    );
  }

  static List<LatLng> _routePoints(RouteEntity route) {
    final source = route.polyline?.isNotEmpty == true
        ? route.polyline!
        : route.stops ?? [];
    return source
        .map((point) => LatLng(point['lat'] ?? 0, point['lng'] ?? 0))
        .where((point) => point.latitude != 0 || point.longitude != 0)
        .toList();
  }
}

class _RouteMap extends StatelessWidget {
  final RouteEntity route;
  final List<LatLng> points;

  const _RouteMap({required this.route, required this.points});

  @override
  Widget build(BuildContext context) {
    final stops = route.stops ?? [];
    final markers = <Marker>{
      for (var index = 0; index < stops.length; index++)
        Marker(
          markerId: MarkerId('${route.id}_stop_$index'),
          position: LatLng(stops[index]['lat'] ?? 0, stops[index]['lng'] ?? 0),
          infoWindow: InfoWindow(title: 'Parada ${index + 1}'),
        ),
    };

    return TripRouteMap(
      initialTarget: points.first,
      polylines: {
        Polyline(
          polylineId: PolylineId('assigned_${route.id}'),
          points: points,
          color: const Color(0xFF111111),
          width: 5,
        ),
      },
      markers: markers,
      boundsPoints: points,
      height: 190,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthLoaded) {
                  context.read<DriverAssignedRoutesBloc>().add(
                    LoadDriverAssignedRoutes(authState.user.uid),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay rutas asignadas a este chofer.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
