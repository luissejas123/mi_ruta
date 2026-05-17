import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_search_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/test_widgets_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_search_header.dart';

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  // ── Constantes ────────────────────────────────────────────────────────────
  static const LatLng _defaultCenter = LatLng(-17.391032, -66.1568);

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

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  // ── Geolocalización ───────────────────────────────────────────────────────

  Future<void> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText = 'Activa el servicio de ubicación para ver tu posición real.';
        _myLocationLatLng = _defaultCenter;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _statusText = 'Permiso de ubicación denegado. Usa el mapa manualmente.';
        _myLocationLatLng = _defaultCenter;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final myLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _myLocationLatLng = myLatLng;
      _statusText = null;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(myLatLng, 15));
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
    try {
      final placemarks = await placemarkFromCoordinates(
        _cameraCenter!.latitude,
        _cameraCenter!.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final addr = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        setState(() =>
            _pinAddress = addr.isEmpty ? 'Ubicación desconocida' : addr);
      }
    } catch (_) {
      if (mounted) setState(() => _pinAddress = 'Dirección no disponible');
    }
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
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WalletPage()));
      return;
    }
    if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RutasInicioPage()));
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
      initialCameraPosition:
          CameraPosition(target: _myLocationLatLng!, zoom: 15),
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

  List<Widget> _buildFabs() {
    return [
      Positioned(
        right: 16,
        bottom: 24,
        child: FloatingActionButton.small(
          backgroundColor: Colors.white,
          onPressed: _goToMyLocation,
          tooltip: 'Mi ubicación',
          child: const Icon(Icons.my_location, color: Colors.black87),
        ),
      ),
      Positioned(
        right: 16,
        bottom: _destinationLatLng != null ? 136 : 80,
        child: FloatingActionButton.small(
          backgroundColor: Colors.white,
          onPressed: _togglePinMode,
          tooltip: 'Mover pin al destino',
          child: const Icon(Icons.push_pin, color: Colors.black87, size: 20),
        ),
      ),
      if (_destinationLatLng != null)
        Positioned(
          right: 16,
          bottom: 80,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            onPressed: _clearSearch,
            tooltip: 'Limpiar búsqueda',
            child: const Icon(Icons.close, color: Colors.black87),
          ),
        ),
    ];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Column(
          children: [
            MapSearchHeader(
              onSearchTap: _onSearchTap,
              searchText: _searchText,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap()),

                  if (_isPinMode)
                    MapPinOverlay(isCameraMoving: _isCameraMoving),

                  if (!_isPinMode) ..._buildFabs(),

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
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _statusText!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
