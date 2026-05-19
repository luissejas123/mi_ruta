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
          color: Colors.white,
        ),
        onPressed: _toggleTorch,
      ),
    ],
  );

  Widget _buildQRCorner({
    required Alignment alignment,
    required BorderRadius radius,
  }) => Positioned.fill(
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
    final color = Colors.yellow[700]!;
    final width = 4.0;

    return switch (alignment) {
      Alignment.topLeft => Border(
        top: BorderSide(color: color, width: width),
        left: BorderSide(color: color, width: width),
      ),
      Alignment.topRight => Border(
        top: BorderSide(color: color, width: width),
        right: BorderSide(color: color, width: width),
      ),
      Alignment.bottomLeft => Border(
        bottom: BorderSide(color: color, width: width),
        left: BorderSide(color: color, width: width),
      ),
      Alignment.bottomRight => Border(
        bottom: BorderSide(color: color, width: width),
        right: BorderSide(color: color, width: width),
      ),
      _ => Border.all(color: color, width: width),
    };
  }

  Widget _buildScanFrame() => Container(
    width: _frameSize,
    height: _frameSize,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white, width: _borderWidth),
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
