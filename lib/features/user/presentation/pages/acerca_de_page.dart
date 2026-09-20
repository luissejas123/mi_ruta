import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mi_ruta/features/user/presentation/widgets/legal_bottom_sheet.dart';

const _amarillo = Color(0xFFFFC12F);

/// "Acerca de MiRuta": guía breve de uso por perfil + acceso a los
/// Términos/EULA (reusa [LegalBottomSheet], antes solo enlazado desde el
/// registro) + versión de la app leída en vivo desde el paquete instalado
/// (nunca más un string fijo que se desincroniza de `pubspec.yaml`).
class AcercaDePage extends StatefulWidget {
  const AcercaDePage({super.key});

  @override
  State<AcercaDePage> createState() => _AcercaDePageState();
}

class _AcercaDePageState extends State<AcercaDePage> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Acerca de MiRuta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: _amarillo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus, size: 36, color: Colors.black),
                ),
                const SizedBox(height: 12),
                const Text('MiRuta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _info == null
                      ? 'Cargando versión…'
                      : 'Versión ${_info!.version} (build ${_info!.buildNumber})',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Cómo usar cada perfil',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const _ProfileGuideTile(
            icon: Icons.person_outline,
            title: 'Usuario',
            body: 'Busca rutas, planifica viajes combinando líneas, recarga tu billetera y paga tu pasaje escaneando el código QR del chofer.',
          ),
          const _ProfileGuideTile(
            icon: Icons.directions_bus_outlined,
            title: 'Chofer',
            body: 'Inicia/detiene servicio en tu unidad, ve la ruta que te asignó el dirigente, genera el QR de cobro para tus pasajeros y consulta tus ingresos.',
          ),
          const _ProfileGuideTile(
            icon: Icons.confirmation_num_outlined,
            title: 'Tickeador',
            body: 'Registra la salida y llegada de las unidades en tu estación buscándolas por placa.',
          ),
          const _ProfileGuideTile(
            icon: Icons.groups_outlined,
            title: 'Presidente (dirigente)',
            body: 'Aprueba solicitudes de chofer, asigna rutas y tickeadores, y supervisa las unidades en servicio de tu línea.',
          ),
          const _ProfileGuideTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Administrador',
            body: 'Gestiona usuarios, otorga o retira privilegios de otros administradores y mantiene el catálogo de rutas.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Legal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined, color: _amarillo),
            title: const Text('Términos y condiciones'),
            subtitle: const Text('Política de privacidad y EULA'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => LegalBottomSheet.show(context, isDriver: false),
          ),
        ],
      ),
    );
  }
}

class _ProfileGuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ProfileGuideTile({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _amarillo, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
