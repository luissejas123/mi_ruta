import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_state.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

class DriverApprovalPage extends StatelessWidget {
  const DriverApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DriverApprovalBloc(service: getIt<DriverService>())
        ..add(const LoadDriverUsers()),
      child: const _DriverApprovalView(),
    );
  }
}

class _DriverApprovalView extends StatelessWidget {
  const _DriverApprovalView();

  static const _amarillo = Color(0xFFFFC12F);

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
          if (state is DriverApprovalLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _amarillo),
            );
          }
          if (state is DriverApprovalError) {
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
                        .read<DriverApprovalBloc>()
                        .add(const LoadDriverUsers()),
                    style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                    child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          }
          if (state is DriverApprovalLoaded) {
            if (state.drivers.isEmpty) return const _EmptyState();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.drivers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _DriverTile(
                driver: state.drivers[i],
                isUpdating: state.updatingUid == state.drivers[i].uid,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay choferes registrados',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

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
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFFFC12F),
            backgroundImage: driver.profileImageUrl.isNotEmpty
                ? NetworkImage(driver.profileImageUrl)
                : null,
            child: driver.profileImageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName.isNotEmpty ? driver.fullName : driver.email,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (driver.isActive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    driver.isActive ? 'Aprobado' : 'Bloqueado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: driver.isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
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
                  onChanged: (value) => context.read<DriverApprovalBloc>().add(
                        SetDriverActiveState(driver.uid, value),
                      ),
                ),
        ],
      ),
    );
  }
}
