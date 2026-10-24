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
import 'package:mi_ruta/features/user/presentation/widgets/logout_button.dart' show confirmLogout;

const _amarillo = Color(0xFFFFC12F);

Color _profileColorForLabel(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('pasajero')) return const Color(0xFFFFC12F);
  if (normalized.contains('chofer')) return const Color(0xFF8D5E3B);
  if (normalized.contains('dirigente') || normalized.contains('presidente')) {
    return const Color(0xFFEF6C00);
  }
  if (normalized.contains('administrador')) return const Color(0xFF7C4DFF);
  if (normalized.contains('tickeador')) return const Color(0xFF7C4DFF);
  return _amarillo;
}

/// Selector de perfiles para la cuenta super-admin: navega a cada home ya
/// existente, sin lógica de negocio nueva — solo decide a qué pantalla ir.
class SuperAdminSwitcherPage extends StatelessWidget {
  const SuperAdminSwitcherPage({super.key});

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
        automaticallyImplyLeading: false,
        title: const Text(
          'Selector de perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Acceso de prueba: entra a cualquier perfil sin cambiar de cuenta.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          _ProfileTile(
            icon: Icons.person_outline,
            label: 'Pasajero',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MiRutaScreen()),
            ),
          ),
          _ProfileTile(
            icon: Icons.directions_bus_outlined,
            label: 'Chofer',
            onTap: () => _openChofer(context, asPresidente: false),
          ),
          _ProfileTile(
            icon: Icons.how_to_reg_outlined,
            label: 'Dirigente (presidente)',
            onTap: () => _openChofer(context, asPresidente: true),
          ),
          _ProfileTile(
            icon: Icons.manage_accounts_outlined,
            label: 'Administrador',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            ),
          ),
          _ProfileTile(
            icon: Icons.qr_code_scanner,
            label: 'Tickeador',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TickeadorHomePage()),
            ),
          ),
          _ProfileTile(
            icon: Icons.analytics_outlined,
            label: 'Panel de dirigencia (directo)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PresidentePanelPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _profileColorForLabel(label);
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
            border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 26),
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
              Icon(Icons.arrow_forward_ios, color: accentColor.withValues(alpha: 0.7), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
