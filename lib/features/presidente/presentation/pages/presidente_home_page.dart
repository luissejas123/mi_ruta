import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/debug/static_test_accounts.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/presidente/domain/services/presidente_dashboard_service.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_dashboard_bloc.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_dashboard_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_dashboard_state.dart';
import 'package:mi_ruta/features/presidente/presentation/widgets/empty_section_placeholder.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class PresidenteHomePage extends StatelessWidget {
  const PresidenteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PresidenteDashboardBloc(
        service: getIt<PresidenteDashboardService>(),
      )..add(const LoadRoutesOverview()),
      child: const _PresidenteHomeView(),
    );
  }
}

class _PresidenteHomeView extends StatelessWidget {
  const _PresidenteHomeView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Supervisión y control',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Color(0xFFFFC12F),
            tabs: [
              Tab(text: 'Rutas'),
              Tab(text: 'Unidades'),
              Tab(text: 'Reportes'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () =>
                  context.read<AuthBloc>().add(const LogoutEvent()),
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            final authState = context.watch<AuthBloc>().state;
            final isMockMode =
                authState is AuthLoaded &&
                authState.user.uid == testPresidenteUid;
            return TabBarView(
              children: [
                const _RoutesTab(),
                _UnitsTab(isMockMode: isMockMode),
                _ReportsTab(isMockMode: isMockMode),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoutesTab extends StatelessWidget {
  const _RoutesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PresidenteDashboardBloc, PresidenteDashboardState>(
      builder: (context, state) {
        if (state is PresidenteDashboardLoading ||
            state is PresidenteDashboardInitial) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
          );
        }
        if (state is PresidenteDashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
              ],
            ),
          );
        }
        final routes = (state as PresidenteDashboardLoaded).routes;
        if (routes.isEmpty) {
          return const EmptySectionPlaceholder(
            icon: Icons.route_outlined,
            title: 'Sin rutas registradas',
            message: 'Aún no hay rutas sincronizadas para mostrar.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: routes.length,
          separatorBuilder: (context, i) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _RouteCard(route: routes[i]),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteEntity route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC12F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Línea ${route.ref}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: route.active
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              route.active ? 'Activa' : 'Inactiva',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: route.active
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsTab extends StatelessWidget {
  final bool isMockMode;
  const _UnitsTab({required this.isMockMode});

  @override
  Widget build(BuildContext context) {
    if (!isMockMode) {
      return const EmptySectionPlaceholder(
        icon: Icons.directions_bus_filled_outlined,
        title: 'Sin unidades registradas',
        message: 'La gestión de unidades aún no está disponible.',
      );
    }
    return Column(
      children: [
        const _MockModeBanner(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staticTestVehicles.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _VehicleCard(vehicle: staticTestVehicles[i]),
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final MockVehicleUnit vehicle;
  const _VehicleCard({required this.vehicle});

  MaterialColor _statusColor() {
    switch (vehicle.status) {
      case 'Activa':
        return Colors.green;
      case 'Mantenimiento':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC12F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_filled,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.plate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.routeRef} · ${vehicle.driverName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vehicle.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  final bool isMockMode;
  const _ReportsTab({required this.isMockMode});

  @override
  Widget build(BuildContext context) {
    if (!isMockMode) {
      return const EmptySectionPlaceholder(
        icon: Icons.bar_chart_outlined,
        title: 'Sin reportes disponibles',
        message: 'Aún no hay reportes generados para mostrar.',
      );
    }
    return Column(
      children: [
        const _MockModeBanner(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: staticTestReports.length,
            itemBuilder: (context, i) =>
                _ReportStatCard(stat: staticTestReports[i]),
          ),
        ),
      ],
    );
  }
}

class _ReportStatCard extends StatelessWidget {
  final MockReportStat stat;
  const _ReportStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, color: const Color(0xFFFFC12F), size: 28),
          const SizedBox(height: 10),
          Text(
            stat.value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            stat.title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockModeBanner extends StatelessWidget {
  const _MockModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC12F).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFC12F).withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.black87),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Datos de ejemplo — modo prueba, no conectado a Firestore',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
