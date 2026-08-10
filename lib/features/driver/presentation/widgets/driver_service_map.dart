import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/core/utils/map_utils.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_location_usecase.dart';

const _amarillo = Color(0xFFFFC12F);

/// Mapa de la unidad del chofer para las vistas de inicio/detener servicio
/// (Figma "3.3 Inicio Servicio" / "3.3 Detener Servicio"): ubicación actual
/// + la ruta asignada dibujada, si el catálogo GTFS tiene su polyline.
class DriverServiceMap extends StatefulWidget {
  final RouteEntity? assignedRoute;
  final bool inService;

  const DriverServiceMap({super.key, required this.assignedRoute, required this.inService});

  @override
  State<DriverServiceMap> createState() => _DriverServiceMapState();
}

class _DriverServiceMapState extends State<DriverServiceMap> {
  GoogleMapController? _controller;
  LatLng? _myLocation;
  bool _loading = true;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final result = await getIt<GetCurrentLocationUseCase>()();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _locationDenied = true;
      }),
      (latLng) {
        setState(() {
          _myLocation = latLng;
          _loading = false;
        });
      },
    );
  }

  List<LatLng> _routePoints() {
    final poly = widget.assignedRoute?.polyline;
    if (poly == null) return const [];
    return poly.map((p) => LatLng(p['lat']!, p['lng']!)).toList();
  }

  void _fitRoute() {
    final points = _routePoints();
    if (points.length > 1 && _controller != null) {
      MapUtils.fitBounds(_controller!, points);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: _amarillo)),
      );
    }
    if (_myLocation == null) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _locationDenied
              ? 'Activa el permiso de ubicación para ver el mapa de tu unidad.'
              : 'No se pudo obtener tu ubicación.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    final isDark = context.watch<ThemeCubit>().state;
    final points = _routePoints();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          style: isDark ? MapStyles.dark : null,
          initialCameraPosition: CameraPosition(target: _myLocation!, zoom: 15),
          onMapCreated: (controller) {
            _controller = controller;
            if (points.length > 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute());
            }
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('mi_unidad'),
              position: _myLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                widget.inService ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: widget.inService ? 'En servicio' : 'Fuera de servicio',
              ),
            ),
          },
          polylines: {
            if (points.length > 1)
              Polyline(
                polylineId: const PolylineId('ruta_asignada'),
                points: points,
                color: _amarillo,
                width: 4,
              ),
          },
        ),
      ),
    );
  }
}
