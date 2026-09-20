import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/claims_bloc.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/claims_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/claims_state.dart';
import 'package:mi_ruta/features/user/domain/entities/claim_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// Gestión de reclamos del presidente (F3, prioridad de Padre — el único de
/// los 4 puntos nuevos cuyo esquema ya estaba documentado). 1 lista + 1
/// bottom sheet de detalle + 1 diálogo de resolución — no 3 pantallas
/// separadas (ver Retrospective/Pereza/Padre): el esquema documentado solo
/// tiene 2 estados (open/resolved), "resolución" es una acción, no una
/// pantalla propia.
class PresidenteReclamosPage extends StatelessWidget {
  const PresidenteReclamosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final lineIds = authState is AuthLoaded ? authState.user.managedLines : const <String>[];
    return BlocProvider(
      create: (_) => getIt<ClaimsBloc>()..add(LoadClaims(lineIds: lineIds)),
      child: const _PresidenteReclamosView(),
    );
  }
}

class _PresidenteReclamosView extends StatefulWidget {
  const _PresidenteReclamosView();

  @override
  State<_PresidenteReclamosView> createState() => _PresidenteReclamosViewState();
}

class _PresidenteReclamosViewState extends State<_PresidenteReclamosView> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _showResolved = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClaimEntity> _filtered(List<ClaimEntity> claims) {
    final base = _showResolved ? claims : claims.where((c) => c.isOpen).toList();
    if (_query.isEmpty) return base;
    final q = _query.toLowerCase();
    return base.where((c) {
      final searchable = [c.title, c.description, c.reporterName, c.targetName, c.lineId]
          .whereType<String>()
          .join(' ')
          .toLowerCase();
      return searchable.contains(q);
    }).toList();
  }

  Future<void> _openDetail(ClaimEntity claim) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ClaimsBloc>(),
        child: _ClaimDetailSheet(claim: claim),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Reclamos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por título, línea o persona...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Abiertos'),
                  selected: !_showResolved,
                  selectedColor: _amarillo.withValues(alpha: 0.35),
                  onSelected: (_) => setState(() => _showResolved = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _showResolved,
                  selectedColor: _amarillo.withValues(alpha: 0.35),
                  onSelected: (_) => setState(() => _showResolved = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<ClaimsBloc, ClaimsState>(
              listener: (context, state) {
                if (state is ClaimsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red.shade700),
                  );
                }
              },
              builder: (context, state) {
                if (state is ClaimsLoading || state is ClaimsInitial) {
                  return const Center(child: CircularProgressIndicator(color: _amarillo));
                }
                if (state is! ClaimsLoaded) {
                  return const SizedBox.shrink();
                }
                final visible = _filtered(state.claims);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      _showResolved ? 'No hay reclamos.' : 'No hay reclamos abiertos.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: visible.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ClaimTile(claim: visible[i], onTap: () => _openDetail(visible[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final ClaimEntity claim;
  final VoidCallback onTap;

  const _ClaimTile({required this.claim, required this.onTap});

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: claim.isOpen ? Colors.orange : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Línea ${claim.lineId} · ${claim.claimType}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimDetailSheet extends StatelessWidget {
  final ClaimEntity claim;

  const _ClaimDetailSheet({required this.claim});

  Future<void> _resolve(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) return;
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver reclamo'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Nota de resolución (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
            child: const Text('Resolver', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (note == null || !context.mounted) return;
    context.read<ClaimsBloc>().add(
          ResolveClaim(
            claimId: claim.id,
            resolvedBy: authState.user.uid,
            resolutionNote: note.isEmpty ? null : note,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(claim.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Línea ${claim.lineId} · ${claim.claimType} · ${claim.isOpen ? "Abierto" : "Resuelto"}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text(claim.description),
            const SizedBox(height: 16),
            if (claim.reporterName != null && claim.reporterName!.isNotEmpty)
              Text('Reportado por: ${claim.reporterName}', style: const TextStyle(fontSize: 13)),
            if (claim.targetName != null && claim.targetName!.isNotEmpty)
              Text('Sobre: ${claim.targetName}', style: const TextStyle(fontSize: 13)),
            if (!claim.isOpen) ...[
              const SizedBox(height: 12),
              if (claim.resolutionNote != null && claim.resolutionNote!.isNotEmpty)
                Text('Resolución: ${claim.resolutionNote}', style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 20),
            if (claim.isOpen)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _resolve(context),
                  style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                  child: const Text('Marcar como resuelto', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
