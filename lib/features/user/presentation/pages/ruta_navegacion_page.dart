import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/core/utils/location_icon_painter.dart';
import 'package:mi_ruta/features/routes/domain/services/tariff_service.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_marker_builder_service.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_polyline_builder_service.dart';
import 'package:mi_ruta/features/user/domain/services/navigation_utils_service.dart';
import 'package:mi_ruta/features/user/domain/services/pago_qr_utils_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';
import 'package:mi_ruta/features/user/domain/services/trip_payment_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/navigation_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/services/trip_history_service.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
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
  // Abordaje ya confirmado en ConfirmarAbordajePage antes de llegar acá
  // (Bloque 2, paso 3, rediseño 2026-09-14) — habilita "Aviso de bajada"
  // desde el inicio, sin depender de ninguna fase de navegación.
  final String? initialBoardingTripId;
  final String? initialBoardingDriverId;
  final String? initialBoardingRouteRef;

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
    this.initialBoardingTripId,
    this.initialBoardingDriverId,
    this.initialBoardingRouteRef,
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
            initialBoardingTripId: initialBoardingTripId,
            initialBoardingDriverId: initialBoardingDriverId,
            initialBoardingRouteRef: initialBoardingRouteRef,
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
  GoogleMapController? _mapController;
  BitmapDescriptor? _locationIcon;
  late final NavigationBloc _navBloc;

  bool _followUser = true;
  bool _isProgrammaticMove = false;
  bool _chargingFare = false;
  bool _payingViaQr = false;
  // tripId del abordaje pendiente de cerrar sin cobro si el pago por QR
  // (segunda opción de "Aviso de bajada") resulta exitoso.
  String? _pendingQrBoardingTripId;

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

  /// Punto de entrada de "Aviso de bajada": calcula la tarifa por distancia
  /// recorrida y deja elegir entre cobrarla directo o pagar escaneando el QR
  /// del chofer (el mismo mecanismo de Billetera → "Pagar viaje"). El QR es
  /// redundante — el viaje ya quedó identificado al abordar, en
  /// `ConfirmarAbordajePage` — pero se ofrece igual porque le da al
  /// pasajero la sensación de control total sobre su propio cobro.
  Future<void> _onAvisoDeBajadaPressed() async {
    if (_chargingFare || _payingViaQr) return;
    final navState = _navBloc.state;
    final tripId = navState.boardingTripId;
    final driverId = navState.boardingDriverId;
    final routeRef = navState.boardingRouteRef;
    if (tripId == null || driverId == null || routeRef == null) return;

    final position = navState.currentPosition;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación actual.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double fare;
    try {
      final traveledMeters = DistanceUtils.distanceAlongPolylineMeters(
        position,
        widget.transitSegment,
      );
      fare = await getIt<TariffService>().resolveFareForDistance(
        routeRef,
        traveledMeters / 1000,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo calcular la tarifa: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    final choice = await showModalBottomSheet<_AvisoBajadaChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AvisoBajadaSheet(fare: fare),
    );
    if (choice == null || !mounted) return;

    if (choice == _AvisoBajadaChoice.distance) {
      await _chargeByDistance(fare: fare, tripId: tripId, driverId: driverId);
    } else {
      await _payViaQr(
        tripId: tripId,
        driverId: driverId,
        routeName: widget.route.name,
        fare: fare,
      );
    }
  }

  /// Cobra directo la tarifa ya calculada por distancia recorrida — misma
  /// lógica que ya usa `DriverService.notifyStop`/`distanceToPolylineMeters`
  /// para GPS, pero acumulando distancia recorrida en vez de solo cercanía.
  Future<void> _chargeByDistance({
    required double fare,
    required String tripId,
    required String driverId,
  }) async {
    setState(() => _chargingFare = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthLoaded) {
        throw Exception('Sesión no válida.');
      }

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

  /// Avisa al chofer (notificación con el mismo `tripId` del abordaje +
  /// monto ya calculado) y abre el escáner — mismo flujo/formato que
  /// `PagoQRPage` en Billetera ("driverId|tripId|amount"), pero el QR que
  /// el chofer va a mostrar sale de esa notificación (`NotificacionesPage`
  /// → "Mostrar QR"), no de un cobro nuevo: es el MISMO viaje de abordaje,
  /// no uno desconectado. El resultado llega vía `TripPaymentBLoC`
  /// (singleton de app), escuchado en `build()`.
  Future<void> _payViaQr({
    required String tripId,
    required String driverId,
    required String routeName,
    required double fare,
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) return;

    try {
      await getIt<NotificationService>().saveDropOffPaymentRequestNotification(
        driverId,
        tripId: tripId,
        amount: fare,
        passengerName: authState.user.fullName,
        routeName: routeName,
      );
    } catch (_) {
      // No bloquea el flujo si la notificación falla — el chofer puede
      // enterarse igual si el pasajero le avisa de palabra.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avisamos al chofer. Escaneá su QR cuando te lo muestre.'),
        backgroundColor: Colors.blue,
      ),
    );

    final qrResult = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(title: 'Escanear QR del chofer'),
      ),
    );
    if (!mounted || !PagoQRUtilsService.isValidQrResult(qrResult)) return;

    // Limpia cualquier resultado pegado de una visita anterior a Billetera
    // → Pagar viaje antes de esperar el nuestro (mismo bloc singleton).
    context.read<TripPaymentBLoC>().add(const ClearPaymentEvent());
    setState(() {
      _pendingQrBoardingTripId = tripId;
      _payingViaQr = true;
    });
    context.read<TripPaymentBLoC>().add(
      ProcessPaymentEvent(userId: authState.user.uid, qrData: qrResult!),
    );
  }

  /// Reacciona al resultado de `_payViaQr`. El QR que mostró el chofer
  /// codifica el MISMO `tripId` del abordaje (ver
  /// `NotificationService.saveDropOffPaymentRequestNotification` +
  /// `NotificacionesPage._showQrDetail`), así que `TripPaymentService`
  /// cobra directo ese viaje — no hace falta cerrar ningún otro por
  /// separado. `state.tripId` se compara contra el que esperábamos por si
  /// llega un resultado de otro pago desconectado (mismo bloc singleton).
  void _onQrPaymentResult(TripPaymentState state) {
    final expectedTripId = _pendingQrBoardingTripId;
    if (!_payingViaQr || expectedTripId == null) return;

    if (state is TripPaymentSuccess && state.tripId != expectedTripId) {
      return;
    }

    if (state is TripPaymentSuccess) {
      setState(() {
        _payingViaQr = false;
        _pendingQrBoardingTripId = null;
      });
      _navBloc.add(FareCharged(state.amount));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cobrado Bs. ${state.amount.toStringAsFixed(2)} por QR'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is TripPaymentError) {
      setState(() {
        _payingViaQr = false;
        _pendingQrBoardingTripId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo procesar el QR: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
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
    return MultiBlocListener(
      listeners: [
        BlocListener<NavigationBloc, NavigationState>(
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
        ),
        // Resultado del pago por QR desde "Aviso de bajada" (segunda opción,
        // ver _payViaQr). `listenWhen` evita reaccionar a un pago de QR sin
        // relación disparado en otra pantalla — TripPaymentBLoC es singleton.
        BlocListener<TripPaymentBLoC, TripPaymentState>(
          listenWhen: (_, _) => _payingViaQr,
          listener: (context, state) => _onQrPaymentResult(state),
        ),
      ],
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
                if (state.boardingTripId != null)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 78),
                        child: _BoardingBanner(
                          farePaid: state.farePaid,
                          chargingFare: _chargingFare || _payingViaQr,
                          onAvisoDeBajada: _onAvisoDeBajadaPressed,
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
      ),
    );
  }
}

/// Banner de cobro por distancia — visible desde el inicio de la navegación
/// (el abordaje ya se confirmó antes, en `ConfirmarAbordajePage`). Dos
/// estados: sin cobrar todavía (botón "Aviso de bajada") o ya cobrado (chip
/// de confirmación).
class _BoardingBanner extends StatelessWidget {
  final double? farePaid;
  final bool chargingFare;
  final VoidCallback onAvisoDeBajada;

  const _BoardingBanner({
    required this.farePaid,
    required this.chargingFare,
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

enum _AvisoBajadaChoice { distance, qr }

/// Elegir cómo pagar al avisar que bajás: por distancia recorrida (ya
/// calculada) o escaneando el QR de cobro del chofer — mismo mecanismo que
/// Billetera → "Pagar viaje". El QR es redundante (el viaje ya quedó
/// identificado al abordar), pero se ofrece para que el pasajero sienta que
/// tiene control total sobre su propio cobro.
class _AvisoBajadaSheet extends StatelessWidget {
  final double fare;

  const _AvisoBajadaSheet({required this.fare});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Cómo querés pagar tu viaje?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tarifa calculada por la distancia recorrida: '
              'Bs. ${fare.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, _AvisoBajadaChoice.distance),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: Text('Pagar Bs. ${fare.toStringAsFixed(2)} (por distancia)'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, _AvisoBajadaChoice.qr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear QR del chofer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
