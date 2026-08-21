import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/tickeador_operations_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_state.dart';

class TickeadorOperationRegisterPage extends StatelessWidget {
  const TickeadorOperationRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TickeadorOperationsBloc(service: getIt<TickeadorOperationsService>()),
      child: const _TickeadorOperationRegisterView(),
    );
  }
}

class _TickeadorOperationRegisterView extends StatefulWidget {
  const _TickeadorOperationRegisterView();

  @override
  State<_TickeadorOperationRegisterView> createState() =>
      _TickeadorOperationRegisterViewState();
}

class _TickeadorOperationRegisterViewState
    extends State<_TickeadorOperationRegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _stationController = TextEditingController();
  final _lineController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _driverController = TextEditingController();
  final _passengerController = TextEditingController();
  final _capacityController = TextEditingController();
  String _logType = 'departure';

  @override
  void dispose() {
    _stationController.dispose();
    _lineController.dispose();
    _vehicleController.dispose();
    _driverController.dispose();
    _passengerController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) return;

    context.read<TickeadorOperationsBloc>().add(
      RegisterTickeadorOperation(
        tickeadorId: authState.user.uid,
        stationName: _stationController.text,
        lineId: _lineController.text,
        logType: _logType,
        vehiclePlate: _vehicleController.text,
        driverId: _driverController.text,
        passengerCount: int.tryParse(_passengerController.text) ?? 0,
        maxCapacity: int.tryParse(_capacityController.text) ?? 0,
      ),
    );
  }

  String? _optionalNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (int.tryParse(value.trim()) == null) return 'Ingrese un número válido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TickeadorOperationsBloc, TickeadorOperationsState>(
      listener: (context, state) {
        if (state is TickeadorOperationSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operación registrada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
        if (state is TickeadorOperationsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is TickeadorOperationSaving;
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Registrar operación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _logType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de operación',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'departure', child: Text('Salida')),
                    DropdownMenuItem(value: 'arrival', child: Text('Llegada')),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _logType = value);
                        },
                ),
                const SizedBox(height: 14),
                _requiredField(
                  controller: _stationController,
                  label: 'Estación',
                  hint: 'Ej. Terminal Sur',
                ),
                const SizedBox(height: 14),
                _requiredField(
                  controller: _lineController,
                  label: 'Línea',
                  hint: 'Ej. line_138',
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _vehicleController,
                  label: 'Placa del vehículo',
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _driverController,
                  label: 'ID del conductor',
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _passengerController,
                  label: 'Cantidad de pasajeros',
                  keyboardType: TextInputType.number,
                  validator: _optionalNumberValidator,
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _capacityController,
                  label: 'Capacidad máxima',
                  keyboardType: TextInputType.number,
                  validator: _optionalNumberValidator,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _register,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSaving ? 'Guardando...' : 'Registrar operación',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC12F),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _requiredField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return _textField(
      controller: controller,
      label: label,
      hint: hint,
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Este campo es obligatorio'
          : null,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
