// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/qr_code_widget.dart';

class RecargaQRPage extends StatefulWidget {
  const RecargaQRPage({super.key});

  @override
  State<RecargaQRPage> createState() => _RecargaQRPageState();
}

class _RecargaQRPageState extends State<RecargaQRPage> {
  static const _navIndexWallet = 1;
  static const _qrSize = 220.0;
  static const _defaultUserId = 'user_demo';

  late String _userId;
  File? _selectedImage;
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initializeUser() {
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthLoaded ? authState.user.uid : _defaultUserId;
  }

  void _onNavTap(int index) => navigateBottomNav(context, index);

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
      _showSnackBar('Comprobante seleccionado');
    }
  }

  void _submitRecharge() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      _showSnackBar('Ingresa un monto válido', isError: true);
      return;
    }

    if (_selectedImage == null) {
      _showSnackBar('Sube un comprobante de la transferencia', isError: true);
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
        duration: Duration(seconds: isError ? 3 : 1),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: const Color(0xFFF5C210),
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: const Text(
      'Recargar con QR',
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildQRSection() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF5C210),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: QRCodeWidget(
        qrData: 'RECARGA_$_userId',
        title: 'Código QR de Recarga',
        size: _qrSize,
      ),
    ),
  );

  Widget _buildInstructions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Pasos para recargar:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 12),
      _buildStep('1', 'Escanea el código QR con tu app bancaria'),
      _buildStep('2', 'Realiza la transferencia del monto deseado'),
      _buildStep('3', 'Ingresa el monto y sube el comprobante'),
      _buildStep('4', 'Listo, tu saldo se actualizará inmediatamente'),
    ],
  );

  Widget _buildStep(String number, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5C210),
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
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildAmountField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Monto a recargar',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: '0.00',
          prefixText: 'Bs. ',
          prefixStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _isProcessing ? null : _pickImage,
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedImage != null ? Colors.green : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _selectedImage != null ? Colors.green[50] : Colors.grey[50],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _selectedImage != null
                    ? Icons.check_circle
                    : Icons.cloud_upload_outlined,
                size: _selectedImage != null ? 40 : 32,
                color: _selectedImage != null
                    ? Colors.green[600]
                    : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                _selectedImage != null
                    ? 'Comprobante cargado'
                    : 'Toca para subir comprobante',
                style: TextStyle(
                  color: _selectedImage != null
                      ? Colors.green[600]
                      : Colors.grey[600],
                  fontWeight: _selectedImage != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: _selectedImage != null ? 14 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_selectedImage != null) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'Comprobante seleccionado',
              style: TextStyle(color: Colors.green[600], fontSize: 13),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _buildSubmitButton(bool isLoading) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: _isProcessing || isLoading ? null : _submitRecharge,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5C210),
        disabledBackgroundColor: Colors.grey[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.black),
              ),
            )
          : const Text(
              'Procesar Recarga',
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
    backgroundColor: Colors.white,
    appBar: _buildAppBar(),
    body: BlocListener<RechargeBloC, RechargeState>(
      listener: (context, state) {
        setState(() => _isProcessing = false);

        if (state is RechargeSubmitted) {
          context.read<WalletBloc>().add(LoadWalletEvent(_userId));
          _showSnackBar(state.message);
          _amountController.clear();
          setState(() => _selectedImage = null);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context, rootNavigator: false).pop();
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
            BlocBuilder<RechargeBloC, RechargeState>(
              builder: (context, state) =>
                  _buildSubmitButton(state is RechargeLoading),
            ),
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
