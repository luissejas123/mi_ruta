import 'package:flutter/material.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// "Asignar ruta a chofer" (RQ4-PRE): el presidente asigna una ruta al
/// PERFIL del chofer, no a la unidad — el chofer elige por su cuenta qué
/// vehículo usar para esa ruta (ver DriverService.getAssignedRoute).
class AsignarRutaChoferPage extends StatefulWidget {
  const AsignarRutaChoferPage({super.key});

  @override
  State<AsignarRutaChoferPage> createState() => _AsignarRutaChoferPageState();
}

class _AsignarRutaChoferPageState extends State<AsignarRutaChoferPage> {
  late Future<(List<UserEntity>, List<RouteEntity>)> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<UserEntity>, List<RouteEntity>)> _load() async {
    final drivers = await getIt<UserManagementService>()
        .getUsers(userTypeFilter: 'driver');
    final routes = await getIt<RouteService>().getAllActiveRoutesLight();
    return (drivers, routes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openRoutePicker(UserEntity driver, List<RouteEntity> routes) async {
    final picked = await showModalBottomSheet<RouteEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RoutePickerSheet(driver: driver, routes: routes),
    );
    if (picked == null || !mounted) return;
    try {
      await getIt<UserManagementService>()
          .assignRouteToDriver(driver.uid, picked.ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Línea ${picked.ref} asignada a '
            '${driver.fullName.isNotEmpty ? driver.fullName : driver.email}',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo asignar la ruta: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Asignar ruta a chofer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: FutureBuilder<(List<UserEntity>, List<RouteEntity>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: _amarillo),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final (drivers, routes) = snapshot.data!;
          final visible = _query.isEmpty
              ? drivers
              : drivers.where((d) {
                  final q = _query.toLowerCase();
                  return d.fullName.toLowerCase().contains(q) ||
                      d.email.toLowerCase().contains(q);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar chofer por nombre o correo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (routes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No hay líneas activas cargadas todavía.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          'No hay choferes registrados',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final driver = visible[i];
                          return Material(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: routes.isEmpty
                                  ? null
                                  : () => _openRoutePicker(driver, routes),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _amarillo,
                                      backgroundImage: driver.profileImageUrl.isNotEmpty
                                          ? NetworkImage(driver.profileImageUrl)
                                          : null,
                                      child: driver.profileImageUrl.isEmpty
                                          ? const Icon(Icons.person, color: Colors.black, size: 20)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driver.fullName.isNotEmpty ? driver.fullName : driver.email,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            driver.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoutePickerSheet extends StatelessWidget {
  final UserEntity driver;
  final List<RouteEntity> routes;

  const _RoutePickerSheet({required this.driver, required this.routes});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elegir línea para '
              '${driver.fullName.isNotEmpty ? driver.fullName : driver.email}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'El chofer elige por su cuenta qué vehículo usar para esta línea.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: routes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final route = routes[i];
                  return ListTile(
                    title: Text('${route.name} · Línea ${route.ref}'),
                    onTap: () => Navigator.pop(context, route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
