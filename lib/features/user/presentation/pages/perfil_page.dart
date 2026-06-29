import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
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
      context.read<WalletBloc>().add(
        LoadWalletEvent(authState.user.uid),
      );
    }
  }

  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const IniciarSesionPage(),
                ),
                (route) => false,
              );
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
    Widget? trailing,
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
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle)
          : null,
      trailing: trailing ??
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
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
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
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
                  Text(state.message),
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
                ProfileHeader(
                  name: user.fullName,
                  email: user.email,
                  imageUrl: user.profileImageUrl,
                  onEditTap: () => _navigateToEditarPerfil(
                    user.uid,
                    user.fullName,
                    user.email,
                    user.phoneNumber,
                    user.profileImageUrl,
                  ),
                ),
                const Divider(height: 1),

                // ── Mi cuenta ──
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

                // ── Billetera ──
                _buildSectionTitle('BILLETERA'),
                BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, walletState) {
                    String saldo = 'Bs. 0.00';
                    if (walletState is WalletLoaded) {
                      saldo =
                          '${walletState.wallet.currency} ${walletState.wallet.currentBalance.toStringAsFixed(2)}';
                    } else if (walletState is WalletOperationSuccess) {
                      saldo =
                          '${walletState.updatedWallet.currency} ${walletState.updatedWallet.currentBalance.toStringAsFixed(2)}';
                    } else if (walletState is TransactionHistoryLoaded) {
                      saldo =
                          '${walletState.wallet.currency} ${walletState.wallet.currentBalance.toStringAsFixed(2)}';
                    }
                    return _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Saldo disponible',
                      subtitle: saldo,
                      onTap: () => navigateBottomNav(context, 1),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'Acceder a beneficios',
                  subtitle: 'Estudiante, Universitario, Adulto mayor',
                  onTap: () => navigateBottomNav(context, 1),
                ),

                // ── Apariencia ──
                _buildSectionTitle('APARIENCIA'),
                // ✅ Botón modo oscuro con switch
                _buildMenuItem(
                  icon: isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'Modo oscuro',
                  subtitle: isDarkMode ? 'Activado' : 'Desactivado',
                  onTap: () => context.read<ThemeCubit>().toggleTheme(),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) =>
                        context.read<ThemeCubit>().toggleTheme(),
                    activeColor: _amarillo,
                  ),
                ),

                // ── Aplicación ──
                _buildSectionTitle('APLICACIÓN'),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Acerca de MiRuta',
                  subtitle: 'Versión 1.0.0',
                  onTap: () {},
                ),

                // ── Sesión ──
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