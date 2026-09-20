import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_service.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_bloc.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_state.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_panel_page.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

const _amarillo = Color(0xFFFFC12F);

/// Tab "Rutas" del dirigente — antes tocar "Rutas" solo volvía a redibujar
/// el panel de dirigencia entero. "Control de rutas en vivo" vive aquí,
/// separado de "Panel de dirigencia" (que se queda con Reporte operativo +
/// Gestión de personal).
class PresidenteRutasPage extends StatelessWidget {
  const PresidenteRutasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PresidentePanelBloc(
        adminService: getIt<AdminService>(),
        routeService: getIt<RouteService>(),
      )..add(const LoadPresidentePanel()),
      child: const _PresidenteRutasView(),
    );
  }
}

class _PresidenteRutasView extends StatelessWidget {
  const _PresidenteRutasView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Control de rutas en vivo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: RouteControlSection(state: state, expand: true),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        tabs: const [0, 2, 3],
        onTap: (index) => navigateBottomNav(
          context,
          index,
          homeBuilder: (_) => const DriverHomePage(roleOverride: 'presidente'),
          routesBuilder: (_) => const PresidenteRutasPage(),
        ),
      ),
    );
  }
}
