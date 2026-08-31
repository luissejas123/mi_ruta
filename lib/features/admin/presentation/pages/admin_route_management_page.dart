import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_access_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_state.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_route_form_page.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class AdminRouteManagementPage extends StatefulWidget {
  const AdminRouteManagementPage({super.key});

  @override
  State<AdminRouteManagementPage> createState() =>
      _AdminRouteManagementPageState();
}

class _AdminRouteManagementPageState extends State<AdminRouteManagementPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<RouteManagementBloc>().add(const LoadAdminRoutesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmLoadFromGtfs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cargar rutas desde GTFS'),
        content: const Text(
          'Se cargarán las rutas del GTFS bundleado en los assets '
          'hacia la colección Firestore "routes". ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cargar',
              style: TextStyle(color: Color(0xFFFFC12F)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<RouteManagementBloc>().add(const LoadRoutesFromGtfsAdminEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded || !authState.user.canManageRoutes) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de rutas')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.black38),
                SizedBox(height: 12),
                Text(
                  'No tienes permiso para gestionar rutas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de rutas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Cargar rutas desde GTFS',
            onPressed: _confirmLoadFromGtfs,
          ),
        ],
      ),
      body: BlocConsumer<RouteManagementBloc, RouteManagementState>(
        listener: (context, state) {
          if (state is RouteManagementSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          if (state is RouteManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RouteManagementLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is RouteManagementError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<RouteManagementBloc>()
                          .add(const LoadAdminRoutesEvent()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! AdminRoutesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final visible = state.filteredRoutes;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o número de ruta...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<RouteManagementBloc>()
                                  .add(const SearchAdminRoutesEvent(''));
                            },
                          ),
                  ),
                  onChanged: (value) => context
                      .read<RouteManagementBloc>()
                      .add(SearchAdminRoutesEvent(value)),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron rutas',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => context
                            .read<RouteManagementBloc>()
                            .add(const LoadAdminRoutesEvent()),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final route = visible[index];
                            return _RouteTile(
                              route: route,
                              onTap: () async {
                                final bloc = context.read<RouteManagementBloc>();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: bloc,
                                      child: AdminRouteFormPage(
                                        route: route,
                                      ),
                                    ),
                                  ),
                                );
                                // RouteManagementBloc es singleton compartido con
                                // AdminRouteFormPage: si se vuelve sin guardar,
                                // el estado no cambia solo, pero si se sale en
                                // medio de un guardado el builder puede quedar
                                // esperando AdminRoutesLoaded para siempre.
                                bloc.add(const LoadAdminRoutesEvent());
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva_ruta',
        backgroundColor: const Color(0xFFFFC12F),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva ruta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final bloc = context.read<RouteManagementBloc>();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const AdminRouteFormPage(),
              ),
            ),
          );
          bloc.add(const LoadAdminRoutesEvent());
        },
      ),
      // Antes esta pantalla no tenía barra propia: al llegar desde el tab
      // "Rutas" del admin, la navegación entera desaparecía hasta volver
      // atrás — el bug reportado. Misma barra que AdminHomePage.
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        tabs: const [0, 2, 3],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pop();
              break;
            case 2:
              break; // ya estamos en Rutas
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PerfilPage(homeBuilder: (_) => const AdminHomePage()),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  final RouteEntity route;
  final VoidCallback onTap;

  const _RouteTile({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _parseColor(route.color),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          route.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Ref: ${route.ref} · ID: ${route.id}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: route.active
                ? const Color(0xFFFFC12F)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            route.active ? 'ACTIVA' : 'INACTIVA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: route.active ? Colors.black : Colors.black54,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFFFC12F);
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed != null ? Color(parsed) : const Color(0xFFFFC12F);
  }
}
