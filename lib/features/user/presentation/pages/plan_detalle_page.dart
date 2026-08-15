import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';
import 'package:mi_ruta/features/routes/domain/services/gtfs_schedule_service.dart';
import 'package:mi_ruta/features/routes/domain/services/planned_trip_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_entity_converter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_history_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_segment_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';

class PlanDetallePage extends StatefulWidget {
  final PlannedTrip trip;
  final String userId;

  const PlanDetallePage({super.key, required this.trip, required this.userId});

  @override
  State<PlanDetallePage> createState() => _PlanDetallePageState();
}

class _PlanDetallePageState extends State<PlanDetallePage> {
  int _currentLeg = 0;
  bool _isLoading = false;
  final List<bool> _completedLegs = [];

  // Real polyline points per leg loaded from GTFS (null = not loaded yet)
  final List<List<LatLng>?> _legPolylines = [];

  // Upcoming departures (RQ-36)
  List<Map<String, dynamic>> _departures = [];
  bool _isLoadingDepartures = false;

  @override
  void initState() {
    super.initState();
    _completedLegs.addAll(List.filled(widget.trip.legs.length, false));
    _legPolylines.addAll(List.filled(widget.trip.legs.length, null));
    _loadPolylines();
    _loadUpcomingDepartures();
  }

  /// Loads upcoming departures for the first bus leg's boarding point (RQ-36).
  Future<void> _loadUpcomingDepartures() async {
    final busLegs = widget.trip.busLegs;
    if (busLegs.isEmpty) return;

    setState(() => _isLoadingDepartures = true);

    try {
      final service = getIt<GtfsScheduleService>();

      final nearest = await service.resolveNearestStop(
        busLegs.first.boardingPoint,
      );
      if (nearest == null) {
        if (mounted) setState(() => _isLoadingDepartures = false);
        return;
      }

      final departures = await service.getUpcomingDepartures(
        stopId: nearest['stop_id'] ?? '',
        now: DateTime.now(),
      );

      if (!mounted) return;
      setState(() {
        _departures = departures;
        _isLoadingDepartures = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDepartures = false);
    }
  }

  /// Loads real transit polylines for each leg in the background so the
  /// overview map shows the actual bus route instead of a straight line.
  Future<void> _loadPolylines() async {
    final syncService = getIt<RouteDataSyncService>();
    await syncService.ensureDataReady();

    for (int i = 0; i < widget.trip.legs.length; i++) {
      final leg = widget.trip.legs[i];
      final isLast = i == widget.trip.legs.length - 1;
      final dest = isLast ? widget.trip.destinationLatLng : leg.alightingPoint;

      try {
        final osmRoute = await _findRouteForLeg(leg, dest, syncService);
        if (osmRoute == null) continue;

        final seg = TripSegmentService.compute(
          route: osmRoute,
          origin: leg.boardingPoint,
          destination: dest,
        );

        if (seg.transitPoints.isNotEmpty && mounted) {
          setState(() => _legPolylines[i] = seg.transitPoints);
        }
      } catch (_) {
        // Leave null — map falls back to straight line for this leg
      }
    }
  }

  /// Finds the OsmRoute for a leg by searching near both endpoints and using
  /// RouteFinderService so the correct direction (ida/vuelta) is selected.
  Future<OsmRoute?> _findRouteForLeg(
    PlannedTripLeg leg,
    LatLng dest,
    RouteDataSyncService syncService,
  ) async {
    final results = await Future.wait([
      syncService.getRoutesNearPoint(
        latitude: leg.boardingPoint.latitude,
        longitude: leg.boardingPoint.longitude,
      ),
      syncService.getRoutesNearPoint(
        latitude: dest.latitude,
        longitude: dest.longitude,
      ),
    ]);

    final entityMap = <String, dynamic>{};
    for (final e in results[0]) {
      entityMap[e.id] = e;
    }
    for (final e in results[1]) {
      entityMap.putIfAbsent(e.id, () => e);
    }

    final entities = entityMap.values.toList();
    final osmRoutes = <OsmRoute>[
      for (int i = 0; i < entities.length; i++)
        RouteEntityConverter.toOsmRoute(entities[i], i),
    ];

    final matches = RouteFinderService.findForTrip(
      origin: leg.boardingPoint,
      destination: dest,
      routes: osmRoutes,
      maxWalkMeters: 1200,
      maxResults: 10,
    );

    // 1. Exact match: same ref + same direction
    for (final m in matches) {
      if (m.route.ref == leg.routeRef &&
          m.route.directionId == leg.directionId) {
        return m.route;
      }
    }
    // 2. Same ref (any direction) or same display name
    for (final m in matches) {
      if (m.route.ref == leg.routeRef || m.route.name == leg.routeName) {
        return m.route;
      }
    }
    // 3. Best scored match
    return matches.isNotEmpty ? matches.first.route : null;
  }

  bool get _allLegsCompleted => _completedLegs.every((c) => c);

  /// Finds the next bus leg at or after [from], skipping walking legs.
  int _nextBusLeg(int from) {
    for (int i = from; i < widget.trip.legs.length; i++) {
      if (widget.trip.legs[i].isBus) return i;
    }
    return widget.trip.legs.length;
  }

  Future<void> _startLeg(int legIndex) async {
    final leg = widget.trip.legs[legIndex];

    // Find the destination: the alighting point of THIS bus leg, or
    // final dest if it's the last bus leg.
    final busLegs = widget.trip.busLegs;
    final busIdx = busLegs.indexWhere(
      (b) => b.boardingPoint == leg.boardingPoint && b.routeRef == leg.routeRef,
    );
    final isLastBus = busIdx == busLegs.length - 1;
    final actualDest = isLastBus
        ? widget.trip.destinationLatLng
        : leg.alightingPoint;

    setState(() => _isLoading = true);

    try {
      final syncService = getIt<RouteDataSyncService>();
      await syncService.ensureDataReady();

      final matchedRoute = await _findRouteForLeg(leg, actualDest, syncService);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (matchedRoute == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar la ruta. Intenta de nuevo.'),
          ),
        );
        return;
      }

      // Label for the destination shown in navigation
      final nextBusAfter = _nextBusLeg(legIndex + 1);
      final destName = isLastBus
          ? widget.trip.destinationName
          : nextBusAfter < widget.trip.legs.length
          ? 'Transbordo — ${widget.trip.legs[nextBusAfter].routeName}'
          : widget.trip.destinationName;

      final destination = PlaceResult(latLng: actualDest, name: destName);

      // Determine originName: first bus leg uses trip origin, rest use Transbordo
      final isBusLegFirst = busIdx == 0;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RutaLineaPage(
            route: matchedRoute,
            destination: destination,
            origin: leg.boardingPoint,
            originName: isBusLegFirst ? widget.trip.originName : 'Transbordo',
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        // Mark this bus leg and any preceding walking legs as completed
        _completedLegs[legIndex] = true;
        // Advance _currentLeg past any immediately following walking legs
        int next = legIndex + 1;
        // mark preceding walk legs (between previous bus and this one) done
        for (int i = legIndex - 1; i >= 0; i--) {
          if (widget.trip.legs[i].isWalking) {
            _completedLegs[i] = true;
          } else {
            break;
          }
        }
        // Advance to the next bus leg (skip walk legs, they'll be shown as done)
        _currentLeg = _nextBusLeg(next);
        // Also mark intermediate walk legs as completed up to next bus
        for (int i = next; i < _currentLeg; i++) {
          _completedLegs[i] = true;
        }
      });

