import 'package:flutter/material.dart';
import 'package:mi_ruta/features/notifications/presentation/pages/notification_demo_screens.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static final List<_NotificationDemoItem> _demos = [
    _NotificationDemoItem(
      title: '1. Registro completado',
      builder: (_) => const RegistroCompletadoScreen(),
    ),
    _NotificationDemoItem(
      title: '2. Carga / mala conexión',
      builder: (_) => const LoadingConnectionScreen(),
    ),
    _NotificationDemoItem(
      title: '3. Abono saldo exitoso',
      builder: (_) => const AbonoSaldoExitosoScreen(),
    ),
    _NotificationDemoItem(
      title: '4. Pago exitoso',
      builder: (_) => const PagoExitosoScreen(),
    ),
    _NotificationDemoItem(
      title: '5. Carnet subido exitosamente',
      builder: (_) => const ConfirmacionBeneficioScreen(),
    ),
    _NotificationDemoItem(
      title: '6. Servicio activo',
      builder: (_) => const ServicioActivoScreen(),
    ),
    _NotificationDemoItem(
      title: '7. Servicio suspendido',
      builder: (_) => const ServicioSuspendidoScreen(),
    ),
    _NotificationDemoItem(
      title: '8. Anunciaste tu parada',
      builder: (_) => const ParadaMicroScreen(),
    ),
    _NotificationDemoItem(
      title: '9. Completaste tu viaje',
      builder: (_) => const CalificacionViajeScreen(),
    ),
    _NotificationDemoItem(
      title: '10. Descuento especial',
      builder: (_) => const DescuentoEspecialScreen(),
    ),
    _NotificationDemoItem(
      title: '11. Saldo bajo',
      builder: (_) => const SaldoBajoScreen(),
    ),
    _NotificationDemoItem(
      title: '12. Cambio de ruta',
      builder: (_) => const CambioRutaNotificationScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones de prueba'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemBuilder: (context, index) {
          final item = _demos[index];
          return ListTile(
            title: Text(item.title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: item.builder),
              );
            },
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _demos.length,
      ),
    );
  }
}

class _NotificationDemoItem {
  final String title;
  final WidgetBuilder builder;

  const _NotificationDemoItem({
    required this.title,
    required this.builder,
  });
}
