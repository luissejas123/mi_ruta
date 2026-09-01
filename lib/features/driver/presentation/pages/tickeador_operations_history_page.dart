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

enum _HistoryFilter {
  today,
  yesterday,
  week,
  all,
}

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

class _TickeadorOperationsView extends StatefulWidget {
  const _TickeadorOperationsView();

  @override
  State<_TickeadorOperationsView> createState() => _TickeadorOperationsViewState();
}

class _TickeadorOperationsViewState extends State<_TickeadorOperationsView> {
  _HistoryFilter _selectedFilter = _HistoryFilter.today;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Historial de operaciones',
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
            return _OperationsList(
              operations: state.operations,
              filter: _selectedFilter,
              onFilterChanged: (value) => setState(() => _selectedFilter = value),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OperationsList extends StatelessWidget {
  final List<TickeadorOperation> operations;
  final _HistoryFilter filter;
  final ValueChanged<_HistoryFilter> onFilterChanged;

  const _OperationsList({
    required this.operations,
    required this.filter,
    required this.onFilterChanged,
  });

  List<TickeadorOperation> _filteredOperations() {
    if (operations.isEmpty) return const [];

    final now = DateTime.now();
    switch (filter) {
      case _HistoryFilter.today:
        return operations
            .where((operation) => _isSameDay(operation.timestamp, now))
            .toList();
      case _HistoryFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return operations
            .where((operation) => _isSameDay(operation.timestamp, yesterday))
            .toList();
      case _HistoryFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return operations
            .where((operation) =>
                !operation.timestamp.isBefore(weekAgo) &&
                !operation.timestamp.isAfter(now))
            .toList();
      case _HistoryFilter.all:
        return operations;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _filterLabel(_HistoryFilter value) {
    switch (value) {
      case _HistoryFilter.today:
        return 'Hoy';
      case _HistoryFilter.yesterday:
        return 'Ayer';
      case _HistoryFilter.week:
        return '7 días';
      case _HistoryFilter.all:
        return 'Todo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredOperations();
    final grouped = <String, List<TickeadorOperation>>{};

    for (final operation in visible) {
      final key = _isSameDay(operation.timestamp, DateTime.now())
          ? 'Hoy'
          : _formatDayHeader(operation.timestamp);
      grouped.putIfAbsent(key, () => []).add(operation);
    }

    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => b.value.first.timestamp.compareTo(a.value.first.timestamp));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _HeaderCard(total: visible.length),
        const SizedBox(height: 12),
        _FilterRow(
          selected: filter,
          onChanged: onFilterChanged,
          labels: _HistoryFilter.values
              .map(_filterLabel)
              .toList(),
        ),
        const SizedBox(height: 18),
        if (visible.isEmpty)
          const _EmptyState()
        else ...[
          for (final entry in sortedGroups)
            ...[
              const SizedBox(height: 8),
              _SectionTitle(entry.key),
              const SizedBox(height: 8),
              ...entry.value.map((operation) => _OperationCard(operation: operation)),
            ],
        ],
      ],
    );
  }

  String _formatDayHeader(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(local, now)) return 'Hoy';
    if (_isSameDay(local, yesterday)) return 'Ayer';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;

  const _HeaderCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC12F).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.history, color: Color(0xFFFFC12F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operaciones registradas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total en total',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;
  final List<String> labels;

  const _FilterRow({
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _HistoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = _HistoryFilter.values[index];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: isSelected,
            selectedColor: const Color(0xFFFFC12F),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.black54,
            ),
            onSelected: (_) => onChanged(value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title.toUpperCase(),
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
    final isDeparture = operation.isDeparture;
    final accent = isDeparture ? const Color(0xFFFFC12F) : Colors.green;
    final surface = isDeparture
        ? const Color(0xFFFFF4D9)
        : const Color(0xFFEAF8EE);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDeparture ? Icons.login : Icons.logout,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        operation.stationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _typeLabel(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Línea ${operation.lineId} · ${operation.vehiclePlate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      _time(operation.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            Icon(Icons.history, size: 64, color: color.withValues(alpha: 0.25)),
            const SizedBox(height: 18),
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
