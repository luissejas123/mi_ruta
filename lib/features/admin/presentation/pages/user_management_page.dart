import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_state.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

const _amarillo = Color(0xFFFFC12F);

const _roleFilters = <String?, String>{
  null: 'Todos',
  'passenger': 'Pasajeros',
  'driver': 'Choferes',
  'tickeador': 'Tickeadores',
  'admin': 'Administradores',
  'presidente': 'Dirigentes',
};

String _roleLabel(String userType) => _roleFilters[userType] ?? userType;

/// Gestión de cuentas de cualquier rol (RQ-71 gestión de usuarios,
/// RQ-72 aprobación/bloqueo) — accesible para admin y presidente.
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserManagementBloc(service: getIt<UserManagementService>())
        ..add(const LoadManagedUsers()),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Gestión de usuarios',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          const _RoleFilterBar(),
          Expanded(
            child: BlocBuilder<UserManagementBloc, UserManagementState>(
              builder: (context, state) {
                if (state is UserManagementLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _amarillo),
                  );
                }
                if (state is UserManagementError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                  );
                }
                if (state is UserManagementLoaded) {
                  if (state.users.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay usuarios en esta categoría',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _UserTile(
                      user: state.users[i],
                      isUpdating: state.updatingUid == state.users[i].uid,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterBar extends StatelessWidget {
  const _RoleFilterBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          final activeFilter = state is UserManagementLoaded ? state.activeFilter : null;
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: _roleFilters.entries.map((entry) {
              final selected = entry.key == activeFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  selectedColor: _amarillo,
                  onSelected: (_) => context
                      .read<UserManagementBloc>()
                      .add(LoadManagedUsers(userTypeFilter: entry.key)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;
  final bool isUpdating;

  const _UserTile({required this.user, required this.isUpdating});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: user.isActive ? null : Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _amarillo,
            backgroundImage:
                user.profileImageUrl.isNotEmpty ? NetworkImage(user.profileImageUrl) : null,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _Badge(label: _roleLabel(user.userType), color: Colors.blueGrey),
                    _Badge(
                      label: user.isActive ? 'Aprobado' : 'Bloqueado',
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                    if (user.qaAccess) const _Badge(label: 'Acceso QA', color: Colors.purple),
                  ],
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
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: user.isActive,
                      activeThumbColor: Colors.green,
                      onChanged: (value) => context
                          .read<UserManagementBloc>()
                          .add(SetManagedUserActiveState(user.uid, value)),
                    ),
                    IconButton(
                      tooltip: user.qaAccess
                          ? 'Quitar acceso QA a los 5 perfiles'
                          : 'Dar acceso QA a los 5 perfiles',
                      icon: Icon(
                        Icons.switch_account_outlined,
                        color: user.qaAccess ? Colors.purple : Colors.grey,
                      ),
                      onPressed: () => context
                          .read<UserManagementBloc>()
                          .add(SetManagedUserQaAccess(user.uid, !user.qaAccess)),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final MaterialColor color;

  const _Badge({required this.label, required this.color});

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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade700),
      ),
    );
  }
}
