import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_assignment_bloc.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// "Asignar tickeador" (RQ4-PRE): el dirigente elige una cuenta, su estación y
/// las líneas que va a operar. Las líneas son las reales sembradas por GTFS.
class AsignarTickeadorPage extends StatelessWidget {
  const AsignarTickeadorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TickeadorAssignmentBloc(
        userService: getIt<UserManagementService>(),
        routeService: getIt<RouteService>(),
      )..add(const LoadTickeadorAssignment()),
      child: const _AsignarTickeadorView(),
    );
  }
}

class _AsignarTickeadorView extends StatelessWidget {
  const _AsignarTickeadorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Asignar tickeador',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<TickeadorAssignmentBloc, TickeadorAssignmentState>(
        builder: (context, state) {
          if (state is TickeadorAssignmentLoading ||
              state is TickeadorAssignmentInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _amarillo),
            );
          }
          if (state is TickeadorAssignmentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context
                        .read<TickeadorAssignmentBloc>()
                        .add(const LoadTickeadorAssignment()),
                    style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is TickeadorAssignmentLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.tickeadores.isNotEmpty) ...[
                  _SectionTitle('Tickeadores (${state.tickeadores.length})'),
                  const SizedBox(height: 10),
                  for (final t in state.tickeadores) ...[
                    _UserTile(user: t, trailingIcon: Icons.check_circle,
                        trailingColor: Colors.green),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                ],
                _SectionTitle('Asignar a una cuenta'),
                const SizedBox(height: 6),
                Text(
                  state.availableLines.isEmpty
                      ? 'No hay líneas activas cargadas todavía. Espera a que '
                          'termine la sincronización de rutas para poder asignar.'
                      : 'Toca una cuenta para elegir su estación y sus líneas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                for (final u in state.candidates) ...[
                  _UserTile(
                    user: u,
                    trailingIcon: Icons.chevron_right,
                    onTap: state.availableLines.isEmpty
                        ? null
                        : () => _openAssignSheet(context, u, state.availableLines),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openAssignSheet(
    BuildContext context,
    UserEntity user,
    List<String> availableLines,
  ) async {
    final bloc = context.read<TickeadorAssignmentBloc>();
    final result = await showModalBottomSheet<_AssignmentDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignmentSheet(
        user: user,
        availableLines: availableLines,
      ),
    );
    if (result == null) return;
    bloc.add(AssignTickeador(
      uid: user.uid,
      assignedStation: result.station,
      assignedLines: result.lines,
    ));
  }
}

class _AssignmentDraft {
  final String station;
  final List<String> lines;

  const _AssignmentDraft({required this.station, required this.lines});
}

/// Formulario de asignación: estación (texto libre, no hay catálogo de
/// estaciones en el backend) y líneas elegidas de las rutas GTFS reales.
class _AssignmentSheet extends StatefulWidget {
  final UserEntity user;
  final List<String> availableLines;

  const _AssignmentSheet({required this.user, required this.availableLines});

  @override
  State<_AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends State<_AssignmentSheet> {
  final _stationController = TextEditingController();
  final _selectedLines = <String>{};

  @override
  void dispose() {
    _stationController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _stationController.text.trim().isNotEmpty && _selectedLines.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.fullName.isNotEmpty
                ? widget.user.fullName
                : widget.user.email,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _stationController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Estación asignada',
              hintText: 'Ej: Terminal Sur',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Líneas asignadas',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableLines.map((line) {
                  final selected = _selectedLines.contains(line);
                  return FilterChip(
                    label: Text('Línea $line'),
                    selected: selected,
                    selectedColor: _amarillo.withValues(alpha: 0.35),
                    onSelected: (value) => setState(() {
                      if (value) {
                        _selectedLines.add(line);
                      } else {
                        _selectedLines.remove(line);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarillo,
                foregroundColor: Colors.black,
              ),
              onPressed: _isValid
                  ? () => Navigator.pop(
                        context,
                        _AssignmentDraft(
                          station: _stationController.text.trim(),
                          lines: _selectedLines.toList()..sort(),
                        ),
                      )
                  : null,
              child: const Text(
                'Asignar como tickeador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;
  final IconData trailingIcon;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _UserTile({
    required this.user,
    required this.trailingIcon,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _amarillo,
                backgroundImage: user.profileImageUrl.isNotEmpty
                    ? NetworkImage(user.profileImageUrl)
                    : null,
                child: user.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.black, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                trailingIcon,
                color: trailingColor ??
                    colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
