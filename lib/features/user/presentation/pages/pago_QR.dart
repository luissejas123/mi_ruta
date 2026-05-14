import 'package:flutter/material.dart';

class PagoQR extends StatelessWidget {
  const PagoQR({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago QR'),
      ),
      body: const Center(
        child: Text('Página de Pago QR'),
      ),
    );
  }
}