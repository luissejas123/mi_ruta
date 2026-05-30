import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/routes/domain/services/route_entity_converter.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_search_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_selection_sheet.dart';
import 'package:mi_ruta/features/user/presentation/widgets/rutas_inicio_top_bar.dart';

enum _PinFor { origin, destination }

class RutasInicioPage extends StatefulWidget {
  const RutasInicioPage({super.key});

  @override
  State<RutasInicioPage> createState() => _RutasInicioPageState();
}

class _RutasInicioPageState extends State<RutasInicioPage> {
  // ─────────────────────────────────────────────────────────────────────
  // Constantes
  // ─────────────────────────────────────────────────────────────────────

  static const _navIndexRoutes = 2;
  static const _routeMatchDistance = 3000.0;

  // ─────────────────────────────────────────────────────────────────────
  // Estado - Datasources y Services
  // ─────────────────────────────────────────────────────────────────────

  final _locationDatasource = LocationDatasource();
  final _geocodingDatasource = GeocodingDatasource();
  late final RouteDataSyncService _syncService = getIt<RouteDataSyncService>();

  // ─────────────────────────────────────────────────────────────────────
  // Estado - Mapa y Ubicaciones
  // ─────────────────────────────────────────────────────────────────────

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  PlaceResult? _origin;
  PlaceResult? _destination;
  List<RouteMatch> _matches = [];

  // ─────────────────────────────────────────────────────────────────────
  // Estado - Pin Mode
  // ─────────────────────────────────────────────────────────────────────

  bool _isPinMode = false;
  _PinFor _pinFor = _PinFor.destination;
  LatLng? _cameraCenter;
  String? _pinAddress;
  bool _isCameraMoving = false;

  // ─────────────────────────────────────────────────────────────────────
  // Estado - Rutas
  // ─────────────────────────────────────────────────────────────────────

