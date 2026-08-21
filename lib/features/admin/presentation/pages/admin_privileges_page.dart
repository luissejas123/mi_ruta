import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_privileges.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_privileges_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_state.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

class AdminPrivilegesPage extends StatelessWidget {
  const AdminPrivilegesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final adminId = authState is AuthLoaded ? authState.user.uid : '';

    return BlocProvider(
      create: (_) =>
          AdminPrivilegesBloc(service: getIt<AdminPrivilegesService>())
            ..add(LoadAdminPrivileges(adminId)),
      child: _AdminPrivilegesView(adminId: adminId),
    );
  }
}

class _AdminPrivilegesView extends StatefulWidget {
  final String adminId;

  const _AdminPrivilegesView({required this.adminId});

  @override
  State<_AdminPrivilegesView> createState() => _AdminPrivilegesViewState();
}

class _AdminPrivilegesViewState extends State<_AdminPrivilegesView> {
  AdminPrivileges? _privileges;

  void _update(AdminPrivileges next) {
    setState(() => _privileges = next);
  }

  void _save() {
    final privileges = _privileges;
    if (privileges == null) return;
    context.read<AdminPrivilegesBloc>().add(
      SaveAdminPrivileges(widget.adminId, privileges),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminPrivilegesBloc, AdminPrivilegesState>(
      listener: (context, state) {
        if (state is AdminPrivilegesLoaded || state is AdminPrivilegesSaved) {
          final privileges = state is AdminPrivilegesLoaded
              ? state.privileges
              : (state as AdminPrivilegesSaved).privileges;
          setState(() => _privileges = privileges);
          if (state is AdminPrivilegesSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Privilegios guardados correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        if (state is AdminPrivilegesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Gestión de privilegios',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: BlocBuilder<AdminPrivilegesBloc, AdminPrivilegesState>(
          builder: (context, state) {
            if (state is AdminPrivilegesLoading ||
                state is AdminPrivilegesInitial ||
                _privileges == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
              );
            }
            final isSaving = state is AdminPrivilegesSaving;
            return _PrivilegesForm(
              privileges: _privileges!,
              isSaving: isSaving,
              onChanged: _update,
              onSave: _save,
            );
          },
        ),
      ),
    );
  }
}

class _PrivilegesForm extends StatelessWidget {
  final AdminPrivileges privileges;
  final bool isSaving;
  final ValueChanged<AdminPrivileges> onChanged;
  final VoidCallback onSave;

  const _PrivilegesForm({
    required this.privileges,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Text('Configure las operaciones disponibles:'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _PrivilegeGroup(
                title: 'Funciones de Rutas',
                entries: [
                  _PrivilegeEntry(
                    label: 'Cargar',
                    value: privileges.manageRoutesCreate,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageRoutesCreate: value),
                    ),
                  ),
                  _PrivilegeEntry(
                    label: 'Editar',
                    value: privileges.manageRoutesEdit,
                    onChanged: (value) =>
                        onChanged(privileges.copyWith(manageRoutesEdit: value)),
                  ),
                  _PrivilegeEntry(
                    label: 'Eliminar',
                    value: privileges.manageRoutesDelete,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageRoutesDelete: value),
                    ),
                  ),
                ],
              ),
              _PrivilegeGroup(
                title: 'Funciones de Usuarios',
                entries: [
                  _PrivilegeEntry(
                    label: 'Aceptar usuario',
                    value: privileges.manageUsersAccept,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageUsersAccept: value),
                    ),
                  ),
                  _PrivilegeEntry(
                    label: 'Suspender',
                    value: privileges.manageUsersSuspend,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageUsersSuspend: value),
                    ),
                  ),
                  _PrivilegeEntry(
                    label: 'Eliminar',
                    value: privileges.manageUsersDelete,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageUsersDelete: value),
                    ),
                  ),
                ],
              ),
              _PrivilegeGroup(
                title: 'Funciones de administrador',
                entries: [
                  _PrivilegeEntry(
                    label: 'Agregar',
                    value: privileges.manageAdminsCreate,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageAdminsCreate: value),
                    ),
                  ),
                  _PrivilegeEntry(
                    label: 'Editar',
                    value: privileges.manageAdminsEdit,
                    onChanged: (value) =>
                        onChanged(privileges.copyWith(manageAdminsEdit: value)),
                  ),
                  _PrivilegeEntry(
                    label: 'Eliminar',
                    value: privileges.manageAdminsDelete,
                    onChanged: (value) => onChanged(
                      privileges.copyWith(manageAdminsDelete: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC12F),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : const Text(
                      'Confirmar Cambios',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivilegeGroup extends StatelessWidget {
  final String title;
  final List<_PrivilegeEntry> entries;

  const _PrivilegeGroup({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFFFC12F),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, size: 38, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...entries,
                ],
              ),
            ),
            Column(
              children: entries
                  .map(
                    (entry) => Switch(
                      value: entry.value,
                      onChanged: entry.onChanged,
                      activeThumbColor: Colors.black,
                      activeTrackColor: Colors.black,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivilegeEntry extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivilegeEntry({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
