import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/tickeador_operation.dart';
import 'package:mi_ruta/features/driver/domain/services/tickeador_operations_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_state.dart';

class TickeadorOperationsHistoryPage extends StatelessWidget {
  const TickeadorOperationsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final tickeadorId = authState is AuthLoaded ? authState.user.uid : '';

    return BlocProvider(
      create: (_) =>
          TickeadorOperationsBloc(service: getIt<TickeadorOperationsService>())
            ..add(LoadTickeadorOperations(tickeadorId)),
      child: const _TickeadorOperationsView(),
    );
  }
}

class _TickeadorOperationsView extends StatelessWidget {
  const _TickeadorOperationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Historial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<TickeadorOperationsBloc, TickeadorOperationsState>(
        builder: (context, state) {
          if (state is TickeadorOperationsLoading ||
              state is TickeadorOperationsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is TickeadorOperationsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthLoaded) {
                          context.read<TickeadorOperationsBloc>().add(
                            LoadTickeadorOperations(authState.user.uid),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is TickeadorOperationsLoaded) {
            if (state.operations.isEmpty) return const _EmptyState();
            return _OperationsList(operations: state.operations);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OperationsList extends StatelessWidget {
  final List<TickeadorOperation> operations;

  const _OperationsList({required this.operations});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = operations
        .where((operation) => _isToday(operation.timestamp))
        .toList();
    final previous = operations
        .where((operation) => !_isToday(operation.timestamp))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        if (today.isNotEmpty) ...[
          const _SectionTitle('REGISTROS DE HOY'),
          ...today.map((operation) => _OperationCard(operation: operation)),
        ],
        if (previous.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionTitle('REGISTROS ANTERIORES'),
          ...previous.map((operation) => _OperationCard(operation: operation)),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFFC12F),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  final TickeadorOperation operation;

  const _OperationCard({required this.operation});

  String _time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _typeLabel() => operation.isDeparture ? 'Salida' : 'Llegada';

  @override
  Widget build(BuildContext context) {
    final accent = operation.isDeparture
        ? const Color(0xFFFFC12F)
        : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC12F),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.black87, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(
            operation.isDeparture ? Icons.login : Icons.flag_outlined,
            color: Colors.black87,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_typeLabel()} - ${operation.stationName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Línea ${operation.lineId}',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.65),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _time(operation.timestamp),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.circle, size: 5, color: accent),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Sin operaciones registradas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Las salidas y llegadas del Tickeador aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