      if (_allLegsCompleted) await _finishTrip();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _finishTrip() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) return;
    final userId = authState.user.uid;

    await getIt<TripHistoryService>().saveTrip(
      userId: userId,
      routeName: widget.trip.routesSummary,
      originName: widget.trip.originName,
      destinationName: widget.trip.destinationName,
      elapsed: Duration(minutes: widget.trip.totalMinutes),
      farePaid: widget.trip.totalCostBs,
    );

    final notifService = getIt<NotificationService>();
    await notifService.saveTripNotification(userId, widget.trip.routesSummary);
    if (notifService.shouldGiveGift()) {
      final discount = await notifService.saveGiftNotification(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎁 ¡Recibiste un $discount% de descuento!'),
            backgroundColor: const Color(0xFFFFC12F),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    await getIt<PlannedTripService>().markCompleted(userId, widget.trip.id);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Viaje completado!'),
          content: Text(
            'Completaste tu viaje planificado:\n${widget.trip.routesSummary}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFFFC12F)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final colorScheme = Theme.of(context).colorScheme;
    final trip = widget.trip;

    final allPoints = [
      trip.originLatLng,
      trip.destinationLatLng,
      ...trip.legs.map((l) => l.boardingPoint),
      ...trip.legs.map((l) => l.alightingPoint),
    ];
    final lats = allPoints.map((p) => p.latitude).toList()..sort();
    final lngs = allPoints.map((p) => p.longitude).toList()..sort();
    final midLat = (lats.first + lats.last) / 2;
    final midLng = (lngs.first + lngs.last) / 2;

    final polylines = <Polyline>{};
    final markers = <Marker>{};

    for (int i = 0; i < trip.legs.length; i++) {
      final leg = trip.legs[i];
      final isCompleted = _completedLegs[i];
      final isActive = i == _currentLeg;
      final color = isActive
          ? const Color(0xFFFFC12F)
          : isCompleted
          ? Colors.blueGrey
          : Colors.blueGrey.withValues(alpha: 0.5);

      // Use real transit points when loaded; fall back to straight line
      final pts = _legPolylines[i];
      final polylinePoints = (pts != null && pts.length >= 2)
          ? pts
          : [leg.boardingPoint, leg.alightingPoint];

      polylines.add(
        Polyline(
          polylineId: PolylineId('leg_$i'),
          points: polylinePoints,
          color: color,
          width: isActive ? 5 : 3,
          patterns: isCompleted
              ? [PatternItem.dash(10), PatternItem.gap(6)]
              : [],
        ),
      );

      markers.add(
        Marker(
          markerId: MarkerId('board_$i'),
          position: leg.boardingPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isActive ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueCyan,
          ),
          infoWindow: InfoWindow(title: 'Abordar ${leg.routeName}'),
        ),
      );
    }

    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: trip.destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: trip.destinationName),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Detalle del plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Map
          SizedBox(
            height: 220,
            child: GoogleMap(
              style: isDark ? MapStyles.dark : null,
              initialCameraPosition: CameraPosition(
                target: LatLng(midLat, midLng),
                zoom: 13,
              ),
              polylines: polylines,
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          // Trip summary header
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.routesSummary,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.originName} → ${trip.destinationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _InfoChip(
                  label: '${trip.totalMinutes} min',
                  icon: Icons.access_time,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'Bs ${trip.totalCostBs.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Upcoming departures (RQ-36)
          _UpcomingDeparturesCard(
            departures: _departures,
            isLoading: _isLoadingDepartures,
          ),

          // Legs list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trip.legs.length,
              itemBuilder: (context, i) {
                final leg = trip.legs[i];
                if (leg.isWalking) {
                  return _WalkCard(leg: leg, isCompleted: _completedLegs[i]);
                }
                return _LegCard(
                  leg: leg,
                  legIndex: i,
                  busIndex: trip.legs.take(i + 1).where((l) => l.isBus).length,
                  totalBusLegs: trip.busLegs.length,
                  isActive: i == _currentLeg,
                  isCompleted: _completedLegs[i],
                  isLoading: _isLoading && i == _currentLeg,
                  onStart: () => _startLeg(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC12F).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFFC12F)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFC12F),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming departures card (RQ-36) ─────────────────────────────────────────

class _UpcomingDeparturesCard extends StatelessWidget {
  final List<Map<String, dynamic>> departures;
  final bool isLoading;

  const _UpcomingDeparturesCard({
    required this.departures,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: const Color(0xFFFFC12F)),
              const SizedBox(width: 8),
              Text(
                'Próximas salidas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFC12F),
                  ),
                ),
              ),
            )
          else if (departures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No hay salidas próximas para esta parada.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ...departures.map((d) => _DepartureRow(departure: d)),
        ],
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final Map<String, dynamic> departure;

  const _DepartureRow({required this.departure});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = departure['time'] ?? '--:--';
    final routeId = departure['route_id'] ?? '—';
    final headsign = departure['trip_headsign'] ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC12F).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$time',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFC12F),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ruta $routeId',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$headsign',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

// ── Bus leg card ─────────────────────────────────────────────────────────────

class _LegCard extends StatelessWidget {
  final PlannedTripLeg leg;
  final int legIndex; // index in full legs list (for _currentLeg tracking)
  final int busIndex; // 1-based index among bus-only legs
  final int totalBusLegs;
  final bool isActive;
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback onStart;

  const _LegCard({
    required this.leg,
    required this.legIndex,
    required this.busIndex,
    required this.totalBusLegs,
    required this.isActive,
    required this.isCompleted,
    required this.isLoading,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = busIndex == totalBusLegs;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFFC12F).withValues(alpha: 0.1)
            : isCompleted
            ? Colors.green.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFC12F).withValues(alpha: 0.5)
              : isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? const Color(0xFFFFC12F)
                  : colorScheme.onSurface.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.directions_bus,
              color: isCompleted || isActive
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.4),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Línea $busIndex — ${leg.routeName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCompleted ? Colors.green : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLast ? '→ Destino final' : '→ Transbordo a siguiente línea',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${leg.estimatedMinutes} min  •  '
                  '${(leg.transitMeters / 1000).toStringAsFixed(1)} km en bus',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                if (isActive && !isCompleted) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC12F),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              busIndex == 1
                                  ? 'Iniciar viaje'
                                  : 'Abordar línea $busIndex',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Walking leg card ──────────────────────────────────────────────────────────

class _WalkCard extends StatelessWidget {
  final PlannedTripLeg leg;
  final bool isCompleted;

  const _WalkCard({required this.leg, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mins = (leg.transitMeters / 80).ceil();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.directions_walk,
            size: 20,
            color: isCompleted
                ? Colors.green
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Text(
            'Caminar ${leg.transitMeters.round()} m  (~$mins min)',
            style: TextStyle(
              fontSize: 12,
              color: isCompleted
                  ? Colors.green
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
