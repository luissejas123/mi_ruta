import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/services/pago_qr_utils_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_payment_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class PagoQRPage extends StatelessWidget {
  final WidgetBuilder? homeBuilder;
  const PagoQRPage({super.key, this.homeBuilder});

  @override
  Widget build(BuildContext context) => _PagoQRView(homeBuilder: homeBuilder);
}

class _PagoQRView extends StatefulWidget {
  final WidgetBuilder? homeBuilder;
  const _PagoQRView({this.homeBuilder});

  @override
  State<_PagoQRView> createState() => _PagoQRViewState();
}

class _PagoQRViewState extends State<_PagoQRView> {
  static const _navIndexWallet = 1;
  static const _amarillo = Color(0xFFFFC12F);
  static const _maxFileSizeBytes = 5 * 1024 * 1024;

  File? _selectedQRImage;
  final ImagePicker _picker = ImagePicker();

  String? _getUserId() {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthLoaded ? authState.user.uid : null;
  }

  void _onNavTap(int index) => navigateBottomNav(
        context, 
        index,
        homeBuilder: widget.homeBuilder,
      );

  Future<void> _scanQr() async {
    final userId = _getUserId();
    if (userId == null) {
      _showError('No se pudo obtener tu información');
      return;
    }
    final qrResult = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(title: 'Escanear QR del viaje'),
      ),
    );
    if (PagoQRUtilsService.isValidQrResult(qrResult) && mounted) {
      context.read<TripPaymentBLoC>().add(
        ProcessPaymentEvent(userId: userId, qrData: qrResult!),
      );
    }
  }

  Future<void> _pickQRFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final fileSize = await file.length();

      if (fileSize > _maxFileSizeBytes) {
        if (mounted) {
          _showError(
            'El archivo supera 5 MB (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)',
          );
        }
        return;
      }

      setState(() => _selectedQRImage = file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR cargado (${(fileSize / 1024).toStringAsFixed(0)} KB)',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  void _processQRFromImage() {
    if (_selectedQRImage == null) {
      _showError('Por favor selecciona una imagen del QR primero');
      return;
    }
    final userId = _getUserId();
    if (userId == null) {
      _showError('No se pudo obtener tu información');
      return;
    }
    context.read<TripPaymentBLoC>().add(
      ProcessPaymentEvent(userId: userId, qrData: _selectedQRImage!.path),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(TripPaymentSuccess state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('¡Pago de Bs. ${state.amount.toStringAsFixed(2)} exitoso!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
    // Ya no hacemos pop automático para que el usuario pueda ver el recibo.
  }

  Widget _buildSuccessMessage(TripPaymentSuccess state) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text(
              '¡Pago exitoso!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Monto: ${PagoQRUtilsService.formatAmount(state.amount)}'),
        const SizedBox(height: 4),
        Text('Nuevo saldo: ${PagoQRUtilsService.formatAmount(state.newBalance)}'),
      ],
    ),
  );

  Widget _buildErrorMessage(TripPaymentError state) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red, width: 2),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            state.message,
            style: TextStyle(fontSize: 14, color: Colors.red.shade700),
          ),
        ),
      ],
    ),
  );

  Widget _buildSelectedQRImage() => Column(
    children: [
      const SizedBox(height: 16),
      Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedQRImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedQRImage = null),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _processQRFromImage,
          icon: const Icon(Icons.payment, color: Colors.black),
          label: const Text(
            'Procesar pago',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _amarillo,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'PAGO CON QR',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    ),
    body: BlocListener<TripPaymentBLoC, TripPaymentState>(
      listener: (context, state) {
        if (state is TripPaymentSuccess) _showSuccess(state);
        if (state is TripPaymentError) _showError(state.message);
      },
      child: BlocBuilder<TripPaymentBLoC, TripPaymentState>(
        builder: (context, state) {
          final isLoading = state is TripPaymentLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _amarillo.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 60,
                    color: _amarillo,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pago con QR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escanea o sube el QR del conductor',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _scanQr,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.qr_code_scanner, color: Colors.black),
                    label: Text(
                      isLoading ? 'Procesando...' : 'Escanear con cámara',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickQRFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(
                      'Subir QR desde galería',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _amarillo, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Máximo 5 MB — PNG, JPG',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                if (_selectedQRImage != null) _buildSelectedQRImage(),
                if (state is TripPaymentSuccess) ...[
                  const SizedBox(height: 24),
                  _buildSuccessMessage(state),
                ] else if (state is TripPaymentError) ...[
                  const SizedBox(height: 24),
                  _buildErrorMessage(state),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    ),
    bottomNavigationBar: CustomBottomNav(
      currentIndex: _navIndexWallet,
      onTap: _onNavTap,
    ),
  );
}
