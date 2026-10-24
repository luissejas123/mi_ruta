import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/user/domain/services/claim_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// Sin este formulario, "Reclamos" del presidente muestra una lista vacía
/// para siempre — `claims` no tenía ningún escritor (ver
/// FIRESTORE_COLLECTIONS_GUIDE.md). Versión mínima: tipo + línea + título +
/// descripción. No pide adjuntar evidencia/fotos — eso no se pidió y no lo
/// bloquea (Pereza).
class CrearReclamoPage extends StatefulWidget {
  const CrearReclamoPage({super.key});

  @override
  State<CrearReclamoPage> createState() => _CrearReclamoPageState();
}

class _CrearReclamoPageState extends State<CrearReclamoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _claimType = 'service';
  RouteEntity? _selectedRoute;
  List<RouteEntity> _routes = const [];
  bool _loadingRoutes = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final routes = await getIt<RouteService>().getAllActiveRoutesLight();
    if (!mounted) return;
    setState(() {
      _routes = routes;
      _loadingRoutes = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) return;
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el título y la descripción.')),
      );
      return;
    }
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige la línea a la que corresponde el reclamo.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await getIt<ClaimService>().createClaim(
        reporterId: authState.user.uid,
        lineId: _selectedRoute!.ref,
        claimType: _claimType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclamo enviado. El dirigente de tu línea lo revisará.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el reclamo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nuevo reclamo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: _loadingRoutes
          ? const Center(child: CircularProgressIndicator(color: _amarillo))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de reclamo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'driver', label: Text('Chofer')),
                      ButtonSegment(value: 'user', label: Text('Pasajero')),
                      ButtonSegment(value: 'service', label: Text('Servicio')),
                    ],
                    selected: {_claimType},
                    onSelectionChanged: (s) => setState(() => _claimType = s.first),
                  ),
                  const SizedBox(height: 16),
                  const Text('Línea', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RouteEntity>(
                    initialValue: _selectedRoute,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    hint: const Text('Elige la línea'),
                    items: _routes
                        .map((r) => DropdownMenuItem(value: r, child: Text('${r.name} · Línea ${r.ref}')))
                        .toList(),
                    onChanged: (r) => setState(() => _selectedRoute = r),
                  ),
                  const SizedBox(height: 16),
                  const Text('Título', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Resumen breve',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Cuéntanos qué pasó',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amarillo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Enviar reclamo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
