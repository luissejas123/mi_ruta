// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

class RecargaQRPage extends StatefulWidget {
  const RecargaQRPage({super.key});

  @override
  State<RecargaQRPage> createState() => _RecargaQRPageState();
}

class _RecargaQRPageState extends State<RecargaQRPage> {
  static const _navIndexWallet = 1;
  static const _amarillo = Color(0xFFFFC12F);
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  late String _userId;
  File? _selectedImage;
  final _amountController = TextEditingController();
  bool _isProcessing = false;
  bool _comprobanteEnviado = false;
  bool _isDownloading = false;
  String? _qrUrl;
  bool _loadingQR = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadQRFromFirestore();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initializeUser() {
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthLoaded ? authState.user.uid : 'user_demo';
  }

  // ✅ Carga QR desde Firestore
  Future<void> _loadQRFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('qr_recarga')
          .get();
      if (doc.exists) {
        setState(() {
          _qrUrl = doc.data()?['qr_url'] as String?;
          _loadingQR = false;
        });
      } else {
        setState(() => _loadingQR = false);
      }
    } catch (e) {
      setState(() => _loadingQR = false);
    }
  }

  // Descarga QR a la carpeta de documentos de la app (sin permiso externo)
  Future<void> _downloadQR() async {
    if (_qrUrl == null) return;
    setState(() => _isDownloading = true);

    try {
      // En Android solicitamos ambos permisos: photos (API 33+) y storage (API <33).
      // permission_handler retorna granted en el que aplique según la versión del SO.
      if (Platform.isAndroid) {
        final photosStatus = await Permission.photos.request();
        final storageStatus = await Permission.storage.request();
        if (!photosStatus.isGranted && !storageStatus.isGranted) {
          _showSnackBar('Permiso denegado para guardar imágenes', isError: true);
          setState(() => _isDownloading = false);
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          _showSnackBar('Permiso denegado para guardar imágenes', isError: true);
          setState(() => _isDownloading = false);
          return;
        }
      }

      // Descargar imagen
      final response = await http.get(Uri.parse(_qrUrl!));
      if (response.statusCode != 200) {
        _showSnackBar('Error al descargar el QR', isError: true);
        setState(() => _isDownloading = false);
        return;
      }

      // Guardar en directorio de documentos de la app (no requiere permiso adicional)
      final Uint8List bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/QR_MiRuta_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _showSnackBar('QR guardado correctamente');
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    }

    setState(() => _isDownloading = false);
  }

  void _onNavTap(int index) => navigateBottomNav(context, index);

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileName = pickedFile.name.toLowerCase();
      final extension = fileName.split('.').last;

      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        _showSnackBar('Solo se permiten archivos JPG o PNG', isError: true);
        return;
      }

      final fileSize = await file.length();
      if (fileSize > _maxFileSizeBytes) {
        _showSnackBar(
          'El archivo supera 5 MB (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)',
          isError: true,
        );
        return;
      }

      setState(() {
        _selectedImage = file;
        _comprobanteEnviado = false;
      });
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  void _submitRecharge() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Ingresa un monto válido', isError: true);
      return;
    }
    if (_selectedImage == null) {
      _showSnackBar('Sube el comprobante de la transferencia', isError: true);
      return;
    }
    setState(() => _isProcessing = true);
    context.read<RechargeBloC>().add(
      SubmitRechargeEvent(
        userId: _userId,
        amount: amount,
        proofImageFile: _selectedImage!,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: isError ? 4 : 3),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Widget _buildQRSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _amarillo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Código QR de Recarga',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingQR)
            const CircularProgressIndicator(color: Colors.black)
          else if (_qrUrl != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.network(
                _qrUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: Icon(Icons.error_outline, size: 48),
                  ),
                ),
              ),
            )
          else
            const Text('QR no disponible'),
          const SizedBox(height: 8),
          const Text(
            'Escanea este código con tu app bancaria',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          // ✅ Botón descargar
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isDownloading || _qrUrl == null ? null : _downloadQR,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.download, color: Colors.black),
              label: Text(
                _isDownloading ? 'Descargando...' : 'Guardar QR en Descargas',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _amarillo,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInstructions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Pasos para recargar:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      _buildStep('1', 'Descarga o escanea el QR con tu app bancaria'),
      _buildStep('2', 'Realiza la transferencia del monto deseado'),
      _buildStep('3', 'Ingresa el monto y sube el comprobante'),
      _buildStep('4', 'Tu solicitud pasará a revisión en 24 horas hábiles'),
    ],
  );

  Widget _buildAmountField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Monto a recargar',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: '0.00',
          prefixText: 'Bs. ',
          prefixStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _amarillo, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    ],
  );

  Widget _buildProofUpload() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Comprobante de transferencia',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        'Solo JPG o PNG • Máximo 5 MB',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _isProcessing ? null : _pickImage,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedImage != null
                  ? Colors.green
                  : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _selectedImage != null
                ? Colors.green.shade50
                : Colors.grey.shade50,
          ),
          child: _selectedImage != null
              ? Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedImage!.path.split('/').last,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedImage = null;
                              _comprobanteEnviado = false;
                            }),
                            child: const Text(
                              'Cambiar',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 32, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para subir comprobante',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ],
  );

  Widget _buildRevisionMessage() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.blue.shade300, width: 1.5),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Comprobante enviado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tu comprobante ha sido recibido y pasará a revisión. '
          'Verificaremos tus datos y actualizaremos tu saldo '
          'en un plazo de 24 horas hábiles.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _buildSubmitButton(bool isLoading) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: _isProcessing || isLoading ? null : _submitRecharge,
      style: ElevatedButton.styleFrom(
        backgroundColor: _amarillo,
        disabledBackgroundColor: Colors.grey.shade300,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.black),
              ),
            )
          : const Text(
              'Enviar comprobante',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
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
        'Recargar con QR',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    body: BlocListener<RechargeBloC, RechargeState>(
      listener: (context, state) {
        setState(() => _isProcessing = false);
        if (state is RechargeSubmitted) {
          context.read<WalletBloc>().add(LoadWalletEvent(_userId));
          setState(() {
            _comprobanteEnviado = true;
            _amountController.clear();
            _selectedImage = null;
          });
        } else if (state is RechargeError) {
          _showSnackBar(state.message, isError: true);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQRSection(),
            const SizedBox(height: 32),
            _buildInstructions(),
            const SizedBox(height: 32),
            _buildAmountField(),
            const SizedBox(height: 24),
            _buildProofUpload(),
            const SizedBox(height: 32),
            if (_comprobanteEnviado)
              _buildRevisionMessage()
            else
              BlocBuilder<RechargeBloC, RechargeState>(
                builder: (context, state) =>
                    _buildSubmitButton(state is RechargeLoading),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    bottomNavigationBar: CustomBottomNav(
      currentIndex: _navIndexWallet,
      onTap: _onNavTap,
    ),
  );
}