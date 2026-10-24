import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/entities/recharge.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_state.dart';

const _amarillo = Color(0xFFFFC12F);

/// Revisión de recargas pendientes por el tickeador (docs/
/// PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 0) — uno de los 11 puntos
/// originales del plan que nunca se había construido. Desde que se quitó
/// la auto-aprobación, una recarga se queda `pending` para siempre si nadie
/// la revisa acá.
class RevisionRecargasPage extends StatefulWidget {
  const RevisionRecargasPage({super.key});

  @override
  State<RevisionRecargasPage> createState() => _RevisionRecargasPageState();
}

class _RevisionRecargasPageState extends State<RevisionRecargasPage> {
  @override
  void initState() {
    super.initState();
    context.read<RechargeBloC>().add(const LoadPendingRechargesEvent());
  }

  void _aprobar(Recharge recharge) {
    context.read<RechargeBloC>().add(
      ApproveRechargeEvent(
        rechargeId: recharge.id,
        userId: recharge.userId,
        amount: recharge.amount,
      ),
    );
  }

  Future<void> _rechazar(Recharge recharge) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar recarga'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivo (ej: comprobante ilegible, monto no coincide)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    context.read<RechargeBloC>().add(
      RejectRechargeEvent(
        rechargeId: recharge.id,
        userId: recharge.userId,
        amount: recharge.amount,
        reason: reason,
      ),
    );
  }

  void _verComprobante(Recharge recharge) {
    if (recharge.proofImageUrl == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(recharge.proofImageUrl!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Revisión de recargas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocConsumer<RechargeBloC, RechargeState>(
        listener: (context, state) {
          if (state is RechargeActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          if (state is RechargeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RechargeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _amarillo),
            );
          }
          if (state is! PendingRechargesLoaded) {
            return const SizedBox.shrink();
          }
          if (state.recharges.isEmpty) {
            return Center(
              child: Text(
                'No hay recargas pendientes de revisión.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.recharges.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _RechargeCard(
              recharge: state.recharges[i],
              onVerComprobante: () => _verComprobante(state.recharges[i]),
              onAprobar: () => _aprobar(state.recharges[i]),
              onRechazar: () => _rechazar(state.recharges[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RechargeCard extends StatelessWidget {
  final Recharge recharge;
  final VoidCallback onVerComprobante;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _RechargeCard({
    required this.recharge,
    required this.onVerComprobante,
    required this.onAprobar,
    required this.onRechazar,
  });

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recharge.userName?.isNotEmpty == true
                      ? recharge.userName!
                      : recharge.userId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Bs. ${recharge.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(recharge.createdAt),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 10),
          if (recharge.proofImageUrl != null)
            GestureDetector(
              onTap: onVerComprobante,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  recharge.proofImageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 140,
                    color: colorScheme.surface,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRechazar,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAprobar,
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: const Text('Aprobar', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
