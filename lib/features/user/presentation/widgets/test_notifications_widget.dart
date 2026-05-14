import 'package:flutter/material.dart';
import 'features/shared/widgets/floating_notifications.dart';

class TestNotificationsWidget extends StatefulWidget {
  const TestNotificationsWidget({super.key});

  @override
  State<TestNotificationsWidget> createState() => _TestNotificationsWidgetState();
}

class _TestNotificationsWidgetState extends State<TestNotificationsWidget> {
  OverlayEntry? _overlayEntry;

  void _showFloatingNotification() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 206,
        left: 20,
        child: FloatingNotification(
          message: '¡Felicidades! recibiste un descuento especial',
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _showFloatingGift() {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 621,
        left: 256,
        child: const FloatingGift(),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showFloatingNotification,
              child: const Text('Mostrar Notificación Flotante'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showFloatingGift,
              child: const Text('Mostrar Regalo Flotante'),
            ),
          ],
        ),
      ),
    );
  }
}