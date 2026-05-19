import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/user/data/datasources/walking_routes_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/trip_segment_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_navegacion_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_route_map.dart';
import 'package:mi_ruta/features/user/presentation/widgets/trip_summary_view.dart';

class RutaLineaPage extends StatefulWidget {
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
  State<RutaLineaPage> createState() => _RutaLineaPageState();
}

class _RutaLineaPageState extends State<RutaLineaPage> {
  // ─────────────────────────────────────────────────────────────────────
  // Constantes
  // ─────────────────────────────────────────────────────────────────────

  static const _navIndexRoutes = 2;
  static const _transitColor = Color(0xFFFBC02D);
  static const _bgColor = Color(0xFFF1F3F4);

  // ─────────────────────────────────────────────────────────────────────
  // Estado
  // ─────────────────────────────────────────────────────────────────────

  late final LatLng _boardingStop;
  late final LatLng _alightingStop;
  late final List<LatLng> _transitSegment;

  List<LatLng> _walkStartPoints = [];
  List<LatLng> _walkEndPoints = [];

  final _walkingDatasource = WalkingRoutesDatasource();

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeSegment();
    _loadWalkingRoutes();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Inicialización
  // ─────────────────────────────────────────────────────────────────────

  void _initializeSegment() {
    final origin = widget.origin ?? widget.destination.latLng;
    final segment = TripSegmentService.compute(
      route: widget.route,
      origin: origin,
      destination: widget.destination.latLng,
    );
    _boardingStop = segment.boardingStop;
    _alightingStop = segment.alightingStop;
    _transitSegment = segment.transitPoints;
  }

  Future<void> _loadWalkingRoutes() async {
    final futures = <Future<List<LatLng>>>[];
    if (widget.origin != null) {
      futures.add(_walkingDatasource.fetchRoute(widget.origin!, _boardingStop));
    }
    futures.add(
      _walkingDatasource.fetchRoute(_alightingStop, widget.destination.latLng),
    );

    final results = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      if (widget.origin != null) {
        _walkStartPoints = results[0];
        _walkEndPoints = results[1];
      } else {
        _walkEndPoints = results[0];
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Navegación
  // ─────────────────────────────────────────────────────────────────────

  void _navigateToNavegacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RutaNavegacionPage(
          route: widget.route,
          destination: widget.destination,
          origin: widget.origin,
          boardingStop: _boardingStop,
          alightingStop: _alightingStop,
          transitSegment: _transitSegment,
          walkStartPoints: _walkStartPoints,
          walkEndPoints: _walkEndPoints,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Polylines y Markers
  // ─────────────────────────────────────────────────────────────────────

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    if (_transitSegment.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('transit'),
          points: _transitSegment,
          color: _transitColor,
          width: 6,
        ),
      );
    }

    if (widget.origin != null) {
      final pts = _walkStartPoints.isNotEmpty
          ? _walkStartPoints
          : [widget.origin!, _boardingStop];
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

    final walkEndPts = _walkEndPoints.isNotEmpty
        ? _walkEndPoints
        : [_alightingStop, widget.destination.latLng];
    polylines.add(
      Polyline(
        polylineId: const PolylineId('walk_end'),
        points: walkEndPts,
        color: Colors.grey.shade700,
        width: 4,
        patterns: [PatternItem.dash(16), PatternItem.gap(12)],
      ),
    );

    return polylines;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origen'),
          position: widget.origin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: '📍 Punto de partida'),
        ),
      );
    }
    markers.add(
      Marker(
        markerId: const MarkerId('boarding'),
        position: _boardingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: '🚌 Subir aquí'),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('alighting'),
        position: _alightingStop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: '🔔 Bajar aquí'),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('destino'),
        position: widget.destination.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: '🏁 ${widget.destination.name}'),
      ),
    );

    return markers;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Construcción de Widgets
  // ─────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    title: Text(widget.route.name, style: const TextStyle(color: Colors.black)),
  );

  Widget _buildSummary() {
    final walkStartDist = widget.origin != null
        ? DistanceUtils.metersApprox(widget.origin!, _boardingStop)
        : 0.0;
    final walkEndDist = DistanceUtils.metersApprox(
      _alightingStop,
      widget.destination.latLng,
    );
    return TripSummaryView(
      walkStartSublabel: widget.origin != null
          ? DistanceUtils.formatMeters(walkStartDist)
          : 'Desde tu ubicación',
      busLabel: widget.route.ref.isNotEmpty
          ? 'Línea ${widget.route.ref}  •  ${widget.route.name}'
          : widget.route.name,
      walkEndSublabel: DistanceUtils.formatMeters(walkEndDist),
      destinationName: widget.destination.name,
    );
  }

  Widget _buildBoardButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _navigateToNavegacion,
      style: ElevatedButton.styleFrom(
        backgroundColor: _transitColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Abordar línea',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              TripRouteMap(
                initialTarget: _boardingStop,
                polylines: _buildPolylines(),
                markers: _buildMarkers(),
                boundsPoints: [
                  if (widget.origin != null) widget.origin!,
                  ..._transitSegment,
                  widget.destination.latLng,
                ],
              ),
              const SizedBox(height: 16),
              _buildSummary(),
              const Spacer(),
              _buildBoardButton(),
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
}
