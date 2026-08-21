import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/stops/domain/entities/bus_stop_entity.dart';
import 'package:mi_ruta/features/stops/domain/services/bus_stop_service.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_stops_bloc.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_stops_event.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_stops_state.dart';
import 'package:mi_ruta/features/stops/presentation/pages/parada_detalle_page.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';

class ParadasCercanasPage extends StatefulWidget {
  const ParadasCercanasPage({super.key});

  @override
  State<ParadasCercanasPage> createState() => _ParadasCercanasPageState();
}

class _ParadasCercanasPageState extends State<ParadasCercanasPage> {
  final _locationDatasource = LocationDatasource();
  late final NearbyStopsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = NearbyStopsBloc(service: getIt<BusStopService>());
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    final result = await _locationDatasource.getCurrentLocation();
    _bloc.add(LoadNearbyStops(result.location.latitude, result.location.longitude));
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
        body: BlocBuilder<NearbyStopsBloc, NearbyStopsState>(
          builder: (context, state) {
            if (state is NearbyStopsLoading || state is NearbyStopsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
              );
            }
            if (state is NearbyStopsError) {
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
            final loaded = state as NearbyStopsLoaded;
            if (loaded.stops.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loaded.stops.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _StopCard(
                stop: loaded.stops[i],
                originLat: loaded.originLat,
                originLng: loaded.originLng,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final BusStopEntity stop;
  final double originLat;
  final double originLng;

  const _StopCard({
    required this.stop,
    required this.originLat,
    required this.originLng,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final distance = getIt<BusStopService>().distanceLabel(
      stop,
      originLat,
      originLng,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ParadaDetallePage(stop: stop)),
      ),
      child: Container(
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
                Icons.pin_drop_outlined,
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
                    stop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (stop.routeRefs.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stop.routeRefs
                          .take(8)
                          .map((ref) => _RefChip(ref: ref))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefChip extends StatelessWidget {
  final String ref;
  const _RefChip({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC12F).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ref,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFC12F),
        ),
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
            Icons.pin_drop_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin paradas cercanas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No encontramos paradas de bus\ncerca de tu ubicación actual',
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
