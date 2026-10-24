import 'package:flutter/material.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// Tarjeta con los datos del vehículo encontrado por placa: tipo, línea,
/// número interno, marca/modelo, capacidad y estado.
class TickeadorVehicleInfoCard extends StatelessWidget {
  final VehicleEntity vehicle;

  const TickeadorVehicleInfoCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amarillo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amarillo, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: _amarillo, size: 28),
              const SizedBox(width: 8),
              Text(
                vehicle.vehicleId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _VehicleRow(label: 'Tipo', value: vehicle.vehicleType),
          _VehicleRow(label: 'Línea', value: vehicle.lineNumber),
          _VehicleRow(label: 'Número interno', value: vehicle.internalNumber),
          _VehicleRow(
            label: 'Marca/Modelo',
            value: '${vehicle.brand} ${vehicle.model}'.trim(),
          ),
          _VehicleRow(
            label: 'Capacidad',
            value: '${vehicle.passengerCapacity} pasajeros',
          ),
          _VehicleRow(label: 'Estado', value: vehicle.status),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final String label;
  final String value;

  const _VehicleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
