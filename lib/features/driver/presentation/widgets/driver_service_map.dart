import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/core/utils/location_icon_painter.dart';
import 'package:mi_ruta/core/utils/map_utils.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_location_usecase.dart';

const _amarillo = Color(0xFFFFC12F);

/// Mapa de la unidad del chofer para las vistas de inicio/detener servicio
/// (Figma "3.3 Inicio Servicio" / "3.3 Detener Servicio"): posición del
/// chofer en tiempo real (mismo patrón de `Geolocator.getPositionStream`
/// que ya usa `NavigationBloc` para el pasajero en ruta) + la ruta asignada
/// dibujada, si el catálogo GTFS tiene su polyline.
class DriverServiceMap extends StatefulWidget {
  final RouteEntity? assignedRoute;
  final bool inService;
  final double height;

  const DriverServiceMap({
    super.key,
    required this.assignedRoute,
    required this.inService,
    this.height = 220,
  });

  @override
  State<DriverServiceMap> createState() => _DriverServiceMapState();
}

class _DriverServiceMapState extends State<DriverServiceMap> {
  GoogleMapController? _controller;
  LatLng? _myLocation;
  bool _loading = true;
  bool _locationDenied = false;
  StreamSubscription<Position>? _positionSubscription;
  BitmapDescriptor? _locationIcon;
  // La cámara seguía la posición en CADA actualización del GPS (cada ~5m),
  // así que un chofer que intentaba paniar el mapa para mirar otra calle
  // era "empujado" de vuelta a su ubicación en el siguiente tick — no
  // dejaba navegar el mapa. Ahora el auto-seguimiento se pausa apenas el
  // chofer arrastra el mapa con el dedo, y un botón lo vuelve a activar.
  bool _autoFollow = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadLocationIcon();
  }

  @override
  void didUpdateWidget(DriverServiceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inService != widget.inService) _loadLocationIcon();
  }

  /// Círculo tipo "punto" en vez del pin genérico de Maps, verde/naranja
  /// según en/fuera de servicio — se regenera si ese estado cambia porque
  /// el color queda "horneado" en el bitmap, no es una propiedad del Marker.
  Future<void> _loadLocationIcon() async {
    final icon = await LocationIconPainter.build(
      color: widget.inService ? Colors.green.shade600 : Colors.orange.shade700,
    );
    if (mounted && icon != null) setState(() => _locationIcon = icon);
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
        _startLiveTracking();
      },
    );
  }

  /// Igual que `NavigationBloc._startGpsTracking`: la ubicación inicial ya
  /// se obtuvo arriba (con su propio manejo de permisos vía
  /// GetCurrentLocationUseCase), acá solo se agrega el stream para que el
  /// marcador se mueva solo mientras la pantalla está abierta.
  void _startLiveTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (!mounted) return;
      final updated = LatLng(position.latitude, position.longitude);
      setState(() => _myLocation = updated);
      // El marcador se movía solo (arriba), pero la cámara se quedaba fija
      // en la posición inicial — sin esto la app parecía no rastrear en
      // tiempo real (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 1).
      // Solo si el chofer no está paniando el mapa a mano ahora mismo.
      if (_autoFollow) {
        _controller?.animateCamera(CameraUpdate.newLatLng(updated));
      }
    });
  }

  void _recenter() {
    setState(() => _autoFollow = true);
    if (_myLocation != null) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_myLocation!));
    }
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
    _positionSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: _amarillo)),
      );
    }
    if (_myLocation == null) {
      return Container(
        height: widget.height,
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
        height: widget.height,
        child: Stack(
          children: [
            GoogleMap(
              style: isDark ? MapStyles.dark : null,
              initialCameraPosition:
                  CameraPosition(target: _myLocation!, zoom: 15),
              onMapCreated: (controller) {
                _controller = controller;
                if (points.length > 1) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _fitRoute());
                }
              },
              // El chofer tocó el mapa con el dedo: dejar de seguirlo solo
              // hasta que vuelva a tocar el botón de recentrar.
              onCameraMoveStarted: () {
                if (_autoFollow) setState(() => _autoFollow = false);
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('mi_unidad'),
                  position: _myLocation!,
                  icon: _locationIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        widget.inService
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueOrange,
                      ),
                  anchor: const Offset(0.5, 0.5),
                  infoWindow: InfoWindow(
                    title:
                        widget.inService ? 'En servicio' : 'Fuera de servicio',
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
            if (!_autoFollow)
              Positioned(
                right: 8,
                bottom: 8,
                child: FloatingActionButton.small(
                  heroTag: 'driver_service_map_recenter',
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
