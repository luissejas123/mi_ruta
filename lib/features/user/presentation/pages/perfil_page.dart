
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/change_password_dialog.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_preferences_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_preferences_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_preferences_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/editar_perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/historial_beneficios_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/historial_viajes_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/historial_ingresos_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_assigned_routes_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/tickeador_operations_history_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/tickeador_operation_register_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/notificaciones_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/planificar_viaje_page.dart';
import 'package:mi_ruta/features/stops/presentation/pages/paradas_cercanas_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/profile_header.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/legal_bottom_sheet.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_trip_history_page.dart';

class PerfilPage extends StatefulWidget {
  /// A qué pantalla vuelve la pestaña "Inicio" del pie de navegación.
  /// Nulo = MiRutaScreen (pasajero); los demás perfiles pasan su propio home.
  final WidgetBuilder? homeBuilder;

  const PerfilPage({super.key, this.homeBuilder});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const _amarillo = Color(0xFFFFC12F);
  static const _navIndexPerfil = 3;

  /// El botón del panel administrativo solo se muestra a role == "admin".
  bool get _isAdmin {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthLoaded && authState.user.role == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthLoaded) {
      context.read<UserBloc>().add(
        StartUserStreamEvent(uid: authState.user.uid),
      );
      context.read<WalletBloc>().add(LoadWalletEvent(authState.user.uid));
    }
  }

  void _onNavTap(int index) {
    navigateBottomNav(context, index, homeBuilder: widget.homeBuilder);
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

  void _cerrarSesion() {    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);

              context.read<AuthBloc>().add(
                const LogoutEvent(),
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
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
        child: Icon(
          icon,
          color: iconColor ?? _amarillo,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        4,
      ),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocConsumer<UserBloc, UserState>(
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
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadUser,
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

          final user = state is UserLoaded
              ? state.user
              : state is UserStreamLoaded
              ? state.user
              : null;

            if (user == null) {
              return const Center(
                child: Text(
                  'No se encontraron datos del usuario',
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    name: user.fullName,
                    email: user.email,
                    imageUrl: user.profileImageUrl,
                    onEditTap: () =>
                        _navigateToEditarPerfil(
                      user.uid,
                      user.fullName,
                      user.email,
                      user.phoneNumber,
                      user.profileImageUrl,
                    ),
                  ),

                  const Divider(height: 1),

                  // ==================================================
                  // MI CUENTA
                  // ==================================================

                  _buildSectionTitle('MI CUENTA'),

                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Información personal',
                    subtitle: user.fullName,
                    onTap: () =>
                        _navigateToEditarPerfil(
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
                    onTap: () =>
                        _navigateToEditarPerfil(
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
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualiza tu contraseña de acceso',
                  onTap: () => showChangePasswordDialog(context),
                ),

                  _buildMenuItem(
                    icon: Icons.history,
                    title: (context.read<AuthBloc>().state as AuthLoaded).user.role == 'driver' ? 'Historial del conductor' : 'Historial de viajes',
                    subtitle: 'Ver todos tus viajes',
                    onTap: () {
                      final authState = context.read<AuthBloc>().state;
                      print("DEBUG PERFIL ROLE: ${authState.user.role}");
                      print("DEBUG PERFIL UID: ${authState.user.uid}");
                      if (authState is AuthLoaded) {
                        if (authState.user.role == "driver") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverTripHistoryPage(driverId: authState.user.uid),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistorialViajesPage(),
                            ),
                          );
                        }
                      }
                    },
                  ),
                if (user.userType == 'tickeador')
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Historial de operaciones',
                    subtitle: 'Salidas y llegadas registradas',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TickeadorOperationsHistoryPage(),
                      ),
                    ),
                  ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Viajes, recargas y regalos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificacionesPage(),
                    ),
                  ),

                  _buildMenuItem(
                    icon: Icons.map_outlined,
                    title: 'Planificar viaje',
                    subtitle:
                        'Combina líneas para llegar a tu destino',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PlanificarViajePage(),
                      ),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.pin_drop_outlined,
                  title: 'Paradas cercanas',
                  subtitle: 'Encuentra paradas de bus cerca de ti',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlanificarViajePage(),
                    ),
                  ),
                ),

                // ── Panel administrativo (solo admins) ──
                if (_isAdmin)
                  _buildSectionTitle('PANEL ADMINISTRATIVO'),
                if (_isAdmin)
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Panel administrativo',
                    subtitle: 'Gestión de usuarios y privilegios',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminHomePage(),
                      ),
                    ),
                  ),

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

                _buildSectionTitle('SUPERVISIÓN'),
                _buildMenuItem(
                  icon: Icons.assessment_outlined,
                  title: 'Reportes operativos',
                  subtitle: 'Estado y desempeño de choferes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportesOperativosPage(),
                    ),
                  ),
                ),

                // ── Apariencia ──
                _buildSectionTitle('APARIENCIA'),
                // ✅ Botón modo oscuro con switch
                _buildMenuItem(
                  icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  title: 'Modo oscuro',
                  subtitle: isDarkMode ? 'Activado' : 'Desactivado',
                  onTap: () => context.read<ThemeCubit>().toggleTheme(),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                    activeColor: _amarillo,
                  ),
                ),

                  // ==================================================
                  // APLICACIÓN
                  // ==================================================

                  _buildSectionTitle('APLICACIÓN'),

                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'Acerca de MiRuta',
                    subtitle: 'Versión 1.0.0',
                    onTap: () {},
                  ),

                  // ==================================================
                  // SESIÓN
                  // ==================================================

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
      ),
    );
  }
}
