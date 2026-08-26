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
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_state.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/services/trip_history_service.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_bottom_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_summary_sheet.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_top_bar.dart';

class RutaNavegacionPage extends StatelessWidget {
  final OsmRoute route;
  final PlaceResult destination;
  final LatLng? origin;
  final String originName;
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
    this.originName = 'Mi ubicación',
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
        originName: originName,
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
  final String originName;
  final LatLng boardingStop;
  final LatLng alightingStop;
  final List<LatLng> transitSegment;
  final List<LatLng> walkStartPoints;
  final List<LatLng> walkEndPoints;

  const _RutaNavegacionView({
    required this.route,
    required this.destination,
    this.origin,
    required this.originName,
    required this.boardingStop,
    required this.alightingStop,
    required this.transitSegment,
    required this.walkStartPoints,
    required this.walkEndPoints,
  });

  @override
  State<_RutaNavegacionView> createState() => _RutaNavegacionViewState();
}

class _RutaNavegacionViewState extends State<_RutaNavegacionView>
    with WidgetsBindingObserver {
  static const _navIndexRoutes = 2;

  GoogleMapController? _mapController;
  BitmapDescriptor? _locationIcon;
  late final NavigationBloc _navBloc;

  bool _followUser = true;
  bool _isProgrammaticMove = false;

  @override
  void initState() {
    super.initState();
    _navBloc = context.read<NavigationBloc>();
    WidgetsBinding.instance.addObserver(this);
    LocationIconPainter.build().then((icon) {
      if (mounted && icon != null) setState(() => _locationIcon = icon);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _navBloc.add(const NavigationPaused());
        break;
      case AppLifecycleState.resumed:
        _navBloc.add(const NavigationResumed());
        break;
      case AppLifecycleState.inactive:
        break;
    }
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

  void _onBackPressed() {
    _navBloc.add(const NavigationStopped());
    Navigator.of(context).pop();
  }

  bool _tripSaved = false;

  Future<void> _showSummarySheet(Duration elapsed) async {
    if (!mounted) return;
    if (!_tripSaved) {
      _tripSaved = true;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthLoaded) {
        final userId = authState.user.uid;
        final notifService = getIt<NotificationService>();
        await getIt<TripHistoryService>().saveTrip(
          userId: userId,
          routeName: widget.route.name,
          originName: widget.originName,
          destinationName: widget.destination.name,
          elapsed: elapsed,
          farePaid: 2.5,
        );
        await notifService.saveTripNotification(userId, widget.route.name);
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
      }
    }
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
          _navBloc.add(const NavigationStopped());
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        if (state.currentPosition != null &&
            _mapController != null &&
            _followUser) {
          _isProgrammaticMove = true;
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.currentPosition!),
          );
        }
        // ✅ Comparación directa con enum en vez de toString()
        if (state.phase == TripPhase.arrived) {
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
                  style: isDark ? MapStyles.dark : null,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: widget.origin ?? widget.boardingStop,
                    zoom: 15,
                  ),
                  onCameraMove: (_) {
                    if (!_isProgrammaticMove && _followUser) {
                      setState(() => _followUser = false);
                    }
                  },
                  onCameraIdle: () => _isProgrammaticMove = false,
                  polylines: polylines,
                  markers: markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                NavTopBar(
                  routeName: widget.route.name,
                  elapsed: DistanceUtils.formatDuration(state.elapsed),
                  onBack: _onBackPressed,
                ),
                if (!_followUser)
                  Positioned(
                    right: 16,
                    bottom: 200,
                    child: FloatingActionButton.small(
                      heroTag: 'follow_user',
                      backgroundColor: const Color(0xFFFFC12F),
                      foregroundColor: Colors.black,
                      onPressed: () {
                        setState(() {
                          _followUser = true;
                          _isProgrammaticMove = true;
                        });
                        final pos = _navBloc.state.currentPosition;
                        if (pos != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(pos),
                          );
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
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
