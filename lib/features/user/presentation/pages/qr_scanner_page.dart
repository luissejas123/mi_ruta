import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  final String title;
  const QRScannerPage({super.key, this.title = 'Escanear código QR'});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  static const _frameSize = 280.0;
  static const _cornerSize = 30.0;
  static const _cornerRadius = 8.0;
  static const _borderWidth = 3.0;
  // ✅ Color consistente
  static const _amarillo = Color(0xFFFFC12F);

  final MobileScannerController _controller = MobileScannerController();
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() => _isTorchOn = !_isTorchOn);
    _controller.toggleTorch();
  }

  void _onQrDetected(Barcode barcode) {
    final qrCode = barcode.rawValue ?? '';
    Navigator.of(context).pop(qrCode);
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(
      widget.title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    actions: [
      IconButton(
        icon: Icon(
          _isTorchOn ? Icons.flash_on : Icons.flash_off,
          color: _isTorchOn ? _amarillo : Colors.white,
        ),
        onPressed: _toggleTorch,
      ),
    ],
  );

  Widget _buildQRCorner({
    required Alignment alignment,
    required BorderRadius radius,
  }) =>
      Positioned.fill(
        child: Align(
          alignment: alignment,
          child: Container(
            width: _cornerSize,
            height: _cornerSize,
            decoration: BoxDecoration(
              border: _buildCornerBorder(alignment),
              borderRadius: radius,
            ),
          ),
        ),
      );

  Border _buildCornerBorder(Alignment alignment) {
    // ✅ Color amarillo consistente
    const color = _amarillo;
    const width = 4.0;

    return switch (alignment) {
      Alignment.topLeft => const Border(
        top: BorderSide(color: color, width: width),
        left: BorderSide(color: color, width: width),
      ),
      Alignment.topRight => const Border(
        top: BorderSide(color: color, width: width),
        right: BorderSide(color: color, width: width),
      ),
      Alignment.bottomLeft => const Border(
        bottom: BorderSide(color: color, width: width),
        left: BorderSide(color: color, width: width),
      ),
      Alignment.bottomRight => const Border(
        bottom: BorderSide(color: color, width: width),
        right: BorderSide(color: color, width: width),
      ),
      _ => const Border.fromBorderSide(
        BorderSide(color: color, width: width),
      ),
    };
  }

  Widget _buildScanFrame() => Container(
    width: _frameSize,
    height: _frameSize,
    decoration: BoxDecoration(
      // ✅ Borde amarillo en frame
      border: Border.all(color: _amarillo, width: _borderWidth),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Stack(
      children: [
        _buildQRCorner(
          alignment: Alignment.topLeft,
          radius: const BorderRadius.only(
            topLeft: Radius.circular(_cornerRadius),
          ),
        ),
        _buildQRCorner(
          alignment: Alignment.topRight,
          radius: const BorderRadius.only(
            topRight: Radius.circular(_cornerRadius),
          ),
        ),
        _buildQRCorner(
          alignment: Alignment.bottomLeft,
          radius: const BorderRadius.only(
            bottomLeft: Radius.circular(_cornerRadius),
          ),
        ),
        _buildQRCorner(
          alignment: Alignment.bottomRight,
          radius: const BorderRadius.only(
            bottomRight: Radius.circular(_cornerRadius),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: _buildAppBar(),
    body: Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) _onQrDetected(barcodes.first);
          },
        ),
        _buildScanFrame(),
      ],
    ),
  );
}