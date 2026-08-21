import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/solicitud_beneficio_page.dart';

/// Historial de solicitudes de beneficio del usuario, con opción de renovar.
class MisSolicitudesBeneficioPage extends StatefulWidget {
  const MisSolicitudesBeneficioPage({super.key});

  @override
  State<MisSolicitudesBeneficioPage> createState() =>
      _MisSolicitudesBeneficioPageState();
}

class _MisSolicitudesBeneficioPageState
    extends State<MisSolicitudesBeneficioPage> {
  static const _amarillo = Color(0xFFFFC12F);

  String get _userId {
    final state = context.read<AuthBloc>().state;
    return state is AuthLoaded ? state.user.uid : '';
  }

  @override
  void initState() {
    super.initState();
    context.read<BenefitRequestBLoC>().add(LoadBenefitHistoryEvent(_userId));
  }

  void _renovar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SolicitudBeneficioPage()),
    );
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
        return type;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return 'En revisión';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<BenefitRequestBLoC, BenefitRequestState>(
        builder: (context, state) {
          if (state is BenefitRequestLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _amarillo));
          }
          if (state is BenefitRequestError) {
            return Center(child: Text(state.message));
          }
          if (state is BenefitHistoryLoaded) {
            if (state.requests.isEmpty) {
              return const Center(
                child: Text('Aún no tienes solicitudes de beneficio.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.requests.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _RequestTile(
                request: state.requests[i],
                typeLabel: _benefitTypeLabel(state.requests[i].benefitType),
                statusLabel: _statusLabel(state.requests[i].status),
                statusColor: _statusColor(state.requests[i].status),
                onRenovar: _renovar,
                colorScheme: colorScheme,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final BenefitRequest request;
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onRenovar;
  final ColorScheme colorScheme;

  const _RequestTile({
    required this.request,
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.onRenovar,
    required this.colorScheme,
  });

  bool get _canRenovar =>
      request.status == 'approved' || request.status == 'rejected';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                Text(statusLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ],
            ),
          ),
          if (_canRenovar)
            TextButton(
              onPressed: onRenovar,
              child: const Text('Renovar',
                  style: TextStyle(color: Color(0xFFFFC12F))),
            ),
        ],
      ),
    );
  }
}
