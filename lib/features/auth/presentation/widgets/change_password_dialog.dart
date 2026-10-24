import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_state.dart';

/// Muestra el diálogo de cambio de contraseña del usuario autenticado.
/// En éxito cierra el diálogo y muestra un SnackBar verde.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final message = await showDialog<String>(
    context: context,
    builder: (context) => BlocProvider.value(
      value: getIt<ChangePasswordBloc>(),
      child: const ChangePasswordDialog(),
    ),
  );
  if (message != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  static const _amarillo = Color(0xFFFFC12F);

  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  String? _errorLocal;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  String? _validar() {
    if (_actualController.text.isEmpty) {
      return 'Ingresa tu contraseña actual';
    }
    if (_nuevaController.text.isEmpty || _confirmarController.text.isEmpty) {
      return 'Completa ambos campos';
    }
    if (_nuevaController.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_nuevaController.text != _confirmarController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _guardar(ChangePasswordBloc bloc) {
    final error = _validar();
    if (error != null) {
      setState(() => _errorLocal = error);
      return;
    }
    setState(() => _errorLocal = null);
    bloc.add(
      ChangePasswordEventSubmit(
        currentPassword: _actualController.text,
        newPassword: _nuevaController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordSuccess) {
          Navigator.of(context).pop(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ChangePasswordLoading;
        final errorRemote = state is ChangePasswordError ? state.message : null;

        return AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _actualController,
                  obscureText: _obscureActual,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureActual
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureActual = !_obscureActual),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nuevaController,
                  obscureText: _obscureNueva,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNueva
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNueva = !_obscureNueva),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmarController,
                  obscureText: _obscureConfirmar,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmar
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmar = !_obscureConfirmar,
                      ),
                    ),
                  ),
                ),
                if (_errorLocal != null || errorRemote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorLocal ?? errorRemote!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _guardar(context.read<ChangePasswordBloc>()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarillo,
                foregroundColor: Colors.black,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        );
      },
    );
  }
}
