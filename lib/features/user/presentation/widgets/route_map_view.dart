import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMapView extends StatefulWidget {
  final LatLng initialPosition;
  final String title;

  const RouteMapView({
    super.key,
    this.title = 'Mi ruta',
    this.initialPosition = const LatLng(-17.391032, -66.1568),
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(
            target: widget.initialPosition,
            zoom: 13.5,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('route_center'),
              position: widget.initialPosition,
              infoWindow: InfoWindow(title: widget.title),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
