import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_assigned_routes_page.dart' show AssignedRouteCard;
import 'package:mi_ruta/features/routes/domain/entities/route_deviation_note.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_deviation_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// Al tocar una card de "Control de rutas en vivo" del presidente, abre esta
/// vista: mapa de la ruta (reusa `AssignedRouteCard`, ya lo dibuja) + notas
/// de desvío ("calle bloqueada", texto libre, informativo — no recalcula la
/// ruta). Ver docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 1.
class RutaMapaDesvioPage extends StatefulWidget {
  final String routeRef;
  final String routeName;

  const RutaMapaDesvioPage({super.key, required this.routeRef, required this.routeName});

  @override
  State<RutaMapaDesvioPage> createState() => _RutaMapaDesvioPageState();
}

class _RutaMapaDesvioPageState extends State<RutaMapaDesvioPage> {
  late Future<RouteEntity?> _routeFuture;
  late Future<List<RouteDeviationNote>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _routeFuture = getIt<RouteService>().getRouteByRef(widget.routeRef);
    _notesFuture = getIt<RouteDeviationService>().getNotesForRoute(widget.routeRef);
  }

  Future<void> _markDeviation() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marcar desvío'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ej. Calle Ayacucho bloqueada entre Av. San Martín y Plaza Principal',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (note == null || note.isEmpty || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    final reportedBy = authState is AuthLoaded ? authState.user.uid : '';
    await getIt<RouteDeviationService>().createNote(
      routeRef: widget.routeRef,
      note: note,
      reportedBy: reportedBy,
    );
    if (!mounted) return;
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.routeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: FutureBuilder<RouteEntity?>(
        future: _routeFuture,
        builder: (context, routeSnap) {
          if (routeSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _amarillo));
          }
          final route = routeSnap.data;
          if (route == null) {
            return const Center(child: Text('No se pudo cargar el trazado de esta ruta.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AssignedRouteCard(route: route),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markDeviation,
                    icon: const Icon(Icons.warning_amber_outlined, color: Colors.black),
                    label: const Text('Marcar desvío', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Desvíos reportados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                FutureBuilder<List<RouteDeviationNote>>(
                  future: _notesFuture,
                  builder: (context, notesSnap) {
                    if (notesSnap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: _amarillo)),
                      );
                    }
                    final notes = notesSnap.data ?? const [];
                    if (notes.isEmpty) {
                      return Text(
                        'Sin desvíos reportados para esta ruta.',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      );
                    }
                    return Column(
                      children: notes.map((n) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                n.active ? Icons.warning_amber_outlined : Icons.check_circle_outline,
                                size: 18,
                                color: n.active ? Colors.orange.shade700 : Colors.green.shade700,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.note, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}',
                                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await getIt<RouteDeviationService>().setActive(n.id, !n.active);
                                  if (!mounted) return;
                                  setState(_load);
                                },
                                child: Text(n.active ? 'Resolver' : 'Reabrir'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
