import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_section_title.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_vehicle_info_card.dart';

const _amarillo = Color(0xFFFFC12F);

/// Sección "BUSCAR VEHÍCULO POR PLACA" — campo de búsqueda, resultado
/// (encontrado / no encontrado / vacío) y los botones "Marcar salida"/
/// "Marcar llegada" sobre el vehículo ya buscado.
///
/// [foundVehicle]/[notFound] reflejan el estado actual del BLoC (`VehicleFound`/
/// `VehicleNotFound`) y solo controlan qué se dibuja en el área de resultado.
/// [hasSelectedVehicle] es distinto a propósito: viene del vehículo
/// seleccionado que guarda `TickeadorHomePage` (persiste aunque el estado del
/// BLoC cambie después, ej. tras un `StationLogSuccess`) y es lo que
/// habilita/deshabilita los botones de marcar salida/llegada.
class TickeadorVehicleSearchSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isBusy;
  final bool isDarkMode;
  final VehicleEntity? foundVehicle;
  final bool notFound;
  final bool hasSelectedVehicle;
  final VoidCallback onBuscar;
  final VoidCallback onMarcarSalida;
  final VoidCallback onMarcarLlegada;

  const TickeadorVehicleSearchSection({
    super.key,
    required this.controller,
    required this.isBusy,
    required this.isDarkMode,
    required this.foundVehicle,
    required this.notFound,
    required this.hasSelectedVehicle,
    required this.onBuscar,
    required this.onMarcarSalida,
    required this.onMarcarLlegada,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TickeadorSectionTitle('BUSCAR VEHÍCULO POR PLACA'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Ej: 2341-ABC',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isBusy ? null : onBuscar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarillo,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildResultArea(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (isBusy || !hasSelectedVehicle)
                    ? null
                    : onMarcarSalida,
                icon: const Icon(Icons.login),
                label: const Text('Marcar salida'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amarillo,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (isBusy || !hasSelectedVehicle)
                    ? null
                    : onMarcarLlegada,
                icon: const Icon(Icons.logout),
                label: const Text('Marcar llegada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultArea() {
    if (foundVehicle != null) {
      return TickeadorVehicleInfoCard(vehicle: foundVehicle!);
    }
    if (notFound) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text(
          'Vehículo no encontrado',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            color: Colors.grey.shade400,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Busca un vehículo por placa para ver su información',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
