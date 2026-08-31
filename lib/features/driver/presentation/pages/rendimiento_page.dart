import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// "RENDIMIENTO" de la billetera del chofer (Figma). Reusa las mismas
/// funciones puras que ya calculan el resumen en Inicio
/// (`DriverService.getTripHistory` + `buildPerformanceSummary`) — sin
/// bloc/estado nuevo, solo su propia pantalla.
class RendimientoPage extends StatefulWidget {
  const RendimientoPage({super.key});

  @override
  State<RendimientoPage> createState() => _RendimientoPageState();
}

class _RendimientoPageState extends State<RendimientoPage> {
  bool _loading = true;
  String? _error;
  DriverPerformanceSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    try {
      final service = getIt<DriverService>();
      final trips = await service.getTripHistory(uid);
      if (!mounted) return;
      setState(() {
        _summary = service.buildPerformanceSummary(trips);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el rendimiento: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Rendimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amarillo))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Viajes', value: '${_summary!.totalTrips}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Pagados', value: '${_summary!.paidTrips}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Promedio',
                          value: 'Bs. ${_summary!.averageFare.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
