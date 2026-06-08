import 'package:flutter/material.dart';

class PagoQr extends StatelessWidget {
  const PagoQr({super.key});

  @override
  Widget build(BuildContext context) {
    const Color amarillo = Color(0xFFF4C430);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: amarillo,
                  size: 34,
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              'PAGO CON QR',
              style: TextStyle(
                color: amarillo,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Escanee el código',
              style: TextStyle(
                color: amarillo,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 45),

            const Icon(
              Icons.photo_camera_outlined,
              color: amarillo,
              size: 90,
            ),

            const SizedBox(height: 50),

            Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    Positioned(
                      top: 148,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        color: Colors.red,
                      ),
                    ),

                    const Positioned(
                      top: 0,
                      left: 0,
                      child: CornerWidget(),
                    ),

                    const Positioned(
                      top: 0,
                      right: 0,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: CornerWidget(),
                      ),
                    ),

                    const Positioned(
                      bottom: 0,
                      left: 0,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: CornerWidget(),
                      ),
                    ),

                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: CornerWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CornerWidget extends StatelessWidget {
  const CornerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(
        painter: CornerPainter(),
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFF4C430);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}