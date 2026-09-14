import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// El admin sube el QR de recarga que ven todos los pasajeros en
/// `RecargaQrPage` (`config/qr_recarga.qr_url`, ya dinámico — solo faltaba
/// esta pantalla, ver docs/PLAN_SEGURIDAD_TARIFAS_GPS.md Bloque 1).
class ActualizarQrRecargaPage extends StatefulWidget {
  const ActualizarQrRecargaPage({super.key});

  @override
  State<ActualizarQrRecargaPage> createState() => _ActualizarQrRecargaPageState();
}

class _ActualizarQrRecargaPageState extends State<ActualizarQrRecargaPage> {
  final _picker = ImagePicker();
  bool _loading = true;
  bool _uploading = false;
  String? _currentQrUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc('qr_recarga').get();
      if (!mounted) return;
      setState(() {
        _currentQrUrl = doc.data()?['qr_url'] as String?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      setState(() => _uploading = true);
      final url = await getIt<StorageService>().uploadConfigImage(
        configKey: 'qr_recarga',
        imageFile: File(picked.path),
      );
      await FirebaseFirestore.instance.collection('config').doc('qr_recarga').set({
        'qr_url': url,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _currentQrUrl = url;
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('QR de recarga actualizado'), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el QR: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('QR de recarga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amarillo))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Este QR es el que ven todos los pasajeros al recargar saldo.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _currentQrUrl == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('Todavía no se configuró ningún QR.')),
                          )
                        : Image.network(_currentQrUrl!, height: 240, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickAndUpload,
                      icon: _uploading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.upload_outlined, color: Colors.black),
                      label: Text(
                        _currentQrUrl == null ? 'Subir QR' : 'Actualizar QR',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
