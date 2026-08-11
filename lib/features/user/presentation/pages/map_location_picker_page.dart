import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';

class MapLocationPickerPage extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const MapLocationPickerPage({
    super.key,
    this.initialLocation,
    this.title = 'Seleccionar ubicación',
  });

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  static const _defaultCenter = LatLng(-17.3935, -66.1570); // Cochabamba
  static const _amarillo = Color(0xFFFFC12F);

  // ignore: unused_field – reserved for future camera animation
  GoogleMapController? _mapController;
  LatLng _center = _defaultCenter;
  String? _address;
  bool _isGeocoding = false;
  bool _isCameraMoving = false;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation ?? _defaultCenter;
    _reverseGeocode(_center);
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isGeocoding = true;
      _address = null;
    });
    final address =
        await getIt<GeocodingDatasource>().reverseGeocode(position);
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      _address = address ?? 'Dirección no disponible';
    });
  }

  void _onCameraMove(CameraPosition pos) {
    setState(() {
      _center = pos.target;
      _isCameraMoving = true;
      _address = null;
    });
  }

  void _onCameraIdle() {
    setState(() => _isCameraMoving = false);
    _reverseGeocode(_center);
  }

  void _confirm() {
    final addr = _address;
    if (addr == null) return;
    Navigator.pop(context, PlaceResult(latLng: _center, name: addr));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            style: _isDark ? MapStyles.dark : null,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // ── AppBar overlay ────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Material(
                      color: colorScheme.surface,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Material(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Center pin ───────────────────────────────────────────────────
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(
                  0, _isCameraMoving ? -12 : 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: _amarillo,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: _amarillo,
                  ),
                ],
              ),
            ),
          ),

          // ── Shadow dot under pin ─────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 36),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isCameraMoving ? 0.3 : 0.6,
                child: Container(
                  width: 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom confirm panel ──────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación seleccionada',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isGeocoding || _isCameraMoving
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Buscando dirección...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _address ?? 'Mueve el mapa para seleccionar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _address != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_address == null || _isCameraMoving || _isGeocoding)
                                ? null
                                : _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amarillo,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              colorScheme.onSurface.withValues(alpha: 0.1),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Confirmar ubicación',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
