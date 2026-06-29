import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/core/utils/map_utils.dart';

class TripRouteMap extends StatefulWidget {
  final LatLng initialTarget;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final List<LatLng> boundsPoints;
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
    final isDark = context.watch<ThemeCubit>().state;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          style: isDark ? MapStyles.dark : null,
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
