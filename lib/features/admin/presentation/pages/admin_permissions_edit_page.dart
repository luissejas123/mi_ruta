import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_permissions.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_state.dart';

class AdminPermissionsEditPage extends StatefulWidget {
  final AdminUserEntity user;

  const AdminPermissionsEditPage({super.key, required this.user});

  @override
  State<AdminPermissionsEditPage> createState() =>
      _AdminPermissionsEditPageState();
}

class _AdminPermissionsEditPageState extends State<AdminPermissionsEditPage> {
  late Map<String, bool> _permissions;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _permissions = _defaultsFrom(widget.user);
    // Refresca los privilegios actuales desde Firestore.
    context
        .read<AdminPrivilegesBloc>()
        .add(LoadAdminPermissionsEvent(widget.user.uid));
  }

  Map<String, bool> _defaultsFrom(AdminUserEntity user) {
    final result = <String, bool>{};
    for (final key in AdminPermissions.all) {
      result[key] = user.hasPermission(key);
    }
    return result;
  }

  void _confirm() {
    context.read<AdminPrivilegesBloc>().add(
      UpdateAdminPermissionsEvent(
        uid: widget.user.uid,
        permissions: Map<String, bool>.from(_permissions),
      ),
    );
  }

  Future<void> _confirmRevoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar privilegios de administrador'),
        content: Text(
          '¿Seguro que quieres quitarle el rol de administrador a '
          '"${widget.user.fullName}"? La cuenta vuelve a ser un usuario '
          'normal — desde ahí se le puede asignar otro rol limpiamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Quitar privilegios',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AdminPrivilegesBloc>().add(RevokeAdminRoleEvent(widget.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de privilegios'),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminPrivilegesBloc, AdminPrivilegesState>(
        listener: (context, state) {
          if (state is AdminPrivilegesSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
            Navigator.pop(context);
          }
          if (state is AdminPrivilegesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          // Actualiza los switches con los datos frescos de Firestore.
          if (state is AdminPermissionsLoaded && !_initialized) {
            _initialized = true;
            _permissions = _defaultsFrom(state.admin);
          }
          if (state is AdminPrivilegesLoading && !_initialized) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFFFC12F),
                          child: Text(
                            widget.user.fullName.isNotEmpty
                                ? widget.user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.user.email,
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _PermissionSwitch(
                        title: 'Gestionar usuarios',
                        description: 'Ver y buscar usuarios reales',
                        value: _permissions[AdminPermissions.manageUsers] ??
                            false,
                        onChanged: (value) => setState(
                          () => _permissions[AdminPermissions.manageUsers] =
                              value,
                        ),
                      ),
                      const Divider(height: 1),
                      _PermissionSwitch(
                        title: 'Gestionar administradores',
                        description: 'Promover usuarios a administrador',
                        value: _permissions[AdminPermissions.manageAdmins] ??
                            false,
                        onChanged: (value) => setState(
                          () => _permissions[AdminPermissions.manageAdmins] =
                              value,
                        ),
                      ),
                      const Divider(height: 1),
                      _PermissionSwitch(
                        title: 'Gestionar rutas',
                        description: 'Cargar, editar y eliminar rutas',
                        value:
                            _permissions[AdminPermissions.manageRoutes] ??
                                false,
                        onChanged: (value) => setState(
                          () => _permissions[AdminPermissions.manageRoutes] =
                              value,
                        ),
                      ),
                      const Divider(height: 1),
                      _PermissionSwitch(
                        title: 'Gestionar privilegios',
                        description: 'Editar permisos de administradores',
                        value:
                            _permissions[AdminPermissions.managePermissions] ??
                                false,
                        onChanged: (value) => setState(
                          () => _permissions[
                                  AdminPermissions.managePermissions] =
                              value,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC12F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        state is AdminPrivilegesLoading ? null : _confirm,
                    child: state is AdminPrivilegesLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'CONFIRMAR CAMBIOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade400),
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        state is AdminPrivilegesLoading ? null : _confirmRevoke,
                    child: const Text(
                      'QUITAR PRIVILEGIOS DE ADMINISTRADOR',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PermissionSwitch extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionSwitch({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(description),
      value: value,
      activeTrackColor: const Color(0xFFFFC12F),
      onChanged: onChanged,
    );
  }
}
