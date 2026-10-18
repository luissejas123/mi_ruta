import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_actividad_item.dart';

const _amarillo = Color(0xFFFFC12F);

/// Historial completo de salidas/llegadas/puntos intermedios del tickeador
/// — entrada desde Perfil ("Historial de operaciones"). Reemplaza a la
/// implementación duplicada que vivía en `features/driver` (leía la misma
/// colección `station_logs` pero sin punto intermedio y sin ningún llamador
/// real); esta reusa directo `TickeadorService.getActividadReciente`, la
/// misma fuente que ya muestra `TickeadorHomePage` en "Actividad reciente".
class TickeadorActividadHistoryPage extends StatefulWidget {
  const TickeadorActividadHistoryPage({super.key});

  @override
  State<TickeadorActividadHistoryPage> createState() =>
      _TickeadorActividadHistoryPageState();
}

class _TickeadorActividadHistoryPageState
    extends State<TickeadorActividadHistoryPage> {
  late Future<List<StationLogEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StationLogEntity>> _load() {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    if (uid.isEmpty) return Future.value(const []);
    return getIt<TickeadorService>().getActividadReciente(uid, limit: 100);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Historial de operaciones',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        color: _amarillo,
        child: FutureBuilder<List<StationLogEntity>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: _amarillo));
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text('No se pudo cargar el historial: ${snapshot.error}'),
                  ),
                ],
              );
            }
            final logs = snapshot.data ?? const [];
            if (logs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No hay actividad registrada todavía.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, i) => TickeadorActividadItem(log: logs[i]),
            );
          },
        ),
      ),
    );
  }
}
