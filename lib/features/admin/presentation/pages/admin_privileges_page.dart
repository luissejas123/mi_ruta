import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_access_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_state.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_create_admin_page.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_permissions_edit_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

class AdminPrivilegesPage extends StatefulWidget {
  const AdminPrivilegesPage({super.key});

  @override
  State<AdminPrivilegesPage> createState() => _AdminPrivilegesPageState();
}

class _AdminPrivilegesPageState extends State<AdminPrivilegesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminPrivilegesBloc>().add(const LoadAdminsEvent());
  }

  bool get _canManageAdmins {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthLoaded && authState.user.canManageAdmins;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded || !authState.user.canManagePermissions) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de privilegios')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.black38),
                SizedBox(height: 12),
                Text(
                  'No tienes permiso para gestionar privilegios',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de privilegios'),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminPrivilegesBloc, AdminPrivilegesState>(
        listener: (context, state) {
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
          if (state is AdminPrivilegesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is AdminPrivilegesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<AdminPrivilegesBloc>()
                          .add(const LoadAdminsEvent()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is! AdminsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.admins.isEmpty) {
            return const Center(
              child: Text(
                'No hay administradores registrados',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: state.admins.length,
            itemBuilder: (context, index) {
              final admin = state.admins[index];
              return _AdminTile(admin: admin);
            },
          );
        },
      ),
      floatingActionButton: _canManageAdmins
          ? FloatingActionButton.extended(
              heroTag: 'agregar_admin',
              backgroundColor: const Color(0xFFFFC12F),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text(
                'AGREGAR NUEVO ADMINISTRADOR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: getIt<AdminPrivilegesBloc>(),
                      child: const AdminCreateAdminPage(),
                    ),
                  ),
                );
                // El bloc es un singleton compartido con AdminCreateAdminPage:
                // al volver, su estado ya no es AdminsLoaded (quedó en
                // AdminPrivilegesSuccess/Loading) — sin este refresh, la lista
                // se queda mostrando el spinner de "carga" para siempre.
                if (context.mounted) {
                  context.read<AdminPrivilegesBloc>().add(const LoadAdminsEvent());
                }
              },
            )
          : null,
    );
  }
}

class _AdminTile extends StatelessWidget {
  final AdminUserEntity admin;

  const _AdminTile({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFC12F),
          child: Text(
            admin.fullName.isNotEmpty ? admin.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          admin.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(admin.email),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: getIt<AdminPrivilegesBloc>(),
                child: AdminPermissionsEditPage(user: admin),
              ),
            ),
          );
          // Mismo motivo que en el botón de agregar admin: refresca la lista
          // porque el bloc compartido quedó en AdminPermissionsLoaded.
          if (context.mounted) {
            context.read<AdminPrivilegesBloc>().add(const LoadAdminsEvent());
          }
        },
      ),
    );
  }
}
