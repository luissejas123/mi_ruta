import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/core/utils/location_icon_painter.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/routes/domain/services/tariff_service.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_marker_builder_service.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_polyline_builder_service.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_utils_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';
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
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';
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
  bool _confirmingBoarding = false;
  bool _chargingFare = false;

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
    Navigator.of(context).pop(false);
  }

  /// Escanea el QR fijo de la unidad (`UnitQrPage`, `ownerUid|vehicleId`)
  /// para confirmar abordaje — habilita "Aviso de bajada" (Bloque 2, paso 3).
  /// Opcional: si el pasajero no escanea, sigue pudiendo navegar y pagar por
  /// el flujo de QR de cobro del chofer como siempre (ambos mecanismos
  /// conviven, no se reemplaza uno por otro).
  Future<void> _confirmBoarding() async {
    if (_confirmingBoarding) return;
    setState(() => _confirmingBoarding = true);
    try {
      final qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const QRScannerPage(title: 'Escanea el QR de la unidad'),
        ),
      );
      if (qrCode == null || qrCode.isEmpty) return;

      final parts = qrCode.split('|');
      if (parts.length != 2) {
        throw Exception(
          'Ese QR no es el de una unidad — escanea el que está pegado en el vehículo.',
        );
      }
      final ownerUid = parts[0];
      final vehicleId = parts[1];

      final driverService = getIt<DriverService>();
      final vehicle = await driverService.getAssignedVehicle(ownerUid);
      if (vehicle == null || vehicle.vehicleId != vehicleId) {
        throw Exception('No se pudo verificar la unidad escaneada.');
      }
      if (!mounted) return;

      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthLoaded) {
        throw Exception('Sesión no válida.');
      }

      final route = await driverService.getAssignedRoute(vehicle);
      final tripId = await driverService.createBoardingTrip(
        vehicle: vehicle,
        passengerId: authState.user.uid,
        route: route,
      );

      if (!mounted) return;
      _navBloc.add(
        BoardingConfirmed(
          tripId: tripId,
          driverId: vehicle.ownerUid,
          routeRef: route?.ref ?? vehicle.lineNumber,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abordaje confirmado.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo confirmar el abordaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmingBoarding = false);
    }
  }

  /// Cobra la tarifa según la distancia recorrida desde que se abordó,
  /// proyectada sobre el tramo de bus (`widget.transitSegment`) — misma
  /// lógica que ya usa `DriverService.notifyStop`/`distanceToPolylineMeters`
  /// para GPS, pero acumulando distancia recorrida en vez de solo cercanía.
  Future<void> _avisoDeBajada() async {
    if (_chargingFare) return;
    final navState = _navBloc.state;
    final tripId = navState.boardingTripId;
    final driverId = navState.boardingDriverId;
    final routeRef = navState.boardingRouteRef;
    if (tripId == null || driverId == null || routeRef == null) return;

    setState(() => _chargingFare = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthLoaded) {
        throw Exception('Sesión no válida.');
      }
      final position = navState.currentPosition;
      if (position == null) {
        throw Exception('No se pudo obtener tu ubicación actual.');
      }

      final traveledMeters = DistanceUtils.distanceAlongPolylineMeters(
        position,
        widget.transitSegment,
      );
      final fare = await getIt<TariffService>().resolveFareForDistance(
        routeRef,
        traveledMeters / 1000,
      );

      final result = await getIt<TripPaymentService>().processDistanceFare(
        userId: authState.user.uid,
        driverId: driverId,
        tripId: tripId,
        amount: fare,
      );
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'No se pudo procesar el cobro.');
      }

      if (!mounted) return;
      _navBloc.add(FareCharged(fare));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cobrado Bs. ${fare.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo procesar el aviso de bajada: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _chargingFare = false);
    }
  }

  bool _tripSaved = false;

  Future<void> _showSummarySheet(Duration elapsed) async {
    if (!mounted) return;
    if (!_tripSaved) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthLoaded) {
        final userId = authState.user.uid;
        try {
          final notifService = getIt<NotificationService>();
          // Si el pasajero escaneó el QR de la unidad y avisó que bajó, usa
          // el monto real ya cobrado; si no, es una estimación por tarifa de
          // línea (ya no el 2.5 fijo de antes) — este historial es personal,
          // no afecta el cobro real (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md,
          // Bloque 2, paso 3).
          double farePaid = _navBloc.state.farePaid ?? 2.5;
          if (_navBloc.state.farePaid == null) {
            try {
              final traveledMeters = widget.transitSegment.isEmpty
                  ? 0.0
                  : DistanceUtils.distanceAlongPolylineMeters(
                      widget.transitSegment.last,
                      widget.transitSegment,
                    );
              farePaid = await getIt<TariffService>().resolveFareForDistance(
                widget.route.ref,
                traveledMeters / 1000,
              );
            } catch (_) {
              // Sin conexión: se queda con el respaldo de arriba.
            }
          }
          await getIt<TripHistoryService>().saveTrip(
            userId: userId,
            routeName: widget.route.name,
            originName: widget.originName,
            destinationName: widget.destination.name,
            elapsed: elapsed,
            farePaid: farePaid,
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
          _tripSaved = true;
        } catch (_) {
          // Sin conexión u otro error: no bloqueamos al usuario por esto —
          // su viaje sí cuenta como completado, solo no se guardó el
          // historial/notificación. _tripSaved queda false para reintentar
          // si el listener vuelve a disparar con phase == arrived.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No se pudo guardar el historial del viaje (sin conexión).',
                ),
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
          Navigator.of(context).pop(true);
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
                if (state.phase == TripPhase.onBus)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 78),
                        child: _BoardingBanner(
                          boardingTripId: state.boardingTripId,
                          farePaid: state.farePaid,
                          confirmingBoarding: _confirmingBoarding,
                          chargingFare: _chargingFare,
                          onConfirmBoarding: _confirmBoarding,
                          onAvisoDeBajada: _avisoDeBajada,
                        ),
                      ),
                    ),
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

/// Banner de abordaje/cobro por distancia mientras `phase == onBus`
/// (Bloque 2, paso 3). Tres estados: sin abordaje confirmado (botón para
/// escanear el QR de la unidad), abordaje confirmado sin cobrar (botón
/// "Aviso de bajada"), o ya cobrado (chip de confirmación).
class _BoardingBanner extends StatelessWidget {
  final String? boardingTripId;
  final double? farePaid;
  final bool confirmingBoarding;
  final bool chargingFare;
  final VoidCallback onConfirmBoarding;
  final VoidCallback onAvisoDeBajada;

  const _BoardingBanner({
    required this.boardingTripId,
    required this.farePaid,
    required this.confirmingBoarding,
    required this.chargingFare,
    required this.onConfirmBoarding,
    required this.onAvisoDeBajada,
  });

  @override
  Widget build(BuildContext context) {
    if (farePaid != null) {
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade600,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cobrado Bs. ${farePaid!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (boardingTripId == null) {
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ElevatedButton.icon(
          onPressed: confirmingBoarding ? null : onConfirmBoarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC12F),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: confirmingBoarding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.qr_code_scanner),
          label: const Text(
            'Escanear QR de la unidad',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: ElevatedButton.icon(
        onPressed: chargingFare ? null : onAvisoDeBajada,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: chargingFare
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout),
        label: const Text(
          'Aviso de bajada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
