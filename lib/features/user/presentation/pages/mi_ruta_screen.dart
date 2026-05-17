import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/presentation/pages/test_widgets_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_search_header.dart';

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  static const LatLng _defaultCenter = LatLng(-17.391032, -66.1568);
  LatLng? _mapCenter;
  String? _statusText;
  GoogleMapController? _mapController;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText =
            'Activa el servicio de ubicación para ver tu posición real.';
        _mapCenter = _defaultCenter;
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
        _mapCenter = _defaultCenter;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    setState(() {
      _mapCenter = LatLng(position.latitude, position.longitude);
      _statusText = null;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_mapCenter!, 15));
  }

  void _onSearchTap() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar destino'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: '¿A dónde vamos ...?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletPage()),
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

  Set<Marker> get _markers {
    if (_mapCenter == null) return {};
    return {
      Marker(
        markerId: const MarkerId('mi_ubicacion'),
        position: _mapCenter!,
        infoWindow: const InfoWindow(title: 'Mi ubicación'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Column(
          children: [
            MapSearchHeader(onSearchTap: _onSearchTap),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _mapCenter == null
                        ? const Center(child: CircularProgressIndicator())
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _mapCenter!,
                              zoom: 15,
                            ),
                            onMapCreated: (controller) =>
                                _mapController = controller,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            markers: _markers,
                            zoomControlsEnabled: false,
                          ),
                  ),
                  if (_statusText != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
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
