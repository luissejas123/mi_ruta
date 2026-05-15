import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;

  // Ubicación inicial: Cochabamba, Bolivia
  static const LatLng _initialPosition = LatLng(-17.3895, -66.1568);

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('marker_1'),
      position: LatLng(-17.3895, -66.1568),
      infoWindow: InfoWindow(
        title: 'Cochabamba',
        snippet: 'Cochabamba, Bolivia',
      ),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print('✅ GoogleMap creado correctamente');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Google Maps'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              mapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(target: _initialPosition, zoom: 15.0),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cámara centrada en La Paz')),
              );
            },
            tooltip: 'Centrar mapa',
            child: const Icon(Icons.location_on),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver atrás',
            child: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
