import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_routes_bloc.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_routes_event.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_routes_state.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_location_picker_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

/// "Paradas cercanas": no hay registros de paradas GTFS reales sembrados
/// (ver `RouteLocalDatabase.getRoutesNearPoint`), así que en vez de buscar
/// paradas puntuales se busca qué rutas/trufis pasan dentro del radio
/// elegido — la intersección ruta↔radio contra las polylines ya
/// sincronizadas offline.
class ParadasCercanasPage extends StatefulWidget {
  const ParadasCercanasPage({super.key});

  @override
  State<ParadasCercanasPage> createState() => _ParadasCercanasPageState();
}

class _ParadasCercanasPageState extends State<ParadasCercanasPage> {
  static const _radiusOptions = [250.0, 500.0];

  final _locationDatasource = LocationDatasource();
  late final NearbyRoutesBloc _bloc;
  double _radiusMeters = 500;
  LatLng? _customOrigin;

  @override
  void initState() {
    super.initState();
    _bloc = NearbyRoutesBloc(syncService: getIt<RouteDataSyncService>());
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    LatLng origin;
    if (_customOrigin != null) {
      origin = _customOrigin!;
    } else {
      final result = await _locationDatasource.getCurrentLocation();
      origin = LatLng(result.location.latitude, result.location.longitude);
    }
    _bloc.add(LoadNearbyRoutes(
      origin.latitude,
      origin.longitude,
      radiusMeters: _radiusMeters,
    ));
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerPage(
          title: 'Buscar trufis desde aquí',
          initialLocation: _customOrigin,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _customOrigin = result.latLng);
    _loadNearby();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Paradas cercanas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Text('Radio:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 10),
                  for (final r in _radiusOptions) ...[
                    ChoiceChip(
                      label: Text('${r.toInt()} m'),
                      selected: _radiusMeters == r,
                      selectedColor: const Color(0xFFFFC12F).withValues(alpha: 0.35),
                      onSelected: (_) {
                        setState(() => _radiusMeters = r);
                        _loadNearby();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickOnMap,
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('Elegir ubicación en el mapa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            if (_customOrigin != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Buscando desde el punto elegido en el mapa',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _customOrigin = null);
                        _loadNearby();
                      },
                      child: const Text('Usar mi ubicación', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<NearbyRoutesBloc, NearbyRoutesState>(
                builder: (context, state) {
                  if (state is NearbyRoutesLoading || state is NearbyRoutesInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
                    );
                  }
                  if (state is NearbyRoutesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(state.message, textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  final loaded = state as NearbyRoutesLoaded;
                  if (loaded.routes.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: loaded.routes.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final (route, distance) = loaded.routes[i];
                      return _RouteCard(route: route, distanceMeters: distance);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteEntity route;
  final double distanceMeters;

  const _RouteCard({required this.route, required this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Sin onTap a un "detalle de parada": no hay una pantalla de detalle de
    // ruta que muestre datos reales (la única existente, StopDetailPage, usa
    // RouteStopInfo con campos fijos como "Tráfico moderado" — justo lo que
    // el CLAUDE.md del repo prohíbe simular). La tarjeta queda informativa.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC12F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_filled_outlined,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Línea ${route.ref} · ${route.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Pasa a ${DistanceUtils.formatMeters(distanceMeters)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_filled_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Ningún trufi cerca',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No encontramos rutas que pasen cerca\nde tu ubicación actual en este radio',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
