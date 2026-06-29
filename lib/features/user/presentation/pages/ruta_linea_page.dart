import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/trip_route_map_builder_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_line_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_line_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_line_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_navegacion_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_route_map.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_summary_view.dart';

class RutaLineaPage extends StatelessWidget {
  final OsmRoute route;
  final PlaceResult destination;
  final LatLng? origin;

  const RutaLineaPage({
    super.key,
    required this.route,
    required this.destination,
    this.origin,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripLineBloc()
        ..add(
          TripLineInitialized(
            route: route,
            destination: destination,
            origin: origin,
          ),
        ),
      child: _RutaLineaView(
        route: route,
        destination: destination,
        origin: origin,
      ),
    );
  }
}

class _RutaLineaView extends StatefulWidget {
  final OsmRoute route;
  final PlaceResult destination;
  final LatLng? origin;

  const _RutaLineaView({
    required this.route,
    required this.destination,
    this.origin,
  });

  @override
  State<_RutaLineaView> createState() => _RutaLineaViewState();
}

class _RutaLineaViewState extends State<_RutaLineaView> {
  static const _navIndexRoutes = 2;
  // ✅ Colores consistentes
  static const _amarillo = Color(0xFFFFC12F);

  void _navigateToNavegacion({
    required LatLng boardingStop,
    required LatLng alightingStop,
    required List<LatLng> transitSegment,
    required List<LatLng> walkStartPoints,
    required List<LatLng> walkEndPoints,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RutaNavegacionPage(
          route: widget.route,
          destination: widget.destination,
          origin: widget.origin,
          boardingStop: boardingStop,
          alightingStop: alightingStop,
          transitSegment: transitSegment,
          walkStartPoints: walkStartPoints,
          walkEndPoints: walkEndPoints,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    elevation: 0,
    title: Text(
      widget.route.name,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildLoadingScaffold() => Scaffold(
    appBar: _buildAppBar(),
    body: const Center(
      child: CircularProgressIndicator(color: _amarillo),
    ),
  );

  Widget _buildSummary({
    required LatLng boardingStop,
    required LatLng alightingStop,
  }) {
    final walkStartDist = widget.origin != null
        ? DistanceUtils.metersApprox(widget.origin!, boardingStop)
        : 0.0;
    final walkEndDist = DistanceUtils.metersApprox(
      alightingStop,
      widget.destination.latLng,
    );
    return TripSummaryView(
      walkStartSublabel: widget.origin != null
          ? DistanceUtils.formatMeters(walkStartDist)
          : 'Desde tu ubicación',
      busLabel: widget.route.ref.isNotEmpty
          ? 'Línea ${widget.route.ref}  •  ${widget.route.displayName}'
          : widget.route.displayName,
      walkEndSublabel: DistanceUtils.formatMeters(walkEndDist),
      destinationName: widget.destination.name,
    );
  }

  Widget _buildBoardButton({
    required LatLng boardingStop,
    required LatLng alightingStop,
    required List<LatLng> transitSegment,
    required List<LatLng> walkStartPoints,
    required List<LatLng> walkEndPoints,
  }) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _navigateToNavegacion(
            boardingStop: boardingStop,
            alightingStop: alightingStop,
            transitSegment: transitSegment,
            walkStartPoints: walkStartPoints,
            walkEndPoints: walkEndPoints,
          ),
          style: ElevatedButton.styleFrom(
            // ✅ Color amarillo consistente
            backgroundColor: _amarillo,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Abordar línea',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripLineBloc, TripLineState>(
      builder: (context, state) {
        if (state is TripLineLoading) {
          return _buildLoadingScaffold();
        }

        if (state is TripLineError) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is TripLineLoaded) {
          final polylines = TripRouteMapBuilderService.buildPolylines(
            tripSegment: state.tripSegment,
            walkingPaths: state.walkingPaths,
            route: widget.route,
            destination: widget.destination,
            origin: widget.origin,
          );

          final markers = TripRouteMapBuilderService.buildMarkers(
            tripSegment: state.tripSegment,
            route: widget.route,
            destination: widget.destination,
            origin: widget.origin,
          );

          final boundsPoints = TripRouteMapBuilderService.getBoundsPoints(
            tripSegment: state.tripSegment,
            destination: widget.destination,
            origin: widget.origin,
          );

          return Scaffold(
            appBar: _buildAppBar(),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    TripRouteMap(
                      initialTarget: state.tripSegment.boardingStop,
                      polylines: polylines,
                      markers: markers,
                      boundsPoints: boundsPoints,
                    ),
                    const SizedBox(height: 16),
                    _buildSummary(
                      boardingStop: state.tripSegment.boardingStop,
                      alightingStop: state.tripSegment.alightingStop,
                    ),
                    const Spacer(),
                    _buildBoardButton(
                      boardingStop: state.tripSegment.boardingStop,
                      alightingStop: state.tripSegment.alightingStop,
                      transitSegment: state.tripSegment.transitPoints,
                      walkStartPoints: state.walkingPaths.startWalkPath,
                      walkEndPoints: state.walkingPaths.endWalkPath,
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: _navIndexRoutes,
              onTap: (index) => navigateBottomNav(context, index),
            ),
          );
        }

        return _buildLoadingScaffold();
      },
    );
  }
}