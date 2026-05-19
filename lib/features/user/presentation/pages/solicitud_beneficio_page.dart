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
  int _currentNavIndex = 1;
  String? _selectedBenefitType;
  final List<File> _selectedDocuments = [];
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  void _onNavTap(int index) {
    navigateBottomNav(context, index);
  }

  Future<void> _pickDocument() async {
    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (result != null) {
        setState(() {
          _selectedDocuments.add(File(result.path));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento agregado: ${result.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar documento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _selectedDocuments.removeAt(index);
    });

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
        const SnackBar(
          content: Text('Por favor selecciona un tipo de beneficio'),
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una descripción')),
      );
      return;
    }

    if (_selectedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un documento'),
        ),
      );
      return;
    }

    final userId = _getUserIdFromContext();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener tu información')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<BenefitRequestBLoC>().add(
      SubmitBenefitRequestEvent(
        userId: userId,
        benefitType: _selectedBenefitType!,
        description: _descriptionController.text,
        documentFiles: _selectedDocuments,
      ),
    );
  }

  String? _getUserIdFromContext() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      return authState.user.uid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Solicitud de Beneficio',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: BlocListener<BenefitRequestBLoC, BenefitRequestState>(
        listener: (context, state) {
          if (state is BenefitRequestSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          } else if (state is BenefitRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );

            setState(() {
              _isSubmitting = false;
            });
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de beneficio
                const Text(
                  'Tipo de Beneficio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    BenefitTypeButton(
                      label: 'Estudiante',
                      isSelected: _selectedBenefitType == 'student',
                      onTap: () =>
                          setState(() => _selectedBenefitType = 'student'),
                    ),
                    const SizedBox(height: 12),
                    BenefitTypeButton(
                      label: 'Universitario',
                      isSelected: _selectedBenefitType == 'university',
                      onTap: () =>
                          setState(() => _selectedBenefitType = 'university'),
                    ),
                    const SizedBox(height: 12),
                    BenefitTypeButton(
                      label: 'Adulto mayor',
                      isSelected: _selectedBenefitType == 'senior',
                      onTap: () =>
                          setState(() => _selectedBenefitType = 'senior'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Descripción
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
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Documentos
                const Text(
                  'Documentos adjuntos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DocumentUploadSection(
                  isSubmitting: _isSubmitting,
                  documents: _selectedDocuments,
                  onAddDocument: _pickDocument,
                  onRemoveDocument: _removeDocument,
                ),
                const SizedBox(height: 32),

                // Botón enviar
                BlocBuilder<BenefitRequestBLoC, BenefitRequestState>(
                  builder: (context, state) {
                    final isLoading = state is BenefitRequestLoading;

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitBenefitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isLoading
                              ? 'Enviando solicitud...'
                              : 'Enviar solicitud',
                          style: const TextStyle(
                            color: Colors.white,
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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
