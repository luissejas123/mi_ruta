import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_service.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_bloc.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_state.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

const _amarillo = Color(0xFFFFC12F);

/// Panel de solo lectura para el dirigente (RQ-76 control de rutas/unidades,
/// RQ-77 reportes operativos, RQ-80 panel de presidente). La aprobación de
/// usuarios (RQ-71/72) ya es accesible desde el home de chofer/dirigente.
class PresidentePanelPage extends StatelessWidget {
  const PresidentePanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PresidentePanelBloc(
        adminService: getIt<AdminService>(),
        routeService: getIt<RouteService>(),
      )..add(const LoadPresidentePanel()),
      child: const _PresidentePanelView(),
    );
  }
}

class _PresidentePanelView extends StatelessWidget {
  const _PresidentePanelView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Panel de dirigencia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: const [SwitchProfileButton()],
      ),
      body: BlocBuilder<PresidentePanelBloc, PresidentePanelState>(
        builder: (context, state) {
          if (state is PresidentePanelLoading) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          if (state is PresidentePanelError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }
          if (state is PresidentePanelLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<PresidentePanelBloc>().add(const LoadPresidentePanel()),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Reporte operativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _StatsGrid(state: state),
                  const SizedBox(height: 24),
                  const Text('Control de rutas en vivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _RouteControlSection(state: state),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => navigateBottomNav(
          context,
          index,
          homeBuilder: (_) => const DriverHomePage(roleOverride: 'presidente'),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final PresidentePanelLoaded state;

  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.directions_bus, 'Unidades en servicio', '${state.activeVehicles.length}'),
      (Icons.check_circle_outline, 'Unidades aprobadas', '${state.approvedVehicles}'),
      (Icons.pending_outlined, 'Unidades en revisión', '${state.pendingVehicles}'),
      (Icons.cancel_outlined, 'Unidades rechazadas', '${state.rejectedVehicles}'),
      (Icons.people_outline, 'Choferes registrados', '${state.totalDrivers}'),
      (Icons.groups_outlined, 'Pasajeros registrados', '${state.totalPassengers}'),
      (Icons.confirmation_num_outlined, 'Tickeadores', '${state.totalTickeadores}'),
      (Icons.block_outlined, 'Cuentas bloqueadas', '${state.blockedUsers}'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, i) {
        final (icon, label, value) = items[i];
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              const Spacer(),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RouteControlSection extends StatelessWidget {
  final PresidentePanelLoaded state;

  const _RouteControlSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (state.activeRoutes.isEmpty) {
      return Text(
        'No hay rutas activas registradas.',
        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
      );
    }
    final byLine = state.activeVehiclesByLine;
    return Column(
      children: state.activeRoutes.map((route) {
        final count = byLine[route.ref] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${route.name} · Línea ${route.ref}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count unidad${count == 1 ? '' : 'es'} en ruta',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
