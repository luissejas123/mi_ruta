import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/user_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_textfield.dart';

class EditarPerfilPage extends StatefulWidget {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? imageUrl;

  const EditarPerfilPage({
    super.key,
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.imageUrl,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  static const _amarillo = Color(0xFFFFC12F);

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  File? _selectedImage;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: _amarillo,
                child: Icon(Icons.camera_alt, color: Colors.black),
              ),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: _amarillo,
                child: Icon(Icons.photo_library, color: Colors.black),
              ),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String? _validar() {
    if (_nameController.text.trim().isEmpty) {
      return 'El nombre no puede estar vacío';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'El teléfono no puede estar vacío';
    }
    final phoneRegex = RegExp(r'^\d{7,15}$');
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  Future<void> _guardarCambios() async {
    final error = _validar();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    String? newImageUrl;

    if (_selectedImage != null) {
      setState(() => _isUploadingImage = true);
      try {
        final storageService = getIt<StorageService>();
        newImageUrl = await storageService.uploadProfileImage(
          userId: widget.uid,
          imageFile: _selectedImage!,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir foto: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        setState(() => _isUploadingImage = false);
        return;
      }
      setState(() => _isUploadingImage = false);
    }

    final data = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
    };

    if (newImageUrl != null) {
      data['profile_picture_url'] = newImageUrl;
    }

    if (mounted) {
      context.read<UserBloc>().add(
        UpdateUserEvent(uid: widget.uid, data: data),
      );
    }
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: _amarillo,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!) as ImageProvider
                : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ? NetworkImage(widget.imageUrl!)
                    : null,
            child: (_selectedImage == null &&
                    (widget.imageUrl == null || widget.imageUrl!.isEmpty))
                ? Text(
                    widget.fullName.isNotEmpty
                        ? widget.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Perfil actualizado correctamente'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) Navigator.pop(context);
        }
        if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          final isLoading = state is UserLoading || _isUploadingImage;

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: const Text(
                'Editar Perfil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showImageOptions,
                    child: const Text(
                      'Cambiar foto',
                      style: TextStyle(
                        color: _amarillo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nombre Completo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: 'Nombre Completo',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Número de Teléfono',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText: 'Número de teléfono',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _guardarCambios(),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Correo Electrónico',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.38),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.email,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.38),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.26),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El correo electrónico no se puede modificar',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amarillo,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Guardando...',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
