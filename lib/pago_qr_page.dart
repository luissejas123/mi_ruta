import 'package:flutter/material.dart';

class PagoQRPage extends StatelessWidget {
  const PagoQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],

      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PAGO QR',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// TITULO
            const Text(
              'PAGO CON QR',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            /// SUBTITULO
            const Text(
              'Escanea el codigo',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            /// ICONO CAMARA
            const Icon(
              Icons.camera_alt_outlined,
              size: 90,
              color: Colors.black54,
            ),

            const SizedBox(height: 40),

            /// CUADRO QR
            Stack(
              alignment: Alignment.center,
              children: [

                /// FONDO
                Container(
                  width: 250,
                  height: 250,
                  color: Colors.white,
                ),

                /// LINEA ROJA
                Container(
                  width: 250,
                  height: 4,
                  color: Colors.red,
                ),

                /// ESQUINAS
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CustomPaint(
                    painter: ScannerPainter(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// DIBUJO ESQUINAS QR
class ScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    double c = 40;

    /// SUPERIOR IZQUIERDA
    canvas.drawLine(
      const Offset(0, 0),
      Offset(c, 0),
      paint,
    );

    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, c),
      paint,
    );

    /// SUPERIOR DERECHA
    canvas.drawLine(
      Offset(size.width - c, 0),
      Offset(size.width, 0),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, c),
      paint,
    );

    /// INFERIOR IZQUIERDA
    canvas.drawLine(
      Offset(0, size.height - c),
      Offset(0, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height),
      Offset(c, size.height),
      paint,
    );

    /// INFERIOR DERECHA
    canvas.drawLine(
      Offset(size.width - c, size.height),
      Offset(size.width, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height - c),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}