import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
<<<<<<< HEAD
<<<<<<< HEAD
=======
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
>>>>>>> origin/pedro-integracion-jesus
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/presentation/pages/user_management_page.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_panel_page.dart';
=======
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
>>>>>>> origin/adolfo-dev
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
<<<<<<< HEAD
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_approval_page.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/driver_service_map.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_trip_history_page.dart';

class DriverHomePage extends StatelessWidget {
  /// Fuerza el rol usado para decidir si se muestran las secciones de
  /// dirigente, sin depender del `role` real de la cuenta. Solo la usa el
  /// selector de perfiles de la cuenta super-admin.
  final String? roleOverride;

  const DriverHomePage({super.key, this.roleOverride});

  static const _amarillo = Color(0xFFFFC12F);
=======
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_state.dart';

/// Panel de entrada del chofer: gestión de la unidad que tiene asignada.
class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});
>>>>>>> origin/adolfo-dev

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
<<<<<<< HEAD
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
=======
    final ownerUid = authState is AuthLoaded ? authState.user.uid : '';
    final isStaticDemo = ownerUid == kStaticDemoDriverUid;

    return BlocProvider(
      create: (_) => getIt<DriverVehicleBloc>()
        ..add(isStaticDemo
            ? const LoadStaticDemoVehicle()
            : StartMyVehicleStream(ownerUid: ownerUid)),
      child: const _DriverHomeView(),
>>>>>>> origin/adolfo-dev
    );
  }
}

class _DriverHomeView extends StatelessWidget {
<<<<<<< HEAD
  final String fullName;
  final String role;

  const _DriverHomeView({required this.fullName, required this.role});

  void _cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = role == 'presidente';

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
                backgroundColor: vehicle.inService ? Colors.green.shade700 : Colors.grey.shade800,
                content: Text(
                  vehicle.inService ? 'Servicio iniciado' : 'Servicio detenido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Modo Chofer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            const SwitchProfileButton(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _cerrarSesion(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${fullName.isNotEmpty ? fullName : 'chofer'} 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isSupervisor ? 'Dirigente' : 'Chofer',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              const _VehicleServiceSection(),
              if (isSupervisor) ...[
                const SizedBox(height: 24),
                _SupervisorSection(),
                const SizedBox(height: 12),
                _UserManagementSection(),
                const SizedBox(height: 12),
                _PresidentePanelSection(),
              ],
              const SizedBox(height: 24),
              _DriverOperationsSections(fullName: fullName),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 0,
          onTap: (index) => navigateBottomNav(
            context,
            index,
            homeBuilder: (_) => DriverHomePage(roleOverride: role),
          ),
        ),
      ),
    );
  }
}

class _SupervisorSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DriverApprovalPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DriverHomePage._amarillo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.how_to_reg_outlined, color: Colors.black, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Aprobar o bloquear choferes',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserManagementPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DriverHomePage._amarillo, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.manage_accounts_outlined, color: colorScheme.onSurface, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Gestión de usuarios (todos los roles)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}

class _PresidentePanelSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PresidentePanelPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DriverHomePage._amarillo, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics_outlined, color: colorScheme.onSurface, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Panel de dirigencia (rutas y reportes)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
          ],
        ),
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
            'No tienes una unidad asignada',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Contacta a tu dirigente para que te asigne un vehículo antes de iniciar servicio.',
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

  Color _statusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.approved:
        return Colors.green;
      case VehicleStatus.pendingReview:
        return Colors.orange;
      case VehicleStatus.rejected:
        return Colors.red;
    }
  }

  String _statusLabel(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.approved:
        return 'Aprobada';
      case VehicleStatus.pendingReview:
        return 'En revisión';
      case VehicleStatus.rejected:
        return 'Rechazada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canOperate = vehicle.status == VehicleStatus.approved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DriverServiceMap(assignedRoute: assignedRoute, inService: vehicle.inService),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: DriverHomePage._amarillo,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.brand} ${vehicle.model}'.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Placa ${vehicle.vehicleId} · Línea ${vehicle.lineNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
=======
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
>>>>>>> origin/adolfo-dev
                        ),
                      ],
                    ),
                  ),
<<<<<<< HEAD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(vehicle.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(vehicle.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(vehicle.status),
                      ),
=======
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
>>>>>>> origin/adolfo-dev
                    ),
                  ),
                ],
              ),
<<<<<<< HEAD
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estado del servicio',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: vehicle.inService ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicle.inService ? 'En servicio' : 'Fuera de servicio',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              if (!canOperate) ...[
                const SizedBox(height: 10),
                Text(
                  'Esta unidad debe estar aprobada antes de poder iniciar servicio.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: !canOperate || isUpdating
                ? null
                : () => context.read<DriverServiceBloc>().add(
                      vehicle.inService ? const StopService() : const StartService(),
                    ),
            icon: isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Icon(
                    vehicle.inService ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                    color: Colors.black,
                  ),
            label: Text(
              vehicle.inService ? 'Finalizar servicio' : 'Iniciar servicio',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vehicle.inService ? Colors.grey.shade300 : DriverHomePage._amarillo,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});
