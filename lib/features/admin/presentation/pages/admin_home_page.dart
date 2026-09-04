import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_access_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/admin_bottom_navigation_bar.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_privileges_page.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_route_management_page.dart';
import 'package:mi_ruta/features/admin/presentation/pages/user_management_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/change_password_dialog.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/logout_button.dart' show confirmLogout;

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = authState.user;

        return Scaffold(
          // Sin `leading` forzado: esta es la pantalla raíz del admin
          // (home_router la usa directo tras login), así que no hay nada
          // que retroceder — Flutter no muestra flecha si no hay nada que
          // popear, igual que el resto de las pantallas raíz de la app.
          appBar: AppBar(
            title: const Text('Perfil Administrativo'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => confirmLogout(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFFFC12F),
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : 'Administrador',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Administrador',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                if (user.isSuperAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC12F),
                                      borderRadius: BorderRadius.circular(84),
                                    ),
                                    child: const Text(
                                      'SUPERADMIN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Menú',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (user.canManageUsers)
                    _MenuCard(
                      icon: Icons.people_outline,
                      title: 'Gestión de usuarios',
                      subtitle: 'Listar, buscar y promover usuarios',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: getIt<UserManagementBloc>(),
                              child: const UserManagementPage(),
                            ),
                          ),
                        );
                      },
                    ),
                  if (user.canManagePermissions)
                    _MenuCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Gestión de privilegios',
                      subtitle: 'Activar o desactivar permisos de admins',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: getIt<AdminPrivilegesBloc>(),
                              child: const AdminPrivilegesPage(),
                            ),
                          ),
                        );
                      },
                    ),
                  if (user.canManageRoutes)
                    _MenuCard(
                      icon: Icons.route_outlined,
                      title: 'Gestión de rutas',
                      subtitle: 'Cargar, editar y eliminar rutas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: getIt<RouteManagementBloc>(),
                              child: const AdminRouteManagementPage(),
                            ),
                          ),
                        );
                      },
                    ),
                  if (!user.canManageUsers &&                  
                      !user.canManagePermissions &&
                      !user.canManageRoutes)
                    const _NoPermissionsCard(),
                  const SizedBox(height: 8),
                  const Text(
                    'Seguridad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualiza tu contraseña de acceso',
                    onTap: () => showChangePasswordDialog(context),
                  ),
                  const SizedBox(height: 8),
                  LogoutButton(
                    onPressed: () =>
                        context.read<AuthBloc>().add(const LogoutEvent()),
                  ),
                ],
              ),
            ),
          ),
          // Sin Billetera (el admin no tiene): tabs 0/2/3 en vez de las 4.
          // "Rutas" (índice 2) no es la del pasajero — es Gestión de rutas,
          // permiso-gateada — por eso no se delega a `navigateBottomNav`.
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 0,
            tabs: const [0, 2, 3],
            onTap: (index) {
              switch (index) {
                case 0:
                  break; // ya estamos en Inicio
                case 2:
                  if (!user.canManageRoutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No tienes permiso para gestionar rutas'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: getIt<RouteManagementBloc>(),
                        child: const AdminRouteManagementPage(),
                      ),
                    ),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PerfilPage(homeBuilder: (_) => const AdminHomePage()),
                    ),
                  );
                  break;
              }
            },
          ),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC12F),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _NoPermissionsCard extends StatelessWidget {
  const _NoPermissionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No tienes privilegios asignados. Contacta a un administrador.',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
