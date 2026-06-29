import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/editar_perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/profile_header.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const _amarillo = Color(0xFFFFC12F);
  static const _navIndexPerfil = 3;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      context.read<UserBloc>().add(
        GetUserByIdEvent(uid: authState.user.uid),
      );
    }
  }

  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

  // ✅ Ahora recibe imageUrl también
  void _navigateToEditarPerfil(
    String uid,
    String fullName,
    String email,
    String phone,
    String imageUrl,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<UserBloc>(),
          child: EditarPerfilPage(
            uid: uid,
            fullName: fullName,
            email: email,
            phone: phone,
            imageUrl: imageUrl,
          ),
        ),
      ),
    ).then((_) => _loadUser());
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: (iconColor ?? _amarillo).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? _amarillo, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.black54))
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.black38,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black45,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        // No redibujar cuando llega UserOperationSuccess para no perder
        // los datos del usuario que ya estaban visibles.
        buildWhen: (previous, current) => current is! UserOperationSuccess,
        listener: (context, state) {
          if (state is UserOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
          if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _amarillo),
            );
          }

          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo,
                    ),
                    child: const Text('Reintentar',
                        style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          }

          final user = state is UserLoaded
              ? state.user
              : state is UserStreamLoaded
                  ? state.user
                  : null;

          if (user == null) {
            return const Center(
              child: Text('No se encontraron datos del usuario'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Encabezado con foto y datos
                ProfileHeader(
                  name: user.fullName,
                  email: user.email,
                  imageUrl: user.profileImageUrl,
                  onEditTap: () => _navigateToEditarPerfil(
                    user.uid,
                    user.fullName,
                    user.email,
                    user.phoneNumber,
                    user.profileImageUrl, // ✅ nuevo
                  ),
                ),
                const Divider(height: 1),

                // ── Sección cuenta ──
                _buildSectionTitle('MI CUENTA'),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Información personal',
                  subtitle: user.fullName,
                  onTap: () => _navigateToEditarPerfil(
                    user.uid,
                    user.fullName,
                    user.email,
                    user.phoneNumber,
                    user.profileImageUrl,
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.phone_outlined,
                  title: 'Teléfono',
                  subtitle: user.phoneNumber.isNotEmpty
                      ? user.phoneNumber
                      : 'No registrado',
                  onTap: () => _navigateToEditarPerfil(
                    user.uid,
                    user.fullName,
                    user.email,
                    user.phoneNumber,
                    user.profileImageUrl,
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.email_outlined,
                  title: 'Correo electrónico',
                  subtitle: user.email,
                  onTap: () {},
                ),

                // ── Sección billetera ──
                _buildSectionTitle('BILLETERA'),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Saldo disponible',
                  subtitle:
                      'Bs. ${user.walletBalance.toStringAsFixed(2)}',
                  onTap: () => navigateBottomNav(context, 1),
                ),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'Acceder a beneficios',
                  subtitle: 'Estudiante, Universitario, Adulto mayor',
                  onTap: () => navigateBottomNav(context, 1),
                ),

                // ── Sección app ──
                _buildSectionTitle('APLICACIÓN'),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Acerca de MiRuta',
                  subtitle: 'Versión 1.0.0',
                  onTap: () {},
                ),

                // ── Cerrar sesión ──
                _buildSectionTitle('SESIÓN'),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Cerrar sesión',
                  iconColor: Colors.red.shade400,
                  titleColor: Colors.red.shade400,
                  onTap: _cerrarSesion,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndexPerfil,
        onTap: _onNavTap,
      ),
    );
  }
}