  final Map<String, List<RouteMatch>> _routeCache = {};
  late Future<void> _dataReadyFuture;
  bool _isDataLoading = false;

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getLocation();
    // Reusar el future del servicio (ya arrancó desde main.dart)
    _dataReadyFuture = _syncService.ensureDataReady();
    _dataReadyFuture.then((_) {
      if (mounted) setState(() => _isDataLoading = false);
    });
    _checkIfLoading();
  }

  Future<void> _checkIfLoading() async {
    final count = await _syncService.localDb.countRoutes();
    if (mounted && count == 0) {
      setState(() => _isDataLoading = true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Migración de Bounding Boxes
  // ─────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Búsqueda de Rutas
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _findRoutes() async {
    if (_destination == null) return;

    final originLatLng = _origin?.latLng ?? _userLocation;
    if (originLatLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esperando ubicación GPS...')),
        );
      }
      return;
    }

    if (!mounted) return;

    final cacheKey =
        '${originLatLng.latitude},${originLatLng.longitude}-'
        '${_destination!.latLng.latitude},${_destination!.latLng.longitude}';

    // Comprobar caché local de búsquedas
    if (_routeCache.containsKey(cacheKey)) {
      _matches = _routeCache[cacheKey]!;
      if (mounted) _showRoutesSheet();
      return;
    }

    // Flag para controlar si mostrar diálogo
    bool dialogShown = false;
    Timer? loadingTimer;

    // Mostrar diálogo solo si la búsqueda tarda > 300ms
    loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !dialogShown) {
        dialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            title: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Buscando rutas')),
              ],
            ),
            content: Text('Buscando rutas cercanas...'),
          ),
        );
      }
    });

    try {
      // Esperar que los datos locales estén listos (GTFS seed o sync)
      await _dataReadyFuture;

      // Buscar rutas que pasen cerca del ORIGEN (usuario) y del DESTINO, unir sin duplicados
      final nearOriginRows = await _syncService.getRoutesNearPoint(
        latitude: originLatLng.latitude,
        longitude: originLatLng.longitude,
      );
      final nearDestRows = await _syncService.getRoutesNearPoint(
        latitude: _destination!.latLng.latitude,
        longitude: _destination!.latLng.longitude,
      );
      final allById = <String, dynamic>{};
      for (final r in nearOriginRows) allById[r.id] = r;
      for (final r in nearDestRows) allById.putIfAbsent(r.id, () => r);
      final nearbyRoutes = allById.values.toList();

      loadingTimer.cancel();

      if (!mounted) return;

      if (nearbyRoutes.isEmpty) {
        if (dialogShown) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay rutas en esa zona. Verifica tu ubicación.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Convertir RouteEntity → OsmRoute y filtrar por proximidad
      final candidates = <OsmRoute>[];
      for (int i = 0; i < nearbyRoutes.length; i++) {
        candidates.add(RouteEntityConverter.toOsmRoute(nearbyRoutes[i], i));
      }

      final matches = RouteFinderService.findForTrip(
        origin: originLatLng,
        destination: _destination!.latLng,
        routes: candidates,
        // maxDistanceMeters usa el default de 800m (~10 min caminando)
      );

      if (!mounted) return;
      if (dialogShown) Navigator.pop(context);

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay rutas que pasen por esa zona'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _routeCache[cacheKey] = matches;
      _matches = matches;
      if (mounted) _showRoutesSheet();
    } catch (e, st) {
      loadingTimer.cancel();
      print('❌ Error buscando rutas: $e\n$st');
      if (!mounted) return;
      if (dialogShown) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRoutesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => RouteSelectionSheet(
          matches: _matches,
          destination: _destination!,
          onRouteSelected: _onRouteSelected,
          scrollController: controller,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Navegación
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _onOriginTap() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchPage(currentLocation: _userLocation),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _origin = result);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 15),
    );
  }

  Future<void> _onDestinationTap() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchPage(currentLocation: _userLocation),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _destination = result);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 15),
    );
    if (mounted) {
      // Pequeño delay para asegurar que el state se actualice
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) await _findRoutes();
    }
  }

  void _onRouteSelected(RouteMatch match) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RutaLineaPage(
          route: match.route,
          destination: _destination!,
          origin: _origin?.latLng ?? _userLocation,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Pin Mode
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    final result = await _locationDatasource.getCurrentLocation();
    if (!mounted) return;
    setState(() => _userLocation = result.location);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.location, 15),
    );
  }

  void _togglePinMode([_PinFor target = _PinFor.destination]) {
    setState(() {
      _pinFor = target;
      _isPinMode = !_isPinMode;
      if (_isPinMode) {
        _cameraCenter ??= _userLocation ?? LocationDatasource.defaultCenter;
        _pinAddress = null;
      } else {
        _pinAddress = null;
      }
    });
    if (_isPinMode) _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    if (_cameraCenter == null) return;
    final address = await _geocodingDatasource.reverseGeocode(_cameraCenter!);
    if (!mounted) return;
    setState(() => _pinAddress = address ?? 'Dirección no disponible');
  }

  Future<void> _confirmPin() async {
    if (_cameraCenter == null) return;
    final place = PlaceResult(
      latLng: _cameraCenter!,
      name: _pinAddress ?? 'Ubicación seleccionada',
    );
    setState(() {
      _isPinMode = false;
      if (_pinFor == _PinFor.origin) {
        _origin = place;
      } else {
        _destination = place;
      }
    });
    if (_pinFor == _PinFor.destination && mounted) {
      // Pequeño delay para asegurar que el state se actualice
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) await _findRoutes();
    }
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
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? LocationDatasource.defaultCenter,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _cameraCenter = _userLocation ?? LocationDatasource.defaultCenter;
            },
            onCameraMove: (pos) {
              _cameraCenter = pos.target;
              if (_isPinMode && !_isCameraMoving) {
                setState(() => _isCameraMoving = true);
              }
            },
            onCameraIdle: () {
              if (_isPinMode) {
                setState(() => _isCameraMoving = false);
                _reverseGeocode();
              }
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _userLocation == null
                ? <Marker>{}
                : <Marker>{
                    Marker(
                      markerId: const MarkerId('user_location'),
                      position: _userLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  },
            polylines: <Polyline>{},
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RutasInicioTopBar(
              origin: _origin,
              destination: _destination,
              onOriginTap: _onOriginTap,
              onDestinationTap: _onDestinationTap,
              onOriginPinTap: () => _togglePinMode(_PinFor.origin),
              onDestinationPinTap: () => _togglePinMode(_PinFor.destination),
              onSearchTap: _findRoutes,
            ),
          ),
          if (!_isPinMode)
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'rutas_my_location',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                onPressed: _getLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
          if (_isPinMode) MapPinOverlay(isCameraMoving: _isCameraMoving),
          if (_isPinMode)
            // Banner de carga primera vez
            if (_isDataLoading)
              Positioned(
                bottom: 110,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBC02D),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Preparando rutas por primera vez...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (_isPinMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MapPinConfirmPanel(
                isCameraMoving: _isCameraMoving,
                address: _pinAddress,
                onCancel: () => setState(() {
                  _isPinMode = false;
                  _pinAddress = null;
                }),
                onConfirm: (_isCameraMoving || _pinAddress == null)
                    ? null
                    : _confirmPin,
              ),
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
