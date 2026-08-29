import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/solicitud_beneficio_page.dart';

class BeneficiosPage extends StatefulWidget {
  const BeneficiosPage({super.key});

  @override
  State<BeneficiosPage> createState() => _BeneficiosPageState();
}

class _BeneficiosPageState extends State<BeneficiosPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadHistory();
  }

  void _loadUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      _userId = authState.user.uid;
    }
  }

  void _loadHistory() {
    if (_userId == null || _userId!.isEmpty) return;
    context.read<BenefitRequestBLoC>().add(LoadBenefitHistoryEvent(_userId!));
  }

  void _renewBenefit(String requestId) {
    if (_userId == null || _userId!.isEmpty) return;
    context.read<BenefitRequestBLoC>().add(
      RenewBenefitRequestEvent(userId: _userId!, requestId: requestId),
    );
  }

  void _cancelBenefit(String requestId) {
    if (_userId == null || _userId!.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar beneficio'),
        content: const Text(
          '¿Deseas cancelar esta solicitud? Se conservará el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BenefitRequestBLoC>().add(
                CancelBenefitRequestEvent(
                  userId: _userId!,
                  requestId: requestId,
                ),
              );
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _downloadPdf(String requestId) {
    if (_userId == null || _userId!.isEmpty) return;
    context.read<BenefitRequestBLoC>().add(
      DownloadBenefitDocumentEvent(userId: _userId!, requestId: requestId),
    );
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'student':
        return 'Estudiante';
      case 'university':
        return 'Universitario';
      case 'senior':
        return 'Adulto mayor';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SolicitudBeneficioPage(),
                ),
              ).then((_) => _loadHistory());
            },
          ),
        ],
      ),
      body: BlocConsumer<BenefitRequestBLoC, BenefitRequestState>(
        listener: (context, state) {
          if (state is BenefitRequestUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          if (state is BenefitDocumentDownloaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          if (state is BenefitRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BenefitRequestLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }

          if (state is BenefitHistoryLoaded) {
            final requests = state.requests;
            if (requests.isEmpty) {
              return const Center(
                child: Text('Todavía no tienes solicitudes de beneficio.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final canRenew = request.status == 'rejected';
                final canCancel = request.status == 'pending';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _labelForType(request.benefitType),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _colorForStatus(
                                  request.status,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _labelForStatus(request.status),
                                style: TextStyle(
                                  color: _colorForStatus(request.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Descripción: ${request.description}'),
                        const SizedBox(height: 6),
                        Text(
                          'Fecha: ${request.createdAt.toLocal().toString().split(' ')[0]}',
                        ),
                        if (request.adminNotes != null &&
                            request.adminNotes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Observación: ${request.adminNotes}'),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canRenew)
                              OutlinedButton.icon(
                                onPressed: () => _renewBenefit(request.id),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Renovar'),
                              ),
                            if (canCancel)
                              OutlinedButton.icon(
                                onPressed: () => _cancelBenefit(request.id),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancelar'),
                              ),
                            if (request.documentUrls.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _downloadPdf(request.id),
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('PDF'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Cargando beneficios...'));
        },
      ),
    );
  }
}
