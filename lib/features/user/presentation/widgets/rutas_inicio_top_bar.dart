import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/presentation/widgets/location_row.dart';

/// Barra superior de la pantalla de inicio de rutas.
/// Incluye el título, la tarjeta de origen/destino y el botón de búsqueda.
/// Debe colocarse dentro de un [Stack] envuelta con [Positioned].
class RutasInicioTopBar extends StatelessWidget {
  final PlaceResult? origin;
  final PlaceResult? destination;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onOriginPinTap;
  final VoidCallback onDestinationPinTap;
  final VoidCallback onSearchTap;

  static const _titleColor = Color(0xFFFBC02D);
  static const _searchBtnColor = Color(0xFFFBC02D);

  const RutasInicioTopBar({
    super.key,
    required this.origin,
    required this.destination,
    required this.onOriginTap,
    required this.onDestinationTap,
    required this.onOriginPinTap,
    required this.onDestinationPinTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF1F3F4).withValues(alpha: 1.0),
              const Color(0xFFF1F3F4).withValues(alpha: 0.95),
              const Color(0xFFF1F3F4).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MiRuta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLocationCard(),
                const SizedBox(height: 12),
                if (destination != null) _buildSearchButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          LocationRow(
            icon: Icons.radio_button_checked,
            iconColor: const Color(0xFF43A047),
            label: origin == null ? 'Mi ubicación actual' : origin!.name,
            isPlaceholder: origin == null,
            onTap: onOriginTap,
            onPinTap: onOriginPinTap,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          LocationRow(
            icon: Icons.location_on,
            iconColor: const Color(0xFFE53935),
            label: destination == null ? '¿A dónde vas?' : destination!.name,
            isPlaceholder: destination == null,
            onTap: onDestinationTap,
            onPinTap: onDestinationPinTap,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onSearchTap,
      icon: const Icon(Icons.search),
      label: const Text('Buscar rutas'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _searchBtnColor,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
