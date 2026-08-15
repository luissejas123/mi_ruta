import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/config/super_admin_config.dart';
import 'package:mi_ruta/features/admin/presentation/pages/super_admin_switcher_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

/// Botón "cambiar de perfil", visible para la cuenta super-admin fija (ver
/// super_admin_config.dart) o para cualquier cuenta con acceso QA activado
/// desde el panel de Admin. En cualquier otra cuenta no renderiza nada.
class SwitchProfileButton extends StatelessWidget {
  const SwitchProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final hasQaAccess = authState is AuthLoaded && authState.user.qaAccess;
    if (!isSuperAdminEmail(FirebaseAuth.instance.currentUser?.email) && !hasQaAccess) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.switch_account_outlined),
      tooltip: 'Cambiar de perfil',
      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SuperAdminSwitcherPage()),
        (route) => false,
      ),
    );
  }
}
