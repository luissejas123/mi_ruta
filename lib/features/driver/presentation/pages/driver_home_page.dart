import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_approval_page.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});

  static const _amarillo = Color(0xFFFFC12F);

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    final fullName = authState is AuthLoaded ? authState.user.fullName : '';
    final role = authState is AuthLoaded ? authState.user.role : '';

    return BlocProvider(
      create: (_) => DriverServiceBloc(service: getIt<DriverService>())
        ..add(LoadAssignedVehicle(uid)),
      child: _DriverHomeView(fullName: fullName, role: role),
    );
  }
}

class _DriverHomeView extends StatelessWidget {
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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Modo Chofer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
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
            ],
          ],
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
        return _VehicleCard(vehicle: vehicle, isUpdating: isUpdating);
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

  const _VehicleCard({required this.vehicle, required this.isUpdating});

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
                        ),
                      ],
                    ),
                  ),
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
                    ),
                  ),
                ],
              ),
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
