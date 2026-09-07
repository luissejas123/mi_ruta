import 'package:flutter/material.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// "Asignar línea a presidente" — cierra el hueco encontrado al construir
/// las 4 funciones nuevas de dirigencia (calificación de choferes, reclamos,
/// desvíos de ruta): ninguna se puede acotar por "los choferes/rutas de este
/// presidente" porque ese vínculo no existía. Mismo patrón que
/// AsignarRutaChoferPage/assignTickeador, pero de admin hacia presidente y
/// con selección múltiple (un dirigente puede gestionar más de una línea).
class AsignarLineasPresidentePage extends StatefulWidget {
  const AsignarLineasPresidentePage({super.key});

  @override
  State<AsignarLineasPresidentePage> createState() => _AsignarLineasPresidentePageState();
}

class _AsignarLineasPresidentePageState extends State<AsignarLineasPresidentePage> {
  late Future<(List<UserEntity>, List<RouteEntity>)> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<UserEntity>, List<RouteEntity>)> _load() async {
    // Sin userTypeFilter: una cuenta presidente puede tener 'role' primario
    // distinto (ej. también es chofer) — filtramos por `roles` en cliente,
    // igual que ya hace perfil_page.dart para detectar presidente.
    final allUsers = await getIt<UserManagementService>().getUsers();
    final presidentes = allUsers.where((u) => u.roles.contains('presidente')).toList();
    final routes = await getIt<RouteService>().getAllActiveRoutesLight();
    return (presidentes, routes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLinePicker(UserEntity presidente, List<RouteEntity> routes) async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LinesPickerSheet(presidente: presidente, routes: routes),
    );
    if (picked == null || !mounted) return;
    try {
      await getIt<UserManagementService>()
          .assignPresidenteLines(presidente.uid, managedLines: picked);
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            picked.isEmpty
                ? 'Se quitaron todas las líneas de ${presidente.fullName}'
                : 'Líneas ${picked.join(", ")} asignadas a ${presidente.fullName}',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo asignar: $e'),
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
          'Asignar línea a presidente',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: FutureBuilder<(List<UserEntity>, List<RouteEntity>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final (presidentes, routes) = snapshot.data!;
          final visible = _query.isEmpty
              ? presidentes
              : presidentes.where((p) {
                  final q = _query.toLowerCase();
                  return p.fullName.toLowerCase().contains(q) ||
                      p.email.toLowerCase().contains(q);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar presidente por nombre o correo...',
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
                          'No hay cuentas con rol presidente',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: visible.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final presidente = visible[i];
                          return Material(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openLinePicker(presidente, routes),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _amarillo,
                                      child: const Icon(Icons.groups_outlined, color: Colors.black, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            presidente.fullName.isNotEmpty
                                                ? presidente.fullName
                                                : presidente.email,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            presidente.managedLines.isEmpty
                                                ? 'Sin línea asignada'
                                                : 'Líneas: ${presidente.managedLines.join(", ")}',
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

class _LinesPickerSheet extends StatefulWidget {
  final UserEntity presidente;
  final List<RouteEntity> routes;

  const _LinesPickerSheet({required this.presidente, required this.routes});

  @override
  State<_LinesPickerSheet> createState() => _LinesPickerSheetState();
}

class _LinesPickerSheetState extends State<_LinesPickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.presidente.managedLines.toSet();
  }

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
              'Líneas de '
              '${widget.presidente.fullName.isNotEmpty ? widget.presidente.fullName : widget.presidente.email}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Un dirigente puede gestionar más de una línea.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.routes.length,
                separatorBuilder: (context, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final route = widget.routes[i];
                  return CheckboxListTile(
                    value: _selected.contains(route.ref),
                    title: Text('${route.name} · Línea ${route.ref}'),
                    activeColor: _amarillo,
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(route.ref);
                      } else {
                        _selected.remove(route.ref);
                      }
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected.toList()),
                style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                child: const Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
