import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_state.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/admin_bottom_navigation_bar.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

class AdminCreateAdminPage extends StatefulWidget {
  const AdminCreateAdminPage({super.key});

  @override
  State<AdminCreateAdminPage> createState() => _AdminCreateAdminPageState();
}

class _AdminCreateAdminPageState extends State<AdminCreateAdminPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _governmentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureAdminPassword = true;
  String? _errorLocal;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _governmentIdController.dispose();
    _phoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  String? _validar() {
    if (_nameController.text.trim().isEmpty) {
      return 'Ingresa el nombre completo';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Ingresa el correo del nuevo administrador';
    }
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    if (_passwordController.text.isEmpty) {
      return 'Ingresa una contraseña para el nuevo administrador';
    }
    if (_passwordController.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_passwordController.text != _confirmController.text) {
      return 'Las contraseñas no coinciden';
    }
    if (_adminPasswordController.text.isEmpty) {
      return 'Ingresa tu contraseña actual para restaurar tu sesión';
    }
    return null;
  }

  void _crear() {
    final error = _validar();
    if (error != null) {
      setState(() => _errorLocal = error);
      return;
    }
    setState(() => _errorLocal = null);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) {
      setState(() => _errorLocal = 'Sesión no válida. Vuelve a iniciar sesión.');
      return;
    }

    context.read<AdminPrivilegesBloc>().add(
      CreateAdminAccountEvent(
        adminEmail: authState.user.email,
        adminPassword: _adminPasswordController.text,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        governmentId: _governmentIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo administrador'),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminPrivilegesBloc, AdminPrivilegesState>(
        listener: (context, state) {
          if (state is AdminPrivilegesSuccess && context.mounted) {
            Navigator.of(context).pop(true);
          }
          if (state is AdminPrivilegesError && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AdminPrivilegesLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos del nuevo administrador',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña (mín. 6 caracteres) *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _governmentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Carnet de identidad',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Seguridad',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _adminPasswordController,
                  obscureText: _obscureAdminPassword,
                  decoration: InputDecoration(
                    labelText: 'Tu contraseña actual *',
                    prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureAdminPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureAdminPassword = !_obscureAdminPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Al crear la cuenta tu sesión se restaura automáticamente.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (_errorLocal != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorLocal!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC12F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : _crear,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'CREAR ADMINISTRADOR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(
        currentIndex: 0,
      ),
    );
  }
}
