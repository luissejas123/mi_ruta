import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/recuperar_acceso_page.dart';
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
  late TextEditingController _confirmPasswordController;

  // Map para almacenar errores de validación
  Map<String, String> _fieldErrors = {};
  bool _isFormValid = false;
  bool _hasNavigatedToRecovery = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Agregar listeners para validación en tiempo real
    _nameController.addListener(() => _validateField('fullName', _nameController.text));
    _idController.addListener(() => _validateField('governmentId', _idController.text));
    _phoneController.addListener(() => _validateField('phoneNumber', _phoneController.text));
    _emailController.addListener(() => _validateField('email', _emailController.text));
    _passwordController.addListener(() => _validateField('password', _passwordController.text));
    _confirmPasswordController.addListener(
      () => _validateField('confirmPassword', _confirmPasswordController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Dispara validación de un campo individual
  void _validateField(String fieldName, String value) {
    context.read<AuthBloc>().add(
      ValidateRegistrationFieldEvent(
        fieldName: fieldName,
        fieldValue: value,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }

  /// Intenta registrar el usuario
  void _attemptRegister() {
    _hasNavigatedToRecovery = false;
    context.read<AuthBloc>().add(
      RegisterEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        governmentId: _idController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        confirmPassword: _confirmPasswordController.text,
        role: 'user',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RegistrationSuccessPage(
                  fullName: state.user.fullName,
                ),
              ),
            );
          });
        } else if (state is AuthError) {
          // Mostrar error general
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Actualizar errores cuando el estado es de validación
          if (state is AuthValidationError) {
            _fieldErrors = state.fieldErrors;
            _isFormValid = state.isFormValid;
          }

          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: const Color(0xFFE5E5E5),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Título
                        const Text(
                          'MiRuta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Crear cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Campo: Nombre Completo
                        CustomTextField(
                          hintText: 'Nombre Completo',
                          icon: Icons.person_outline,
                          controller: _nameController,
                          keyboardType: TextInputType.text,
                          errorText: _fieldErrors['fullName'],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Campo: Carnet de Identidad
                        CustomTextField(
                          hintText: 'Ingresar Carnet de Identidad',
                          icon: Icons.badge_outlined,
                          controller: _idController,
                          keyboardType: TextInputType.number,
                          errorText: _fieldErrors['governmentId'],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Campo: Teléfono
                        CustomTextField(
                          hintText: 'Número de teléfono',
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          errorText: _fieldErrors['phoneNumber'],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Campo: Email
                        CustomTextField(
                          hintText: 'Correo Electrónico',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _fieldErrors['email'],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Campo: Contraseña
                        CustomTextField(
                          hintText: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          controller: _passwordController,
                          errorText: _fieldErrors['password'],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Campo: Confirmar Contraseña
                        CustomTextField(
                          hintText: 'Confirmar Contraseña',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          controller: _confirmPasswordController,
                          errorText: _fieldErrors['confirmPassword'],
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 30),

                        // Botón de Registro
                        if (isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          RegisterButton(
                            text: 'Crear cuenta',
                            onPressed: _isFormValid ? _attemptRegister : null,
                          ),

                        // Mensaje de validación si hay errores
                        if (!_isFormValid && _fieldErrors.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'Por favor revisa los errores antes de continuar',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
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

