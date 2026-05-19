import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/utils/map_utils.dart';

/// Mapa interactivo que muestra el trayecto completo de un viaje:
/// caminatas (polylines punteadas) + tramo en bus (polyline sólida) + marcadores.
///
/// Gestiona su propio [GoogleMapController] y encuadra automáticamente
/// todos los [boundsPoints] al crearse el mapa.
class TripRouteMap extends StatefulWidget {
  /// Posición inicial de la cámara (antes de que el auto-fit tome efecto).
  final LatLng initialTarget;

  /// Polylines a renderizar (caminatas + tránsito).
  final Set<Polyline> polylines;

  /// Marcadores a renderizar (origen, parada, bajada, destino).
  final Set<Marker> markers;

  /// Puntos usados para calcular el encuadre automático del mapa.
  final List<LatLng> boundsPoints;

  /// Alto del widget en píxeles lógicos.
  final double height;

  const TripRouteMap({
    super.key,
    required this.initialTarget,
    required this.polylines,
    required this.markers,
    required this.boundsPoints,
    this.height = 260,
  });

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          onMapCreated: (c) {
            _controller = c;
            MapUtils.fitBounds(c, widget.boundsPoints);
          },
          initialCameraPosition: CameraPosition(
            target: widget.initialTarget,
            zoom: 14,
          ),
          polylines: widget.polylines,
          markers: widget.markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
