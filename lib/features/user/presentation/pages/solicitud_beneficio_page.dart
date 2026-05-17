import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/subir_fotografia_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class SolicitudBeneficioPage extends StatefulWidget {
  const SolicitudBeneficioPage({super.key});

  @override
  State<SolicitudBeneficioPage> createState() => _SolicitudBeneficioPageState();
}

class _SolicitudBeneficioPageState extends State<SolicitudBeneficioPage> {
  int _currentNavIndex = 1;

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Solicitud de Beneficio',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _buildOptionButton('Estudiante'),
            const SizedBox(height: 20),
            _buildOptionButton('Universitario'),
            const SizedBox(height: 20),
            _buildOptionButton('Adulto mayor'),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildOptionButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubirFotografiaPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5C210),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
