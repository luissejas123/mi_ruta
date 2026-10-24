import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_state.dart';
import 'package:mi_ruta/features/user/presentation/utils/date_formatter.dart';

class EstadoBeneficiosPage extends StatefulWidget {
  const EstadoBeneficiosPage({super.key});

  @override
  State<EstadoBeneficiosPage> createState() => _EstadoBeneficiosPageState();
}

class _EstadoBeneficiosPageState extends State<EstadoBeneficiosPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      _userId = authState.user.uid;
      _loadRequests();
    }
  }

  void _loadRequests() {
    final userId = _userId;
    if (userId != null) {
      context.read<BenefitRequestBLoC>().add(LoadBenefitHistoryEvent(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estado de beneficios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _userId == null
          ? const Center(
              child: Text('Inicia sesión para consultar tus beneficios.'),
            )
          : BlocBuilder<BenefitRequestBLoC, BenefitRequestState>(
              builder: (context, state) {
                if (state is BenefitRequestLoading ||
                    state is BenefitRequestInitial ||
                    state is BenefitRequestSubmitted) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
                  );
                }
                if (state is BenefitRequestError) {
                  return _ErrorState(
                    message: state.message,
                    onRetry: _loadRequests,
                  );
                }
                if (state is BenefitHistoryLoaded) {
                  if (state.requests.isEmpty) return const _EmptyState();
                  return RefreshIndicator(
                    color: const Color(0xFFFFC12F),
                    onRefresh: () async => _loadRequests(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _BenefitRequestCard(request: state.requests[index]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}

class _BenefitRequestCard extends StatelessWidget {
  final BenefitRequest request;

  const _BenefitRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(request.status);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: status.color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(status.icon, color: status.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _benefitTypeLabel(request.benefitType),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(label: status.label, color: status.color),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.description),
            const SizedBox(height: 10),
            Text(
              'Enviada: ${DateFormatter.formatWithTime(request.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (request.approvedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Aprobada: ${DateFormatter.formatWithTime(request.approvedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (request.adminNotes?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text('Observación: ${request.adminNotes}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aún no tienes solicitudes de beneficio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

({String label, Color color, IconData icon}) _statusInfo(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return (
        label: 'Aprobado',
        color: Colors.green.shade700,
        icon: Icons.check_circle_outline,
      );
    case 'rejected':
      return (
        label: 'Rechazado',
        color: Colors.red.shade700,
        icon: Icons.cancel_outlined,
      );
    default:
      return (
        label: 'En revisión',
        color: Colors.orange.shade800,
        icon: Icons.hourglass_top_rounded,
      );
  }
}

String _benefitTypeLabel(String type) {
  switch (type) {
    case 'student':
      return 'Estudiante';
    case 'university':
      return 'Universitario';
    case 'senior':
      return 'Adulto mayor';
    default:
      return type.isEmpty ? 'Beneficio' : type;
  }
}
