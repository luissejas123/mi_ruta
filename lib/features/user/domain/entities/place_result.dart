import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceResult {
  final LatLng latLng;
  final String name;

  const PlaceResult({required this.latLng, required this.name});
}
