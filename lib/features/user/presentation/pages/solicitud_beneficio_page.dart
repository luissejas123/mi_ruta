import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/benefit_request_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/benefit_type_button.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/document_upload_section.dart';

class SolicitudBeneficioPage extends StatefulWidget {
  const SolicitudBeneficioPage({super.key});

  @override
  State<SolicitudBeneficioPage> createState() => _SolicitudBeneficioPageState();
}

class _SolicitudBeneficioPageState extends State<SolicitudBeneficioPage> {
  static const _amarillo = Color(0xFFFFC12F);
  final int _currentNavIndex = 1;
  String? _selectedBenefitType;
  final List<File> _selectedDocuments = [];
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

  Future<void> _pickDocument() async {
    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (result == null) return;

      final file = File(result.path);
      final validationError = DocumentUploadSection.validateFile(file);
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(validationError)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      setState(() => _selectedDocuments.add(file));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Documento agregado: ${result.name}'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar documento: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() => _selectedDocuments.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Documento removido'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitBenefitRequest() async {
    if (_selectedBenefitType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona un tipo de beneficio'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor ingresa una descripción'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (_selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona al menos un documento'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final userId = _getUserIdFromContext();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo obtener tu información'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    context.read<BenefitRequestBLoC>().add(
      SubmitBenefitRequestEvent(
        userId: userId,
        benefitType: _selectedBenefitType!,
        description: _descriptionController.text.trim(),
        documentFiles: _selectedDocuments,
      ),
    );
  }

  String? _getUserIdFromContext() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) return authState.user.uid;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Solicitud de Beneficio',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocListener<BenefitRequestBLoC, BenefitRequestState>(
        listener: (context, state) {
          if (state is BenefitRequestSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green.shade700,
              ),
            );
            final navigator = Navigator.of(context);
            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted) return;
              navigator.pop();
            });
          } else if (state is BenefitRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
            setState(() => _isSubmitting = false);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de Beneficio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                BenefitTypeButton(
                  label: 'Estudiante',
                  isSelected: _selectedBenefitType == 'student',
                  onTap: () => setState(() => _selectedBenefitType = 'student'),
                ),
                const SizedBox(height: 12),
                BenefitTypeButton(
                  label: 'Universitario',
                  isSelected: _selectedBenefitType == 'university',
                  onTap: () => setState(() => _selectedBenefitType = 'university'),
                ),
                const SizedBox(height: 12),
                BenefitTypeButton(
                  label: 'Adulto mayor',
                  isSelected: _selectedBenefitType == 'senior',
                  onTap: () => setState(() => _selectedBenefitType = 'senior'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Descripción de tu solicitud',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe por qué necesitas este beneficio...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _amarillo,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Documentos adjuntos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solo JPG o PNG • Máximo 5 MB por archivo',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                DocumentUploadSection(
                  isSubmitting: _isSubmitting,
                  documents: _selectedDocuments,
                  onAddDocument: _pickDocument,
                  onRemoveDocument: _removeDocument,
                ),
                const SizedBox(height: 32),
                BlocBuilder<BenefitRequestBLoC, BenefitRequestState>(
                  builder: (context, state) {
                    final isLoading = state is BenefitRequestLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitBenefitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amarillo,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLoading ? 'Enviando...' : 'Enviar solicitud',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
