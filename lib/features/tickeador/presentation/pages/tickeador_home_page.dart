import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';

/// Panel de entrada del tickeador (RQ-97): escanea el QR del pasajero al
/// abordar. Hoy es 100% demo — no consulta Firestore por el uid escaneado
/// ni inventa datos falsos de pasajero; solo confirma que se leyó un
/// código y simula el registro del abordaje. Cuando exista acceso a
/// Firestore real, acá se buscaría el usuario por uid y se escribiría un
/// doc en `station_logs` (ver firestore.rules).
class TickeadorHomePage extends StatefulWidget {
  const TickeadorHomePage({super.key});

  @override
  State<TickeadorHomePage> createState() => _TickeadorHomePageState();
}

class _TickeadorHomePageState extends State<TickeadorHomePage> {
  static const _amarillo = Color(0xFFFFC12F);

  String? _scannedCode;
  bool _registered = false;

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(title: 'Escanear pasajero'),
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() {
      _scannedCode = code;
      _registered = false;
    });
  }

  void _registrarAbordaje() {
    setState(() => _registered = true);
  }

  void _limpiar() {
    setState(() {
      _scannedCode = null;
      _registered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickeador',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _scannedCode == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner,
                        size: 72,
                        color: colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('Escaneá el código QR del pasajero al subir.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _scan,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear pasajero'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amarillo,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _registered ? Icons.check_circle : Icons.person_outline,
                      size: 72,
                      color: _registered ? Colors.green : _amarillo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _registered
                          ? '✓ Abordaje registrado'
                          : 'Código escaneado',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_scannedCode!,
                          style: const TextStyle(fontFamily: 'monospace')),
                    ),
                    const SizedBox(height: 24),
                    if (!_registered)
                      ElevatedButton(
                        onPressed: _registrarAbordaje,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amarillo,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        child: const Text('Registrar abordaje (demo)'),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _limpiar,
                      child: const Text('Escanear otro'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
