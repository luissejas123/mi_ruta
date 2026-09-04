import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/vehicle_review_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/vehicle_review_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/vehicle_review_state.dart';

const _amarillo = Color(0xFFFFC12F);

const _docLabels = {
  'driver_license_url': 'Licencia de conducir',
  'vehicle_inspection_url': 'Inspección técnica vehicular',
  'soat_url': 'SOAT',
  'ruat_url': 'RUAT',
  'municipal_operation_card_url': 'Tarjeta de operación municipal',
};

/// Revisión de unidades (RQ-64), separada de "Aprobar choferes"
/// (`DriverApprovalPage`): una unidad puede volver a pedir revisión cuando
/// su dueño la edita, sin pasar de nuevo por la solicitud de chofer — el
/// presidente/admin necesita volver a verificar documentos y datos antes de
/// que siga operando como aprobada.
class VehicleReviewPage extends StatelessWidget {
  const VehicleReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VehicleReviewBloc(
        driverService: getIt<DriverService>(),
        userService: getIt<UserManagementService>(),
      )..add(const LoadVehicleReviewQueue()),
      child: const _VehicleReviewView(),
    );
  }
}

class _VehicleReviewView extends StatelessWidget {
  const _VehicleReviewView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Revisar unidades',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<VehicleReviewBloc, VehicleReviewState>(
        builder: (context, state) {
          if (state is VehicleReviewLoading || state is VehicleReviewInitial) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          if (state is VehicleReviewError) {
            return _ErrorState(message: state.message);
          }
          if (state is VehicleReviewLoaded) {
            if (state.isEmpty) return const _EmptyState();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in state.pending) ...[
                  _VehicleReviewTile(
                    entry: entry,
                    isUpdating: state.updatingVehicleId == entry.vehicle.vehicleId,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                context.read<VehicleReviewBloc>().add(const LoadVehicleReviewQueue()),
            style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
            child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay unidades pendientes de revisión',
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _VehicleReviewTile extends StatelessWidget {
  final VehicleReviewEntry entry;
  final bool isUpdating;

  const _VehicleReviewTile({required this.entry, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final vehicle = entry.vehicle;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amarillo.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _amarillo,
                child: const Icon(Icons.directions_bus_outlined, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.ownerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (entry.ownerEmail.isNotEmpty)
                      Text(
                        entry.ownerEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              if (vehicle.isRejected)
                const _StatusChip(label: 'Antes rechazada', color: Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${vehicle.brand.isEmpty ? vehicle.vehicleType : vehicle.brand} · Placa ${vehicle.vehicleId}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            'Línea ${vehicle.lineNumber} · Unidad ${vehicle.internalNumber} · '
            '${vehicle.color} · ${vehicle.passengerCapacity} pasajeros',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _DocumentsSheet.show(context, vehicle: vehicle),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Ver documentos'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ),
          const SizedBox(height: 6),
          if (isUpdating)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context
                        .read<VehicleReviewBloc>()
                        .add(RejectVehicle(vehicle.vehicleId)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context
                        .read<VehicleReviewBloc>()
                        .add(ApproveVehicle(vehicle.vehicleId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Aprobar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _DocumentsSheet extends StatelessWidget {
  final VehicleEntity vehicle;

  const _DocumentsSheet({required this.vehicle});

  static void show(BuildContext context, {required VehicleEntity vehicle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DocumentsSheet(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Documentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              for (final e in _docLabels.entries)
                _DocumentRow(label: e.value, url: vehicle.legalDocumentation[e.key]),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String label;
  final String? url;

  const _DocumentRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final uploaded = url != null && url!.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        uploaded ? Icons.check_circle : Icons.cancel_outlined,
        color: uploaded ? Colors.green : Colors.red.shade300,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: uploaded ? const Icon(Icons.chevron_right) : null,
      onTap: uploaded
          ? () => showDialog(
                context: context,
                builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(url!))),
              )
          : null,
    );
  }
}
