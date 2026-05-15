import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  static const latlong.LatLng _defaultCenter = latlong.LatLng(-17.391032, -66.1568);
  latlong.LatLng? _mapCenter;
  String? _statusText;
  final MapController _mapController = MapController();
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText = 'Activa el servicio de ubicación para ver tu posición real.';
        _mapCenter = _defaultCenter;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() {
        _statusText = 'Permiso de ubicación denegado. Usa el mapa manualmente.';
        _mapCenter = _defaultCenter;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    setState(() {
      _mapCenter = latlong.LatLng(position.latitude, position.longitude);
      _statusText = null;
    });
    _mapController.move(_mapCenter!, 15);
  }

  void _onSearchTap() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buscar destino'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: '¿A dónde vamos ...?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Listo'),
            ),
          ],
        );
      },
    );
  }

  List<Marker> get _markers {
    if (_mapCenter == null) {
      return [];
    }
    return [
      Marker(
        point: _mapCenter!,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F3F4),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'MiRuta',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBC02D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _onSearchTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBC02D),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: Colors.black87),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '¿A dónde vamos ...?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _mapCenter == null
                        ? const Center(child: CircularProgressIndicator())
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter!,
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.proyecto',
                              ),
                              MarkerLayer(markers: _markers),
                            ],
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
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Billetera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
