import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_state.dart';

/// Panel de entrada del chofer: gestión de la unidad que tiene asignada.
class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final ownerUid = authState is AuthLoaded ? authState.user.uid : '';
    final isStaticDemo = ownerUid == kStaticDemoDriverUid;

    return BlocProvider(
      create: (_) => getIt<DriverVehicleBloc>()
        ..add(isStaticDemo
            ? const LoadStaticDemoVehicle()
            : StartMyVehicleStream(ownerUid: ownerUid)),
      child: const _DriverHomeView(),
    );
  }
}

class _DriverHomeView extends StatelessWidget {
  static const _amarillo = Color(0xFFFFC12F);

  const _DriverHomeView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Unidad',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DriverVehicleBloc, DriverVehicleState>(
        builder: (context, state) {
          if (state is DriverVehicleLoading ||
              state is DriverVehicleInitial) {
            return const Center(
                child: CircularProgressIndicator(color: _amarillo));
          }
          if (state is DriverVehicleError) {
            return Center(child: Text(state.message));
          }
          if (state is DriverVehicleLoaded) {
            final vehicle = state.vehicle;
            if (vehicle == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no tienes una unidad asignada.\n'
                    'Contacta al administrador para que te asigne una.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _amarillo.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.directions_bus,
                                  color: _amarillo),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle.vehicleId,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                    '${vehicle.brand} ${vehicle.model} · ${vehicle.color}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(label: 'Línea', value: vehicle.lineNumber),
                        _InfoRow(
                            label: 'N.º interno',
                            value: vehicle.internalNumber),
                        _InfoRow(
                            label: 'Tipo', value: vehicle.vehicleType),
                        _InfoRow(
                            label: 'Capacidad',
                            value: '${vehicle.passengerCapacity} pasajeros'),
                        _InfoRow(
                          label: 'Documentación',
                          value: _statusLabel(vehicle.status),
                          valueColor: vehicle.isApproved
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.08)),
                    ),
                    child: SwitchListTile(
                      activeThumbColor: _amarillo,
                      title: const Text('Unidad activa',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(vehicle.isOnDuty
                          ? 'Visible para los pasajeros como en servicio'
                          : 'Fuera de servicio'),
                      value: vehicle.isOnDuty,
                      onChanged: (value) {
                        context.read<DriverVehicleBloc>().add(
                              ToggleOnDuty(
                                vehicleId: vehicle.vehicleId,
                                value: value,
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return 'En revisión';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }
}