=======
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
>>>>>>> origin/adolfo-dev

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
<<<<<<< HEAD
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DriverOperationsSections extends StatelessWidget {
  final String fullName;

  const _DriverOperationsSections({required this.fullName});

  @override
  Widget build(BuildContext context) {
    // 1. Obtener el vehículo más actualizado desde DriverServiceBloc
    final serviceState = context.watch<DriverServiceBloc>().state;
    final freshVehicle = serviceState is DriverServiceLoaded ? serviceState.vehicle : null;

    return BlocConsumer<DriverOperationsBloc, DriverOperationsState>(
      listenWhen: (previous, current) {
        if (current is DriverOperationsError) return true;
        if (previous is DriverOperationsLoaded && current is DriverOperationsLoaded) {
          return current.lastPaymentReceivedAmount != previous.lastPaymentReceivedAmount;
        }
        return false;
      },
      listener: (context, state) {
        if (state is DriverOperationsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red.shade700),
          );
        } else if (state is DriverOperationsLoaded && state.lastPaymentReceivedAmount != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('¡Pago de Bs. ${state.lastPaymentReceivedAmount!.toStringAsFixed(2)} recibido!'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
          // Opcionalmente podemos "limpiar" este valor del estado disparando un evento,
          // o simplemente confiar en que el listenWhen no se volverá a disparar a menos que cambie.
        }
      },
      builder: (context, state) {
        if (state is DriverOperationsLoading || state is DriverOperationsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: DriverHomePage._amarillo)),
          );
        }

        if (state is DriverOperationsError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text('Error al cargar datos:\n${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      if (freshVehicle != null) {
                        context.read<DriverOperationsBloc>().add(LoadDriverOperations(freshVehicle));
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  )
                ],
              ),
            ),
          );
        }

        if (state is! DriverOperationsLoaded) return const SizedBox.shrink();

        // Usar el vehículo fresco si está disponible, sino el del state
        final activeVehicle = freshVehicle ?? state.vehicle;
        final canOperate = activeVehicle.status == VehicleStatus.approved;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Ruta asignada',
              icon: Icons.alt_route,
              child: state.assignedRoute != null
                  ? Text(
                      '${state.assignedRoute!.name} · Línea ${state.assignedRoute!.ref}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  : Text(
                      'No se encontró una ruta activa con línea "${activeVehicle.lineNumber}".',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
            ),
            _VehicleInfoEditSection(vehicle: activeVehicle, isBusy: state.isBusy),
            _ChargeSection(state: state),
            _NotifyStopSection(state: state),
            _PerformanceSection(state: state),
            _TripHistorySection(trips: state.trips),
            _IncomeHistorySection(income: state.incomeTransactions),
            _SectionCard(
              title: 'Descargar historial',
              icon: Icons.picture_as_pdf_outlined,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isBusy
                      ? null
                      : () => context
                          .read<DriverOperationsBloc>()
                          .add(DownloadTripHistory(fullName.isNotEmpty ? fullName : 'Chofer')),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Generar y compartir PDF'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Historial de viajes completo',
              icon: Icons.history,
              child: InkWell(
                onTap: () {
                  final authState = context.read<AuthBloc>().state;
                  final uid = authState is AuthLoaded ? authState.user.uid : '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverTripHistoryPage(driverId: uid),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ver todo el historial',
                        style: TextStyle(fontSize: 14),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VehicleInfoEditSection extends StatefulWidget {
  final VehicleEntity vehicle;
  final bool isBusy;

  const _VehicleInfoEditSection({required this.vehicle, required this.isBusy});

  @override
  State<_VehicleInfoEditSection> createState() => _VehicleInfoEditSectionState();
}

class _VehicleInfoEditSectionState extends State<_VehicleInfoEditSection> {
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _internalNumberCtrl;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController(text: widget.vehicle.brand);
    _modelCtrl = TextEditingController(text: widget.vehicle.model);
    _colorCtrl = TextEditingController(text: widget.vehicle.color);
    _internalNumberCtrl = TextEditingController(text: widget.vehicle.internalNumber);
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _internalNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Datos de la unidad',
      icon: Icons.edit_note,
      child: Column(
        children: [
          _EditField(label: 'Marca', controller: _brandCtrl),
          const SizedBox(height: 10),
          _EditField(label: 'Modelo', controller: _modelCtrl),
          const SizedBox(height: 10),
          _EditField(label: 'Color', controller: _colorCtrl),
          const SizedBox(height: 10),
          _EditField(label: 'Número interno', controller: _internalNumberCtrl),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isBusy
                  ? null
                  : () => context.read<DriverOperationsBloc>().add(
                        UpdateVehicleInfo(
                          brand: _brandCtrl.text.trim(),
                          model: _modelCtrl.text.trim(),
                          color: _colorCtrl.text.trim(),
                          internalNumber: _internalNumberCtrl.text.trim(),
                        ),
                      ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _EditField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ChargeSection extends StatefulWidget {
  final DriverOperationsLoaded state;

  const _ChargeSection({required this.state});

  @override
  State<_ChargeSection> createState() => _ChargeSectionState();
}

class _ChargeSectionState extends State<_ChargeSection> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return _SectionCard(
      title: 'Cobro de viaje',
      icon: Icons.qr_code_2,
      child: state.activeChargeQr != null
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(data: state.activeChargeQr!, size: 200),
                ),
                const SizedBox(height: 10),
                Text(
                  'Monto: Bs. ${state.activeChargeAmount?.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'El pasajero escanea este código para pagar.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () =>
                        context.read<DriverOperationsBloc>().add(const ClearTripCharge()),
                    child: const Text('Cerrar cobro'),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto (Bs.)',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () {
                            final amount = double.tryParse(_amountCtrl.text.trim());
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingresa un monto válido.')),
                              );
                              return;
                            }
                            context
                                .read<DriverOperationsBloc>()
                                .add(GenerateTripCharge(amount));
                          },
                    icon: const Icon(Icons.qr_code, color: Colors.black),
                    label: const Text(
                      'Generar código de cobro',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverHomePage._amarillo,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotifyStopSection extends StatefulWidget {
  final DriverOperationsLoaded state;

  const _NotifyStopSection({required this.state});

  @override
  State<_NotifyStopSection> createState() => _NotifyStopSectionState();
}

class _NotifyStopSectionState extends State<_NotifyStopSection> {
  final _stopCtrl = TextEditingController();

  @override
  void dispose() {
    _stopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return _SectionCard(
      title: 'Notificar parada',
      icon: Icons.campaign_outlined,
      child: Column(
        children: [
          TextField(
            controller: _stopCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre de la parada',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () {
                      final stop = _stopCtrl.text.trim();
                      if (stop.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa el nombre de la parada.')),
                        );
                        return;
                      }
                      context.read<DriverOperationsBloc>().add(NotifyStop(stop));
                    },
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Avisar a pasajeros a bordo'),
            ),
          ),
          if (state.lastStopNotifiedCount != null) ...[
            const SizedBox(height: 8),
            Text(
              state.lastStopNotifiedCount! > 0
                  ? 'Se avisó a ${state.lastStopNotifiedCount} pasajero(s).'
                  : 'No hay pasajeros recientes a bordo de esta unidad para notificar.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  final DriverOperationsLoaded state;

  const _PerformanceSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final performance = state.performance;
    return _SectionCard(
      title: 'Rendimiento',
      icon: Icons.insights_outlined,
      child: Row(
        children: [
          Expanded(child: _StatTile(label: 'Viajes', value: '${performance.totalTrips}')),
          Expanded(child: _StatTile(label: 'Pagados', value: '${performance.paidTrips}')),
          Expanded(
            child: _StatTile(
              label: 'Promedio',
              value: 'Bs. ${performance.averageFare.toStringAsFixed(2)}',
            ),
          ),
=======
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
>>>>>>> origin/adolfo-dev
        ],
      ),
    );
  }
}
<<<<<<< HEAD

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _TripHistorySection extends StatelessWidget {
  final List<DriverTripEntity> trips;

  const _TripHistorySection({required this.trips});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Historial de viajes',
      icon: Icons.history,
      child: trips.isEmpty
          ? Text(
              'Todavía no generaste ningún cobro de viaje.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : Column(
              children: trips
                  .take(5)
                  .map(
                    (t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (t.isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              t.isPaid ? Icons.check_circle : Icons.pending,
                              size: 16,
                              color: t.isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.routeName.isNotEmpty ? t.routeName : t.routeRef,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.isPaid ? 'Cobro completado' : 'Pendiente de pago',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+ Bs. ${(t.paymentAmount ?? t.baseFare).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: t.isPaid ? Colors.green.shade700 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _IncomeHistorySection extends StatelessWidget {
  final List<Map<String, dynamic>> income;

  const _IncomeHistorySection({required this.income});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ingresos recientes',
      icon: Icons.payments_outlined,
      child: income.isEmpty
          ? Text(
              'Todavía no recibiste pagos.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          : Column(
              children: income
                  .take(5)
                  .map(
                    (tx) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tx['description']?.toString() ?? 'Pago de viaje',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '+ Bs. ${((tx['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
=======
>>>>>>> origin/adolfo-dev
