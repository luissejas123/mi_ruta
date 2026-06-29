import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/insertar_correo_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/registration_success_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_textfield.dart';
import 'package:mi_ruta/features/user/presentation/widgets/register_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validar() {
    if (_nameController.text.trim().isEmpty ||
        _idController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      return 'Por favor completa todos los campos';
    }
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    if (_passwordController.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    final phoneRegex = RegExp(r'^\d{7,15}$');
    if (!phoneRegex.hasMatch(_phoneController.text.trim())) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  void _registrar() {
    final error = _validar();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(
      RegisterEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        governmentId: _idController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: 'user',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrationSuccessPage(
                fullName: _nameController.text.trim(),
              ),
            ),
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'MiRuta',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      CustomTextField(
                        hintText: 'Nombre Completo',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        hintText: 'Carnet de Identidad',
                        icon: Icons.badge_outlined,
                        controller: _idController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        hintText: 'Número de teléfono',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        hintText: 'Correo Electrónico',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        hintText: 'Contraseña (mín. 6 caracteres)',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _registrar(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (state is AuthLoading)
                        const CircularProgressIndicator(
                          color: Color(0xFFFFC12F),
                        )
                      else
                        RegisterButton(
                          text: 'Registrarse',
                          onPressed: _registrar,
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<AuthBloc>(),
                                child: const InsertarCorreoPage(),
                              ),
                            ),
                          );
                        },
                        child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
