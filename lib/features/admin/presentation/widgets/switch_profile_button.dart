import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/pages/super_admin_switcher_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

/// Botón "cambiar de perfil", visible solo para cuentas con `is_super_admin`
/// en Firestore. En cualquier otra cuenta no renderiza nada.
class SwitchProfileButton extends StatelessWidget {
  const SwitchProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthLoaded) return const SizedBox.shrink();
    final user = authState.user;
    if (!user.isSuperAdmin) {
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
