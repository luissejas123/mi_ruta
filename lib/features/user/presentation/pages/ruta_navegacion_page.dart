import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/core/utils/location_icon_painter.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_marker_builder_service.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_polyline_builder_service.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_utils_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_bottom_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_summary_sheet.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_top_bar.dart';

class RutaNavegacionPage extends StatelessWidget {
  final OsmRoute route;
  final PlaceResult destination;
  final LatLng? origin;
  final LatLng boardingStop;
  final LatLng alightingStop;
  final List<LatLng> transitSegment;
  final List<LatLng> walkStartPoints;
  final List<LatLng> walkEndPoints;

  const RutaNavegacionPage({
    super.key,
    required this.route,
    required this.destination,
    this.origin,
    required this.boardingStop,
    required this.alightingStop,
    required this.transitSegment,
    required this.walkStartPoints,
    required this.walkEndPoints,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationBloc()
        ..add(
          NavigationStarted(
            origin: origin,
            boardingStop: boardingStop,
            alightingStop: alightingStop,
            destination: destination.latLng,
          ),
        ),
      child: _RutaNavegacionView(
        route: route,
        destination: destination,
        origin: origin,
        boardingStop: boardingStop,
        alightingStop: alightingStop,
        transitSegment: transitSegment,
        walkStartPoints: walkStartPoints,
        walkEndPoints: walkEndPoints,
      ),
    );
  }
}

class _RutaNavegacionView extends StatefulWidget {
  final OsmRoute route;
  final PlaceResult destination;
  final LatLng? origin;
  final LatLng boardingStop;
  final LatLng alightingStop;
  final List<LatLng> transitSegment;
  final List<LatLng> walkStartPoints;
  final List<LatLng> walkEndPoints;

  const _RutaNavegacionView({
    required this.route,
    required this.destination,
    this.origin,
    required this.boardingStop,
    required this.alightingStop,
    required this.transitSegment,
    required this.walkStartPoints,
    required this.walkEndPoints,
  });

  @override
  State<_RutaNavegacionView> createState() => _RutaNavegacionViewState();
}

class _RutaNavegacionViewState extends State<_RutaNavegacionView> {
  static const _navIndexRoutes = 2;

  GoogleMapController? _mapController;
  BitmapDescriptor? _locationIcon;
  late final NavigationBloc _navBloc;

  @override
  void initState() {
    super.initState();
    _navBloc = context.read<NavigationBloc>();
    LocationIconPainter.build().then((icon) {
      if (mounted && icon != null) setState(() => _locationIcon = icon);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _navBloc.add(const NavigationStopped());
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final state = _navBloc.state;
    if (state.currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(state.currentPosition!),
      );
    }
  }

  void _onCameraMove(LatLng newPosition) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(newPosition));
    }
  }

  void _showSummarySheet(Duration elapsed) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => NavSummarySheet(
        routeName: widget.route.name,
        destination: widget.destination.name,
        elapsed: elapsed,
        onClose: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        // Animar cámara cuando la posición cambia
        if (state.currentPosition != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.currentPosition!),
          );
        }
        // Mostrar resumen cuando llega al destino
        if (state.phase.toString() == 'TripPhase.arrived') {
          _showSummarySheet(state.elapsed);
        }
      },
      child: Scaffold(
        body: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            final polylines = NavigationPolylineBuilderService.buildPolylines(
              phase: state.phase,
              currentPosition: state.currentPosition,
              walkStartPoints: widget.walkStartPoints,
              transitSegment: widget.transitSegment,
              walkEndPoints: widget.walkEndPoints,
            );

            final markers = NavigationMarkerBuilderService.buildMarkers(
              origin: widget.origin,
              boardingStop: widget.boardingStop,
              alightingStop: widget.alightingStop,
              destination: widget.destination.latLng,
              destinationName: widget.destination.name,
              currentPosition: state.currentPosition,
              locationIcon: _locationIcon,
            );

            final remainingMeters =
                NavigationUtilsService.calculateRemainingMeters(
                  phase: state.phase,
                  currentPosition: state.currentPosition,
                  boardingStop: widget.boardingStop,
                  alightingStop: widget.alightingStop,
                  destination: widget.destination.latLng,
                );

            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: widget.origin ?? widget.boardingStop,
                    zoom: 15,
                  ),
                  polylines: polylines,
                  markers: markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                NavTopBar(
                  routeName: widget.route.name,
                  elapsed: DistanceUtils.formatDuration(state.elapsed),
                  onBack: () => Navigator.of(context).pop(),
                ),
                NavBottomPanel(
                  phase: state.phase,
                  routeName: widget.route.name,
                  destinationName: widget.destination.name,
                  remainingMeters: remainingMeters,
                  onFinalize: () => _showSummarySheet(state.elapsed),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _navIndexRoutes,
          onTap: (index) => navigateBottomNav(context, index),
        ),
      ),
    );
  }
}
