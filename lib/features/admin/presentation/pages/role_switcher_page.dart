import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_panel_page.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_home_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';

const _amarillo = Color(0xFFFFC12F);

/// Selector de perfil para una cuenta real con más de un rol simultáneo
/// (ej. chofer + presidente + user). Solo navega a un home ya existente —
/// no cambia `role`/`roles` en Firestore, ni siquiera cuál era el "activo":
/// la cuenta puede volver a entrar por cualquiera de sus roles la próxima
/// vez, decide `homeScreenForRole` con el rol de mayor prioridad.
///
/// No confundir con `SuperAdminSwitcherPage`: esa es el acceso de prueba
/// QA/superadmin a los 5 perfiles sin importar los roles reales de la
/// cuenta. Esta solo muestra [ownedRoles].
class RoleSwitcherPage extends StatelessWidget {
  final List<String> ownedRoles;

  const RoleSwitcherPage({super.key, required this.ownedRoles});

  Future<void> _openChofer(BuildContext context, {required bool asPresidente}) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _amarillo)),
    );
    try {
      await getIt<DriverService>().ensureDemoVehicle(authState.user.uid);
    } catch (_) {
      // Si falla, DriverHomePage igual maneja el caso "sin unidad asignada".
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverHomePage(roleOverride: asPresidente ? 'presidente' : 'driver'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Cambiar de perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Esta cuenta tiene varios roles. Elige con cuál entrar.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (ownedRoles.contains('user'))
            _RoleTile(
              icon: Icons.person_outline,
              label: 'Pasajero',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MiRutaScreen()),
              ),
            ),
          if (ownedRoles.contains('driver'))
            _RoleTile(
              icon: Icons.directions_bus_outlined,
              label: 'Chofer',
              onTap: () => _openChofer(context, asPresidente: false),
            ),
          if (ownedRoles.contains('presidente'))
            _RoleTile(
              icon: Icons.how_to_reg_outlined,
              label: 'Dirigente (presidente)',
              onTap: () => ownedRoles.contains('driver')
                  ? _openChofer(context, asPresidente: true)
                  : Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PresidentePanelPage()),
                    ),
            ),
          if (ownedRoles.contains('admin'))
            _RoleTile(
              icon: Icons.manage_accounts_outlined,
              label: 'Administrador',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminHomePage()),
              ),
            ),
          if (ownedRoles.contains('tickeador'))
            _RoleTile(
              icon: Icons.qr_code_scanner,
              label: 'Tickeador',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TickeadorHomePage()),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurface, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
