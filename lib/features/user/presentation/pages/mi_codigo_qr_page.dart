import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// RQ-97: código QR del pasajero — el tickeador lo escanea para validar
/// el abordaje. Solo codifica el propio [uid], ya conocido por la app
/// (sin ninguna lectura a Firestore).
class MiCodigoQrPage extends StatelessWidget {
  final String uid;

  const MiCodigoQrPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi código QR',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: uid,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Muéstrale este código al tickeador al subir al bus.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
