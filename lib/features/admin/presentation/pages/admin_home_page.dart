import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

/// Panel de entrada del admin: unidades de transporte actualmente activas.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    final isStaticDemo = uid == kStaticDemoAdminUid;

    return BlocProvider(
      create: (_) => getIt<AdminActiveVehiclesBloc>()
        ..add(isStaticDemo
            ? const WatchStaticDemoVehicles()
            : const WatchActiveVehicles()),
      child: const _AdminHomeView(),
    );
  }
}

class _AdminHomeView extends StatelessWidget {
  static const _amarillo = Color(0xFFFFC12F);

  const _AdminHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades activas',
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
      body: BlocBuilder<AdminActiveVehiclesBloc, AdminActiveVehiclesState>(
        builder: (context, state) {
          if (state is AdminVehiclesLoading || state is AdminVehiclesInitial) {
            return const Center(
                child: CircularProgressIndicator(color: _amarillo));
          }
          if (state is AdminVehiclesError) {
            return Center(child: Text(state.message));
          }
          if (state is AdminVehiclesLoaded) {
            if (state.vehicles.isEmpty) {
              return const Center(
                child: Text('Ninguna unidad está en servicio ahora mismo.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.vehicles.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final vehicle = state.vehicles[i];
                final driver = state.driversByUid[vehicle.ownerUid];
                return _VehicleTile(vehicle: vehicle, driverName: driver?.fullName);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final VehicleEntity vehicle;
  final String? driverName;

  const _VehicleTile({required this.vehicle, this.driverName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Línea ${vehicle.lineNumber}  •  ${vehicle.vehicleId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  driverName ?? 'Chofer sin datos',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                Text(
                  '${vehicle.vehicleType} · ${vehicle.passengerCapacity} pasajeros',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'En servicio',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
