import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/confirmacion_beneficio_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class SubirFotografiaPage extends StatefulWidget {
  const SubirFotografiaPage({super.key});

  @override
  State<SubirFotografiaPage> createState() => _SubirFotografiaPageState();
}

class _SubirFotografiaPageState extends State<SubirFotografiaPage> {
  int _currentNavIndex = 1;
  final TextEditingController _fileNameController = TextEditingController();
  String? _errorText;

  bool get _isValidFile {
    final text = _fileNameController.text.trim().toLowerCase();
    return text.endsWith('.png') || text.endsWith('.jpg') || text.endsWith('.jpeg');
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  void _validateAndSend() {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty) {
      setState(() {
        _errorText = 'Selecciona un archivo png o jpg';
      });
      return;
    }

    if (!_isValidFile) {
      setState(() {
        _errorText = 'Solo se permiten archivos .png o .jpg';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfirmacionBeneficioPage(),
      ),
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            const Text(
              'SUBIR FOTOGRAFÍA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black26, width: 1.5),
              ),
              child: Center(
                child: TextField(
                  controller: _fileNameController,
                  decoration: InputDecoration(
                    hintText: 'Escribe el nombre del archivo (.png / .jpg)',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _validateAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Enviar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
