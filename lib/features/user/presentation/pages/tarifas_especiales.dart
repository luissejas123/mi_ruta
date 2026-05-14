import 'package:flutter/material.dart';

class TarifasEspeciales extends StatelessWidget {
  const TarifasEspeciales({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas Especiales'),
      ),
      body: const Center(
        child: Text('Página de Tarifas Especiales'),
      ),
    );
  }
}