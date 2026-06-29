import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/route_search_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/route_search_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/route_search_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_search_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_selection_sheet.dart';
import 'package:mi_ruta/features/user/presentation/widgets/rutas_inicio_top_bar.dart';

enum _PinFor { origin, destination }

class RutasInicioPage extends StatelessWidget {
  const RutasInicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RouteSearchBloc(syncService: getIt<RouteDataSyncService>()),
      child: const _RutasInicioView(),
    );
  }
}

class _RutasInicioView extends StatefulWidget {
  const _RutasInicioView();

  @override
  State<_RutasInicioView> createState() => _RutasInicioViewState();
}

class _RutasInicioViewState extends State<_RutasInicioView> {
  static const _navIndexRoutes = 2;
  static const _amarillo = Color(0xFFFFC12F);

  final _locationDatasource = LocationDatasource();
  final _geocodingDatasource = GeocodingDatasource();
  late final RouteDataSyncService _syncService =
      getIt<RouteDataSyncService>();

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  PlaceResult? _origin;
  PlaceResult? _destination;

  bool _isPinMode = false;
  _PinFor _pinFor = _PinFor.destination;
  LatLng? _cameraCenter;
  String? _pinAddress;
  bool _isCameraMoving = false;

  late Future<void> _dataReadyFuture;
  bool _isDataLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _getLocation();
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

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

    if (mounted) {
      context.read<RouteSearchBloc>().add(
        SearchRoutesRequested(
          origin: originLatLng,
          destination: _destination!,
        ),
      );
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

  void _showRoutesSheet(List<RouteMatch> matches) {
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
          matches: matches,
          destination: _destination!,
          onRouteSelected: _onRouteSelected,
          scrollController: controller,
        ),
      ),
    );
  }

  // ✅ Búsqueda de ORIGEN con modo correcto
  Future<void> _onOriginTap() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchPage(
          currentLocation: _userLocation,
          searchMode: SearchMode.origin,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _origin = result);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 15),
    );
  }

  // ✅ Búsqueda de DESTINO con modo correcto
  Future<void> _onDestinationTap() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchPage(
          currentLocation: _userLocation,
          searchMode: SearchMode.destination,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _destination = result);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 15),
    );
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) await _findRoutes();
    }
  }

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
    final address =
        await _geocodingDatasource.reverseGeocode(_cameraCenter!);
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
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) await _findRoutes();
    }
  }

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
              _cameraCenter =
                  _userLocation ?? LocationDatasource.defaultCenter;
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
            polylines: const <Polyline>{},
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
              onDestinationPinTap: () =>
                  _togglePinMode(_PinFor.destination),
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
          // ✅ Banner de carga
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
                  color: _amarillo,
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
          BlocListener<RouteSearchBloc, RouteSearchState>(
            listener: (context, state) {
              if (state is RouteSearchSuccess) {
                _showRoutesSheet(state.matches);
              } else if (state is RouteSearchEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is RouteSearchError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const SizedBox.shrink(),
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