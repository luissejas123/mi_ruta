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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_dashboard_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_dashboard_state.dart';
import 'package:mi_ruta/features/admin/presentation/pages/user_management_page.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

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

const _amarillo = Color(0xFFFFC12F);

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final fullName = authState is AuthLoaded ? authState.user.fullName : '';

    return BlocProvider(
      create: (_) => AdminDashboardBloc(service: getIt<AdminService>())
        ..add(const LoadActiveVehicles()),
      child: _AdminHomeView(fullName: fullName),
    );
  }
}

class _AdminHomeView extends StatelessWidget {
  final String fullName;

  const _AdminHomeView({required this.fullName});

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Panel de administración',
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
              'Hola, ${fullName.isNotEmpty ? fullName : 'administrador'} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _UserManagementCard(),
            const SizedBox(height: 16),
            const _ActiveVehiclesCard(),
            const SizedBox(height: 16),
            const _PrivilegesCard(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => navigateBottomNav(
          context,
          index,
          homeBuilder: (_) => const AdminHomePage(),
        ),
      ),
    );
  }
}

class _UserManagementCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          color: _amarillo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.manage_accounts_outlined, color: Colors.black, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Gestión de usuarios',
                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ActiveVehiclesCard extends StatelessWidget {
  const _ActiveVehiclesCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
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
              Icon(Icons.directions_bus_filled_outlined,
                  size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              const Text('Unidades activas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
            builder: (context, state) {
              if (state is AdminDashboardLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: _amarillo)),
                );
              }
              if (state is AdminDashboardError) {
                return Text(state.message, style: TextStyle(fontSize: 12, color: Colors.red.shade400));
              }
              if (state is AdminDashboardLoaded) {
                if (state.activeVehicles.isEmpty) {
                  return Text(
                    'Ninguna unidad está en servicio en este momento.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  );
                }
                return Column(
                  children: state.activeVehicles
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${v.brand} ${v.model} · Placa ${v.vehicleId}'.trim(),
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Línea ${v.lineNumber}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _PrivilegesCard extends StatelessWidget {
  const _PrivilegesCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
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
              Icon(Icons.verified_user_outlined,
                  size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              const Text('Mis privilegios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rol: Administrador\n'
            '• Aprobar o bloquear cualquier cuenta (pasajero, chofer, tickeador)\n'
            '• Ver unidades en servicio en tiempo real\n'
            '• La creación de nuevas cuentas de administrador se gestiona manualmente '
            'desde la consola de Firebase.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
          ),
        ],
      ),
    );
  }
}
