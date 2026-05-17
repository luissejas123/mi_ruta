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
  bool _hasNavigatedToRecovery = false;

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
          if (!_hasNavigatedToRecovery) {
            _hasNavigatedToRecovery = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: RecuperarAccesoPage(
                      initialEmail: _emailController.text,
                    ),
                  ),
                ),
              );
            });
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
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
                      children: [
                        const Text(
                          'MiRuta',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                          icon: Icons.alternate_email,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          hintText: 'Ingresar Carnet de Identidad',
                          icon: Icons.badge_outlined,
                          controller: _idController,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          hintText: 'Numero de telefono',
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          hintText: 'Correo Electrónico',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          hintText: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 30),
                        if (state is AuthLoading)
                          const CircularProgressIndicator()
                        else
                          RegisterButton(
                            text: 'Registrarse',
                            onPressed: () {
                              if (_nameController.text.isEmpty ||
                                  _idController.text.isEmpty ||
                                  _phoneController.text.isEmpty ||
                                  _emailController.text.isEmpty ||
                                  _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor completa todos los campos',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                _hasNavigatedToRecovery = false;
                                context.read<AuthBloc>().add(
                                  RegisterEvent(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    fullName: _nameController.text,
                                    governmentId: _idController.text,
                                    phoneNumber: _phoneController.text,
                                    role: 'user',
                                  ),
                                );
                              }
                            },
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
