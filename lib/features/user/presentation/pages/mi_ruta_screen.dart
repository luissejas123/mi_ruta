import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/gtfs_routes_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/osm_route.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_search_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/test_widgets_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';
import 'package:mi_ruta/features/routes/presentation/pages/routes_migration_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_action_fabs.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_search_header.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_status_card.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_suggestions_sheet.dart';

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  // ── Estado del mapa ───────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng? _myLocationLatLng;
  LatLng? _destinationLatLng;
  String? _searchText;
  String? _statusText;
  int _selectedIndex = 0;

  // ── Estado del pin arrastrable ────────────────────────────────────────────
  bool _isPinMode = false;
  String? _pinAddress;
  bool _isCameraMoving = false;
  LatLng? _cameraCenter;

  final _gtfsRoutes = GtfsRoutesDatasource();
  final _locationDatasource = LocationDatasource();
  final _geocodingDatasource = GeocodingDatasource();
  List<OsmRoute> _osmRoutes = [];
  bool _isLoadingRoutes = false;
  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  // ── Geolocalización ───────────────────────────────────────────────────────

  Future<void> _requestLocation() async {
    final result = await _locationDatasource.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _myLocationLatLng = result.location;
      _statusText = result.error;
    });
    if (!result.hasError) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(result.location, 15),
      );
    }
  }

  Future<void> _goToMyLocation() async {
    if (_myLocationLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_myLocationLatLng!, 15),
      );
    } else {
      await _requestLocation();
    }
  }

  // ── Búsqueda de direcciones ───────────────────────────────────────────────

  Future<void> _onSearchTap() async {
    final result = await Navigator.of(context).push<PlaceResult>(
      MaterialPageRoute(
        builder: (_) => MapSearchPage(currentLocation: _myLocationLatLng),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _destinationLatLng = result.latLng;
      _searchText = result.name;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 16),
    );
    // Mostrar rutas cercanas al destino buscado
    _showNearbyRoutesSheet(result);
  }

  Future<void> _showNearbyRoutesSheet(PlaceResult destination) async {
    // Si no hay rutas cargadas, las cargamos en background
    if (_osmRoutes.isEmpty && !_isLoadingRoutes) {
      setState(() => _isLoadingRoutes = true);
      try {
        final routes = await _gtfsRoutes.fetchRoutes();
        if (!mounted) return;
        setState(() {
          _osmRoutes = routes;
          _isLoadingRoutes = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isLoadingRoutes = false);
        return;
      }
    }
    if (!mounted) return;
    final allNearDest = RouteFinderService.findNearbyForTrip(
      destination: destination.latLng,
      routes: _osmRoutes,
      userLocation: _myLocationLatLng,
    );
    if (!mounted || allNearDest.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          RouteSuggestionsSheet(destination: destination, matches: allNearDest),
    );
  }

  void _clearSearch() {
    setState(() {
      _destinationLatLng = null;
      _searchText = null;
    });
    if (_myLocationLatLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_myLocationLatLng!, 15),
      );
    }
  }

  // ── Pin arrastrable ───────────────────────────────────────────────────────

  void _togglePinMode() {
    setState(() {
      _isPinMode = !_isPinMode;
      if (_isPinMode) {
        _cameraCenter ??= _myLocationLatLng;
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

  void _confirmPinDestination() {
    if (_cameraCenter == null) return;
    setState(() {
      _destinationLatLng = _cameraCenter;
      _searchText = _pinAddress ?? 'Destino';
      _isPinMode = false;
    });
  }

  // ── Navegación inferior ───────────────────────────────────────────────────

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletPage()),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RutasInicioPage()),
      );
      return;
    }
    if (index == 3) {
      final authBloc = context.read<AuthBloc>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authBloc,
            child: const TestWidgetsScreen(),
          ),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  // ── Marcadores ────────────────────────────────────────────────────────────

  Set<Marker> get _markers {
    return {
      if (_myLocationLatLng != null)
        Marker(
          markerId: const MarkerId('mi_ubicacion'),
          position: _myLocationLatLng!,
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
      if (_destinationLatLng != null)
        Marker(
          markerId: const MarkerId('destino'),
          position: _destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: _searchText ?? 'Destino'),
        ),
    };
  }

  // ── Helpers de build ──────────────────────────────────────────────────────

  Widget _buildMap() {
    if (_myLocationLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _myLocationLatLng!,
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _cameraCenter = _myLocationLatLng;
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
      markers: _isPinMode ? {} : _markers,
      zoomControlsEnabled: false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Column(
          children: [
            MapSearchHeader(onSearchTap: _onSearchTap, searchText: _searchText),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap()),

                  if (_isPinMode)
                    MapPinOverlay(isCameraMoving: _isCameraMoving),

                  if (!_isPinMode)
                    Positioned.fill(
                      child: MapActionFabs(
                        hasDestination: _destinationLatLng != null,
                        onMyLocation: _goToMyLocation,
                        onTogglePin: _togglePinMode,
                        onClearSearch: _clearSearch,
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
                        onCancel: _togglePinMode,
                        onConfirm: (_isCameraMoving || _pinAddress == null)
                            ? null
                            : _confirmPinDestination,
                      ),
                    ),

                  if (_statusText != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 80,
                      child: MapStatusCard(message: _statusText!),
                    ),

                  // Botón de migración de rutas
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'migration',
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoutesMigrationPage(),
                          ),
                        );
                      },
                      child: const Icon(Icons.cloud_upload_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
