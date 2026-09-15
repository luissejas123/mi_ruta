import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_conductor_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';

class PerfilRolPage extends StatelessWidget {
  const PerfilRolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthLoaded
        ? authState.user.role.trim().toLowerCase()
        : '';

    if (role == 'driver' || role == 'conductor') {
      return const PerfilConductorPage();
    }

    return const PerfilPage();
  }
}
