import 'package:flutter/material.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_assigned_routes_page.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// "Ver recorrido y línea del chofer" — herramienta del dirigente, no del
/// propio chofer (antes vivía duplicada en el perfil del chofer, yendo a la
/// misma pantalla que "Ruta asignada"). Elegís un chofer de la lista y ves
/// su línea + recorrido actual, de solo lectura — para asignar/cambiar la
/// línea está "Asignar ruta a chofer" (`AsignarRutaChoferPage`).
class VerRutaChoferPage extends StatefulWidget {
  const VerRutaChoferPage({super.key});

  @override
  State<VerRutaChoferPage> createState() => _VerRutaChoferPageState();
}

class _VerRutaChoferPageState extends State<VerRutaChoferPage> {
  late Future<List<UserEntity>> _driversFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _driversFuture = getIt<UserManagementService>().getUsers(userTypeFilter: 'driver');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Ver ruta de un chofer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: FutureBuilder<List<UserEntity>>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          final drivers = snapshot.data ?? const <UserEntity>[];
          final visible = _query.isEmpty
              ? drivers
              : drivers.where((d) {
                  final q = _query.toLowerCase();
                  return d.fullName.toLowerCase().contains(q) || d.email.toLowerCase().contains(q);
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _DriverRouteDetailPage(driver: driver),
                                ),
                              ),
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

class _DriverRouteDetailPage extends StatefulWidget {
  final UserEntity driver;
  const _DriverRouteDetailPage({required this.driver});

  @override
  State<_DriverRouteDetailPage> createState() => _DriverRouteDetailPageState();
}

class _DriverRouteDetailPageState extends State<_DriverRouteDetailPage> {
  late Future<RouteEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RouteEntity?> _load() async {
    final service = getIt<DriverService>();
    final vehicle = await service.getAssignedVehicle(widget.driver.uid);
    if (vehicle == null) return null;
    return service.getAssignedRoute(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.driver.fullName.isNotEmpty ? widget.driver.fullName : widget.driver.email;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: FutureBuilder<RouteEntity?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          final route = snapshot.data;
          if (route == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$name todavía no tiene línea ni unidad asignada.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AssignedRouteCard(route: route),
          );
        },
      ),
    );
  }
}
