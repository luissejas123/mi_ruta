import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// "QR de mi unidad" — código FIJO (no expira, a diferencia del QR de cobro
/// por transacción de `ChargeSection`) que identifica la unidad/chofer, para
/// imprimir y colgar en el vehículo ("5.4.1 Cobrar Viaje", Figma). Repuesta
/// del botón "ACTUALIZAR QR" de la billetera del chofer, que antes abría el
/// mismo flujo transaccional que "MOSTRAR QR" — son dos QR con propósitos
/// distintos, no un mismo mecanismo duplicado.
///
/// Codifica solo `ownerUid|vehicleId`: identifica la unidad para un futuro
/// flujo de verificación, sin simular un estándar de pago QR bancario real
/// (eso requeriría integrarse con un proveedor de pagos boliviano, fuera de
/// alcance aquí — no se finge esa integración).
class UnitQrPage extends StatefulWidget {
  final VehicleEntity vehicle;

  /// Nombre del chofer dueño-operador (con el que se registró) — el
  /// pasajero/tickeador que escanea el QR necesita saber a quién le está
  /// pagando, no solo la placa.
  final String driverName;

  const UnitQrPage({super.key, required this.vehicle, required this.driverName});

  @override
  State<UnitQrPage> createState() => _UnitQrPageState();
}

class _UnitQrPageState extends State<UnitQrPage> {
  final _qrBoundaryKey = GlobalKey();
  final _picker = ImagePicker();
  late String _logoUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.vehicle.legalDocumentation['qr_logo_url'] ?? '';
  }

  String get _qrData => '${widget.vehicle.ownerUid}|${widget.vehicle.vehicleId}';

  Future<void> _pickLogo() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() => _busy = true);
      final url = await getIt<StorageService>().uploadVehicleDocument(
        ownerUid: widget.vehicle.ownerUid,
        plate: widget.vehicle.vehicleId,
        docKey: 'qr_logo',
        imageFile: File(picked.path),
      );
      await getIt<DriverService>().updateVehicleQrLogo(widget.vehicle.vehicleId, url);
      if (!mounted) return;
      setState(() {
        _logoUrl = url;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la imagen: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _downloadQr() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _qrBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_unidad_${widget.vehicle.vehicleId}.png');
      await file.writeAsBytes(bytes);
      await getIt<DriverService>().shareFile(file, subject: 'QR de mi unidad - Mi Ruta');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la imagen: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('QR de mi unidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RepaintBoundary(
              key: _qrBoundaryKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: _qrData,
                      size: 240,
                      embeddedImage: _logoUrl.isNotEmpty ? NetworkImage(_logoUrl) : null,
                      embeddedImageStyle: _logoUrl.isNotEmpty
                          ? const QrEmbeddedImageStyle(size: Size(48, 48))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.driverName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      'Placa ${vehicle.vehicleId} · Línea ${vehicle.lineNumber}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Este código identifica tu unidad — imprímelo y cuélgalo en el vehículo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickLogo,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Elegir imagen de galería para el centro'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _downloadQr,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.download_outlined, color: Colors.black),
                label: const Text('Descargar / compartir QR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
