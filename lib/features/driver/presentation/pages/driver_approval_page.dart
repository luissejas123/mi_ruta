import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_state.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

class DriverApprovalPage extends StatelessWidget {
  const DriverApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DriverApprovalBloc(service: getIt<UserManagementService>())
            ..add(const LoadDriverApprovalQueue()),
      child: const _DriverApprovalView(),
    );
  }
}

class _DriverApprovalView extends StatelessWidget {
  const _DriverApprovalView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Aprobar choferes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<DriverApprovalBloc, DriverApprovalState>(
        builder: (context, state) {
          if (state is DriverApprovalLoading ||
              state is DriverApprovalInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _amarillo),
            );
          }
          if (state is DriverApprovalError) {
            return _ErrorState(message: state.message);
          }
          if (state is DriverApprovalLoaded) {
            if (state.isEmpty) return const _EmptyState();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.pendingRequests.isNotEmpty) ...[
                  _SectionTitle(
                    'Solicitudes pendientes (${state.pendingRequests.length})',
                  ),
                  const SizedBox(height: 10),
                  for (final user in state.pendingRequests) ...[
                    _PendingRequestTile(
                      user: user,
                      isUpdating: state.updatingUid == user.uid,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 12),
                ],
                if (state.approvedDrivers.isNotEmpty) ...[
                  _SectionTitle('Choferes (${state.approvedDrivers.length})'),
                  const SizedBox(height: 10),
                  for (final driver in state.approvedDrivers) ...[
                    _DriverTile(
                      driver: driver,
                      isUpdating: state.updatingUid == driver.uid,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            );
          }
          return const SizedBox.shrink();
        },
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

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context
                .read<DriverApprovalBloc>()
                .add(const LoadDriverApprovalQueue()),
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay solicitudes ni choferes registrados',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar + nombre + correo, compartido por las dos filas.
class _UserSummary extends StatelessWidget {
  final UserEntity user;
  final Widget? badge;

  const _UserSummary({required this.user, this.badge});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _amarillo,
          backgroundImage: user.profileImageUrl.isNotEmpty
              ? NetworkImage(user.profileImageUrl)
              : null,
          child: user.profileImageUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.black)
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
              if (badge != null) ...[const SizedBox(height: 4), badge!],
            ],
          ),
        ),
      ],
    );
  }
}

/// Solicitud sin resolver: Aprobar (promueve a `driver`) o Rechazar.
class _PendingRequestTile extends StatelessWidget {
  final UserEntity user;
  final bool isUpdating;

  const _PendingRequestTile({required this.user, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final requestedAt = user.driverRequest?.requestedAt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amarillo.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          _UserSummary(
            user: user,
            badge: _StatusChip(
              label: requestedAt != null
                  ? 'Solicitó el ${_formatDate(requestedAt)}'
                  : 'Solicitud pendiente',
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          if (isUpdating)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context
                        .read<DriverApprovalBloc>()
                        .add(RejectDriverRequest(user.uid)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context
                        .read<DriverApprovalBloc>()
                        .add(ApproveDriverRequest(user.uid)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      'Aprobar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Chofer ya aprobado: solo se puede bloquear/desbloquear.
class _DriverTile extends StatelessWidget {
  final UserEntity driver;
  final bool isUpdating;

  const _DriverTile({required this.driver, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: driver.isActive
            ? null
            : Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _UserSummary(
              user: driver,
              badge: _StatusChip(
                label: driver.isActive ? 'Aprobado' : 'Bloqueado',
                color: driver.isActive ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          isUpdating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: driver.isActive,
                  activeThumbColor: Colors.green,
                  onChanged: (value) => context
                      .read<DriverApprovalBloc>()
                      .add(SetDriverActiveState(driver.uid, value)),
                ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
