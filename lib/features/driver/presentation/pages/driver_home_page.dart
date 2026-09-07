import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_panel_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_approval_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_rutas_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_wallet_page.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_rutas_page.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/driver_service_map.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/logout_button.dart' show confirmLogout;
import 'package:mi_ruta/features/driver/presentation/pages/rate_passenger_page.dart';

class DriverHomePage extends StatelessWidget {
  /// Fuerza el rol usado para decidir si se muestran las secciones de
  /// dirigente, sin depender del `role` real de la cuenta. Solo la usa el
  /// selector de perfiles de la cuenta super-admin.
  final String? roleOverride;

  const DriverHomePage({super.key, this.roleOverride});

  static const _amarillo = Color(0xFFFFC12F);

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    final fullName = authState is AuthLoaded ? authState.user.fullName : '';
    final role = roleOverride ?? (authState is AuthLoaded ? authState.user.role : '');

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DriverServiceBloc(service: getIt<DriverService>())
            ..add(LoadAssignedVehicle(uid)),
        ),
        BlocProvider(
          create: (_) => DriverOperationsBloc(service: getIt<DriverService>()),
        ),
      ],
      child: _DriverHomeView(fullName: fullName, role: role),
    );
  }
}

class _DriverHomeView extends StatelessWidget {
  final String fullName;
  final String role;

  const _DriverHomeView({required this.fullName, required this.role});

  @override
  Widget build(BuildContext context) {
    final isSupervisor = role == 'presidente';
    final authState = context.read<AuthBloc>().state;
    final driverUid = authState is AuthLoaded ? authState.user.uid : '';

    return MultiBlocListener(
      listeners: [
        BlocListener<DriverServiceBloc, DriverServiceState>(
          listenWhen: (previous, current) =>
              current is DriverServiceLoaded && previous is! DriverServiceLoaded,
          listener: (context, state) {
            if (state is DriverServiceLoaded) {
              context.read<DriverOperationsBloc>().add(LoadDriverOperations(state.vehicle));
            }
          },
        ),
        // "3.3 Notificación Temporal": aviso breve tras iniciar/detener servicio.
        BlocListener<DriverServiceBloc, DriverServiceState>(
          listenWhen: (previous, current) =>
              previous is DriverServiceLoaded &&
              previous.isUpdating &&
              current is DriverServiceLoaded &&
              !current.isUpdating,
          listener: (context, state) {
            final vehicle = (state as DriverServiceLoaded).vehicle;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: vehicle.isOnDuty ? Colors.green.shade700 : Colors.grey.shade800,
                content: Text(
                  vehicle.isOnDuty ? 'Estado del servicio cambió a: Activo' : 'Servicio detenido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        // "¡Ruta Asignada!" — el dirigente le asigna línea a este chofer
        // mientras tiene la app abierta (o la app termina de cargarla).
        if (!isSupervisor)
          BlocListener<DriverOperationsBloc, DriverOperationsState>(
            listenWhen: (previous, current) =>
                previous is DriverOperationsLoaded &&
                previous.assignedRoute == null &&
                current is DriverOperationsLoaded &&
                current.assignedRoute != null,
            listener: (context, state) {
              final route = (state as DriverOperationsLoaded).assignedRoute!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.green.shade700,
                  content: Text(
                    '¡Ruta Asignada! ${route.name} · Línea ${route.ref}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DriverVehicleBloc, DriverVehicleState>(
        listener: (context, state) {
          if (state is DriverVehicleLoaded && state.toggleError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'No se pudo actualizar el estado de la unidad: ${state.toggleError}')),
            );
          }
        },
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
}

class _VehicleServiceSection extends StatelessWidget {
  const _VehicleServiceSection();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverServiceBloc, DriverServiceState>(
      listenWhen: (previous, current) => current is DriverServiceError,
      listener: (context, state) {
        if (state is DriverServiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DriverServiceLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: DriverHomePage._amarillo),
            ),
          );
        }
        if (state is DriverServiceNoVehicle) {
          return _NoVehicleCard();
        }
        final vehicle = state is DriverServiceLoaded
            ? state.vehicle
            : state is DriverServiceError
                ? state.vehicle
                : null;
        final isUpdating = state is DriverServiceLoaded && state.isUpdating;
        if (vehicle == null) return const SizedBox.shrink();
        final opsState = context.watch<DriverOperationsBloc>().state;
        final assignedRoute = opsState is DriverOperationsLoaded ? opsState.assignedRoute : null;
        return _VehicleCard(vehicle: vehicle, isUpdating: isUpdating, assignedRoute: assignedRoute);
      },
    );
  }
}

/// Ya no ofrece el botón "Registrar unidad" aquí — el pedido explícito fue
/// mover ese mensaje al tab Rutas, donde `DriverRutasPage` sí lo muestra
/// junto al CTA real. Inicio solo indica que hay que ir allá.
class _NoVehicleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_bus_filled_outlined,
              size: 40, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'No tienes una unidad registrada',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Ve a la pestaña Rutas para registrar tu unidad antes de iniciar servicio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final bool isUpdating;
  final RouteEntity? assignedRoute;

  const _VehicleCard({
    required this.vehicle,
    required this.isUpdating,
    this.assignedRoute,
  });

  @override
  Widget build(BuildContext context) {
    final canOperate = vehicle.isApproved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sin la card de datos de la unidad (placa/marca/estado): el mapa en
        // vivo con la posición del chofer + la ruta asignada es lo que
        // importa acá, y usa el espacio que antes ocupaba la card. El
        // status de la unidad ya se ve en el color del marcador del mapa
        // (verde/naranja) y en el propio botón de abajo.
        DriverServiceMap(
          assignedRoute: assignedRoute,
          inService: vehicle.isOnDuty,
          height: 340,
        ),
        if (!canOperate) ...[
          const SizedBox(height: 10),
          Text(
            'Esta unidad debe estar aprobada antes de poder iniciar servicio.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: !canOperate || isUpdating
                ? null
                : () => context.read<DriverServiceBloc>().add(
                      vehicle.isOnDuty ? const StopService() : const StartService(),
                    ),
            icon: isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Icon(
                    vehicle.isOnDuty ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                    color: Colors.black,
                  ),
            label: Text(
              vehicle.isOnDuty ? 'Finalizar servicio' : 'Iniciar servicio',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vehicle.isOnDuty ? Colors.grey.shade300 : DriverHomePage._amarillo,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
