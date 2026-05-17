import 'package:flutter/material.dart';

/// Pin animado que se muestra centrado en el mapa durante el modo arrastrable.
/// Flota hacia arriba mientras el mapa se mueve y baja al detenerse.
class MapPinOverlay extends StatelessWidget {
  final bool isCameraMoving;

  const MapPinOverlay({super.key, required this.isCameraMoving});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0,
                isCameraMoving ? -14 : 0,
                0,
              ),
              child: const Icon(
                Icons.location_pin,
                color: Color(0xFFFBC02D),
                size: 52,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isCameraMoving ? 6 : 14,
              height: isCameraMoving ? 3 : 6,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
