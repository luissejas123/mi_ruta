import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/routes/data/datasources/route_cache_manager.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_entity_converter.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_search_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/cache_download_dialog.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_selection_sheet.dart';
import 'package:mi_ruta/features/user/presentation/widgets/rutas_inicio_top_bar.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_progress_dialog.dart';

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
  static const _maxSearchDistance = 5000.0;
  static const _routeMatchDistance = 3000.0;
  static const _chunkSize = 50;

  // ─────────────────────────────────────────────────────────────────────
  // Estado - Datasources y Services
  // ─────────────────────────────────────────────────────────────────────

  final _locationDatasource = LocationDatasource();
  final _geocodingDatasource = GeocodingDatasource();
  late final RouteService _routeService = getIt<RouteService>();

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
  // Estado - Rutas y Caché
  // ─────────────────────────────────────────────────────────────────────

  List<OsmRoute> _osmRoutes = [];
  Map<String, List<RouteMatch>> _routeCache = {};
  List<RouteEntity> _cachedRouteEntities = [];
  late Future<void> _cacheLoadingFuture;
  bool _cacheInitialized = false;
  late final ValueNotifier<int> _downloadProgressNotifier = ValueNotifier(0);
  late final ValueNotifier<int> _downloadTotalNotifier = ValueNotifier(0);

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _getLocation();
    _cacheLoadingFuture = _initializeRouteCache();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Caché de Rutas
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _initializeRouteCache() async {
    try {
      var routes = await RouteCacheManager.loadRoutesFromCache();
      print('✅ Caché local: ${routes.length} rutas');

      if (routes.isEmpty) {
        print('📥 Descargando rutas desde Firestore...');
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CacheDownloadDialog(
              progressNotifier: _downloadProgressNotifier,
              totalNotifier: _downloadTotalNotifier,
            ),
          );
        }
        routes = await _downloadRoutesInChunks();
        print('🔽 Descargadas ${routes.length} rutas de Firestore');

        if (routes.isNotEmpty) {
          await RouteCacheManager.saveRoutesToCache(routes);
          print('💾 Guardadas en caché local');
        }
        if (mounted) Navigator.pop(context);
      }

      if (mounted) {
        setState(() {
          _cachedRouteEntities = routes;
          _cacheInitialized = true;
        });
      }
      print('✨ Caché inicializado: ${routes.length} rutas disponibles');
    } catch (e, st) {
      print('❌ Error inicializando caché: $e\n$st');
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      _cacheInitialized = true;
    }
  }

  Future<List<RouteEntity>> _downloadRoutesInChunks() async {
    final allRoutes = <RouteEntity>[];
    try {
      print('⏳ Descargando rutas de Firestore con paginación...');
      DocumentSnapshot? lastDoc;
      int totalDownloaded = 0;

      while (true) {
        try {
          final result = await _routeService.getActiveRoutesPaginated(
            _chunkSize,
            startAfter: lastDoc,
          );
          final chunk = result['routes'] as List<RouteEntity>;
          lastDoc = result['lastDoc'] as DocumentSnapshot?;

          if (chunk.isEmpty) {
            print('✅ Fin de descarga - no hay más rutas');
            break;
          }

          allRoutes.addAll(chunk);
          totalDownloaded += chunk.length;
          _downloadProgressNotifier.value = totalDownloaded;
          _downloadTotalNotifier.value = totalDownloaded + _chunkSize;
          print('📦 Descargado chunk: $totalDownloaded rutas acumuladas');
          await Future.delayed(const Duration(milliseconds: 50));

          if (chunk.length < _chunkSize) {
            _downloadTotalNotifier.value = totalDownloaded;
            break;
          }
        } catch (e) {
          print('❌ Error descargando chunk: $e');
          rethrow;
        }
      }

      _downloadProgressNotifier.value = allRoutes.length;
      _downloadTotalNotifier.value = allRoutes.length;
      print('✨ Descarga completada: ${allRoutes.length} rutas totales');
      return allRoutes;
    } catch (e, st) {
      print('❌ Error en _downloadRoutesInChunks: $e\n$st');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Métodos Privados - Búsqueda de Rutas
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _findRoutes() async {
    if (_destination == null) return;
    final originLatLng = _origin?.latLng ?? _userLocation;
    if (originLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    final cacheKey =
        '${originLatLng.latitude},${originLatLng.longitude}-'
        '${_destination!.latLng.latitude},${_destination!.latLng.longitude}';

    if (_routeCache.containsKey(cacheKey)) {
      _matches = _routeCache[cacheKey]!;
      if (mounted) _showRoutesSheet();
      return;
    }

    if (!_cacheInitialized) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Preparando búsqueda')),
            ],
          ),
          content: const Text('Esperando a que se carguen las rutas...'),
        ),
      );
      try {
        await _cacheLoadingFuture;
      } catch (e) {
        print('Error esperando caché: $e');
      }
      if (!mounted) return;
      Navigator.pop(context);
      if (_cachedRouteEntities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay rutas disponibles'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_cachedRouteEntities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay rutas disponibles. Intenta reiniciar la app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SearchProgressDialog(
        message: 'Buscando rutas cercanas...',
        onCancel: () => Navigator.pop(context),
      ),
    );

    try {
      _osmRoutes.clear();
      print('🔍 Pre-filtrando ${_cachedRouteEntities.length} rutas...');

      final candidates = <OsmRoute>[];
      for (int i = 0; i < _cachedRouteEntities.length; i++) {
        if (!mounted) return;
        final entity = _cachedRouteEntities[i];
        if (RouteEntityConverter.hasPointNearTargets(
          entity,
          originLatLng,
          _destination!.latLng,
          _maxSearchDistance,
        )) {
          candidates.add(RouteEntityConverter.toOsmRoute(entity, i));
        }
        if (i % 100 == 0) await Future.delayed(const Duration(milliseconds: 1));
      }

      if (!mounted) return;
      final matches = RouteFinderService.findForTrip(
        origin: originLatLng,
        destination: _destination!.latLng,
        routes: candidates,
        maxDistanceMeters: _routeMatchDistance,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay rutas cercanas a tu ubicación'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('✅ Encontradas ${matches.length} rutas ordenadas por cercanía');
      _routeCache[cacheKey] = matches;
      setState(() {
        _osmRoutes = matches.map((m) => m.route).toList();
        _matches = matches;
      });
      _showRoutesSheet();
    } catch (e, st) {
      if (mounted) {
        Navigator.pop(context);
        print('Error en _findRoutes: $e\n$st');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
    await _findRoutes();
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
    if (_pinFor == _PinFor.destination) await _findRoutes();
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
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            polylines: {},
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
