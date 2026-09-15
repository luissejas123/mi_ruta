import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_payment_page.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/editar_perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/profile_header.dart';

class PerfilConductorPage extends StatefulWidget {
  const PerfilConductorPage({super.key});

  @override
  State<PerfilConductorPage> createState() => _PerfilConductorPageState();
}

class _PerfilConductorPageState extends State<PerfilConductorPage> {
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
    }
  }

  void _editProfile(UserState state) {
    if (state is! UserLoaded && state is! UserStreamLoaded) return;
    final user = state is UserLoaded
        ? state.user
        : (state as UserStreamLoaded).user;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<UserBloc>(),
          child: EditarPerfilPage(
            uid: user.uid,
            fullName: user.fullName,
            email: user.email,
            phone: user.phoneNumber,
            imageUrl: user.profileImageUrl,
          ),
        ),
      ),
    ).then((_) => _loadUser());
  }

  void _logout() {
    context.read<AuthBloc>().add(const LogoutEvent());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Perfil de conductor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
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

          return ListView(
            children: [
              ProfileHeader(
                name: user.fullName,
                email: user.email,
                imageUrl: user.profileImageUrl,
                onEditTap: () => _editProfile(state),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: const Text('Rol'),
                subtitle: const Text('Conductor'),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Teléfono'),
                subtitle: Text(
                  user.phoneNumber.isNotEmpty
                      ? user.phoneNumber
                      : 'No registrado',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Cobrar viaje'),
                subtitle: const Text('Generar QR para el pasajero'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverPaymentPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) => navigateBottomNav(context, index),
      ),
    );
  }
}
