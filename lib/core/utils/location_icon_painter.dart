import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Dibuja el icono de posición GPS del usuario usando canvas.
/// Devuelve un [BitmapDescriptor] listo para usar como marcador en Google Maps.
class LocationIconPainter {
  LocationIconPainter._();

  static Future<BitmapDescriptor?> build() async {
    const double size = 56;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Halo exterior
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0x401565C0),
    );
    // Círculo principal
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size * 0.37,
      Paint()..color = const Color(0xFF1565C0),
    );
    // Borde blanco
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size * 0.37,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Flecha de navegación (triángulo apuntando arriba)
    final path = Path()
      ..moveTo(size / 2, size * 0.20)
      ..lineTo(size * 0.33, size * 0.70)
      ..lineTo(size / 2, size * 0.55)
      ..lineTo(size * 0.67, size * 0.70)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }
}
