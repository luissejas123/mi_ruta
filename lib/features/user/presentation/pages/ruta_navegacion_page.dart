import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/core/utils/location_icon_painter.dart';
import 'package:mi_ruta/core/utils/polyline_utils.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/trip_phase_service.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_bottom_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_summary_sheet.dart';
import 'package:mi_ruta/features/user/presentation/widgets/nav_top_bar.dart';

class RutaNavegacionPage extends StatefulWidget {
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
  State<RutaNavegacionPage> createState() => _RutaNavegacionPageState();
}

class _RutaNavegacionPageState extends State<RutaNavegacionPage> {
  // ─────────────────────────────────────────────────────────────────────
  // Constantes
  // ─────────────────────────────────────────────────────────────────────

  static const _navIndexRoutes = 2;
  static const _advanceThresholdMeters = 50.0;
  static const _transitColor = Color(0xFFFBC02D);

  // ─────────────────────────────────────────────────────────────────────
  // Estado
  // ─────────────────────────────────────────────────────────────────────

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  LatLng? _currentPosition;
  late TripPhase _phase;
  late final DateTime _startTime;
  Duration _elapsed = Duration.zero;
  BitmapDescriptor? _locationIcon;

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Inicialización
  // ─────────────────────────────────────────────────────────────────────

  void _initializeNavigation() {
    _startTime = DateTime.now();
    _phase = widget.origin != null ? TripPhase.walkStart : TripPhase.onBus;
    _startTracking();
    _startTimer();
    LocationIconPainter.build().then((icon) {
      if (mounted && icon != null) setState(() => _locationIcon = icon);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_startTime));
    });
  }

  Future<void> _startTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final initial = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(initial.latitude, initial.longitude);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Lógica de Navegación
  // ─────────────────────────────────────────────────────────────────────

  void _onPositionUpdate(Position pos) {
    if (!mounted) return;
    final current = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentPosition = current);
    _mapController?.animateCamera(CameraUpdate.newLatLng(current));
    _checkPhaseAdvance(current);
  }

  void _checkPhaseAdvance(LatLng current) {
    final newPhase = TripPhaseService.advance(
      current: _phase,
      position: current,
      boardingStop: widget.boardingStop,
      alightingStop: widget.alightingStop,
      destination: widget.destination.latLng,
      threshold: _advanceThresholdMeters,
    );
    if (newPhase != _phase) {
      setState(() => _phase = newPhase);
      if (newPhase == TripPhase.arrived) _showSummarySheet();
    }
  }

  double _distBetween(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );

  double _remainingMeters() {
    if (_currentPosition == null) return 0;
    switch (_phase) {
      case TripPhase.walkStart:
        return _distBetween(_currentPosition!, widget.boardingStop);
      case TripPhase.onBus:
        return _distBetween(_currentPosition!, widget.alightingStop);
      case TripPhase.walkEnd:
      case TripPhase.arrived:
        return _distBetween(_currentPosition!, widget.destination.latLng);
    }
  }

  void _showSummarySheet() {
    _timer?.cancel();
    _positionSubscription?.cancel();
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
        elapsed: _elapsed,
        onClose: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Polylines y Markers
  // ─────────────────────────────────────────────────────────────────────

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    final pos = _currentPosition;

    if (_phase == TripPhase.walkStart &&
        widget.origin != null &&
        widget.walkStartPoints.isNotEmpty) {
      final pts = pos != null
          ? PolylineUtils.trimToPosition(widget.walkStartPoints, pos)
          : widget.walkStartPoints;
      if (pts.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('walk_start'),
            points: pts,
            color: Colors.grey.shade700,
            width: 4,
            patterns: [PatternItem.dash(16), PatternItem.gap(12)],
          ),
        );
      }
    }

    if (widget.transitSegment.isNotEmpty &&
        (_phase == TripPhase.walkStart || _phase == TripPhase.onBus)) {
      final pts = (_phase == TripPhase.onBus && pos != null)
          ? PolylineUtils.trimToPosition(widget.transitSegment, pos)
          : widget.transitSegment;
      if (pts.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('transit'),
            points: pts,
            color: _transitColor,
            width: 6,
          ),
        );
      }
    }

    if (widget.walkEndPoints.isNotEmpty && _phase != TripPhase.arrived) {
      final pts = (_phase == TripPhase.walkEnd && pos != null)
          ? PolylineUtils.trimToPosition(widget.walkEndPoints, pos)
          : widget.walkEndPoints;
      if (pts.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('walk_end'),
            points: pts,
            color: Colors.grey.shade700,
            width: 4,
            patterns: [PatternItem.dash(16), PatternItem.gap(12)],
          ),
        );
      }
    }

    return polylines;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Tu origen'),
        ),
      );
    }
    markers.add(
      Marker(
        markerId: const MarkerId('boarding'),
        position: widget.boardingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: '🚌 Subir aquí'),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('alighting'),
        position: widget.alightingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: '🔔 Bajar aquí'),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: widget.destination.name),
      ),
    );
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentPosition!,
          icon:
              _locationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 10,
        ),
      );
    }

    return markers;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: CameraPosition(
              target: widget.origin ?? widget.boardingStop,
              zoom: 15,
            ),
            polylines: _buildPolylines(),
            markers: _buildMarkers(),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          NavTopBar(
            routeName: widget.route.name,
            elapsed: DistanceUtils.formatDuration(_elapsed),
            onBack: () => Navigator.of(context).pop(),
          ),
          NavBottomPanel(
            phase: _phase,
            routeName: widget.route.name,
            destinationName: widget.destination.name,
            remainingMeters: _remainingMeters(),
            onFinalize: _showSummarySheet,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndexRoutes,
        onTap: (index) => navigateBottomNav(context, index),
      ),
    );
  }
}
