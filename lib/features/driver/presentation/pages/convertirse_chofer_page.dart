import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/modo_chofer_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/document_upload_section.dart';

class ConvertirseChoferPage extends StatefulWidget {
  const ConvertirseChoferPage({super.key});

  @override
  State<ConvertirseChoferPage> createState() => _ConvertirseChoferPageState();
}

class _ConvertirseChoferPageState extends State<ConvertirseChoferPage> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthLoaded ? authState.user.uid : '';
    context.read<DriverBloc>().add(LoadMyVehicleApplication(_userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Convertirme en chofer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocConsumer<DriverBloc, DriverState>(
        listener: (context, state) {
          // Mismo patrón que RegisterPage tras AuthSuccess: pushReplacement
          // a la pantalla de destino sin dejar que el usuario tenga que
          // volver manualmente.
          if (state is DriverModeActivated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ModoChoferPage()),
            );
          }
          if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DriverLoading ||
              state is DriverInitial ||
              state is DriverModeActivated) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is NoVehicleApplication) {
            return _ApplicationForm(userId: _userId);
          }
          if (state is VehicleApplicationLoaded) {
            return _ApplicationStatus(vehicle: state.vehicle, userId: _userId);
          }
          if (state is DriverError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DriverBloc>()
                          .add(LoadMyVehicleApplication(_userId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC12F),
                      ),
                      child: const Text('Reintentar',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Estado de una solicitud ya enviada ──────────────────────────────────────

class _ApplicationStatus extends StatelessWidget {
  final Vehicle vehicle;
  final String userId;
  const _ApplicationStatus({required this.vehicle, required this.userId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    late final String title;
    late final String subtitle;
    late final IconData icon;
    late final Color color;

    if (vehicle.isApproved) {
      title = '¡Solicitud aprobada!';
      subtitle =
          'Tu vehículo (placa ${vehicle.id}) fue aprobado. Ya puedes activar el modo chofer.';
      icon = Icons.check_circle_outline;
      color = Colors.green;
    } else if (vehicle.isRejected) {
      // TODO(RQ-68): si el equipo pide reenvío de documentos tras un
      // rechazo, agregar un ResubmitVehicleApplicationUseCase siguiendo el
      // mismo patrón que SubmitVehicleApplicationUseCase — fuera de alcance
      // de RQ-68 por ahora.
      title = 'Solicitud rechazada';
      subtitle =
          'Tu solicitud de chofer no fue aprobada. Contacta a soporte para más información.';
      icon = Icons.cancel_outlined;
      color = Colors.red;
    } else {
      title = 'Solicitud en revisión';
      subtitle =
          'Estamos revisando los documentos de tu vehículo. Te avisaremos cuando haya una respuesta.';
      icon = Icons.hourglass_top_outlined;
      color = const Color(0xFFFFC12F);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (vehicle.isApproved) ...[
              const SizedBox(height: 32),
              BlocBuilder<DriverBloc, DriverState>(
                builder: (context, state) {
                  final isLoading = state is DriverLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<DriverBloc>()
                              .add(ActivateDriverMode(userId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC12F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Activar modo chofer',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Formulario de solicitud (vehículo + 5 documentos legales) ──────────────

class _ApplicationForm extends StatefulWidget {
  final String userId;
  const _ApplicationForm({required this.userId});

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  static const _amarillo = Color(0xFFFFC12F);

  final _plateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _lineNumberController = TextEditingController();
  final _internalNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _soatFile;
  File? _vehicleInspectionFile;
  File? _driverLicenseFile;
  File? _municipalOperationCardFile;
  File? _ruatFile;

  @override
  void dispose() {
    _plateController.dispose();
    _vehicleTypeController.dispose();
    _lineNumberController.dispose();
    _internalNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<File?> _pickDocument() async {
    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (result == null) return null;

      final file = File(result.path);
      // Reutiliza el validador ya existente para documentos (mismas reglas
      // que benefit_requests: solo JPG/PNG, máximo 5 MB).
      final error = DocumentUploadSection.validateFile(file);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
          );
        }
        return null;
      }
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar documento: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return null;
    }
  }

  void _submit() {
    if (_plateController.text.trim().isEmpty ||
        _vehicleTypeController.text.trim().isEmpty ||
        _capacityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Completa placa, tipo de vehículo y capacidad'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final capacity = int.tryParse(_capacityController.text.trim());
    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('La capacidad debe ser un número mayor a 0'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (_soatFile == null ||
        _vehicleInspectionFile == null ||
        _driverLicenseFile == null ||
        _municipalOperationCardFile == null ||
        _ruatFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Adjunta los 5 documentos legales'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    context.read<DriverBloc>().add(SubmitVehicleApplication(
          userId: widget.userId,
          plate: _plateController.text.trim(),
          vehicleType: _vehicleTypeController.text.trim(),
          lineNumber: _lineNumberController.text.trim(),
          internalNumber: _internalNumberController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          color: _colorController.text.trim(),
          passengerCapacity: capacity,
          soatFile: _soatFile!,
          vehicleInspectionFile: _vehicleInspectionFile!,
          driverLicenseFile: _driverLicenseFile!,
          municipalOperationCardFile: _municipalOperationCardFile!,
          ruatFile: _ruatFile!,
        ));
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _documentSlot(String label, File? file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: file != null ? _amarillo : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                file != null ? Icons.check_circle : Icons.upload_file_outlined,
                color: file != null ? _amarillo : Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file != null ? '$label ✓' : label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: file != null ? null : Colors.grey.shade700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del vehículo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _field(_plateController, 'Placa'),
          _field(_vehicleTypeController, 'Tipo de vehículo (ej. taxitrufi, micro)'),
          _field(_lineNumberController, 'Línea'),
          _field(_internalNumberController, 'Número interno'),
          _field(_brandController, 'Marca'),
          _field(_modelController, 'Modelo'),
          _field(_colorController, 'Color'),
          _field(_capacityController, 'Capacidad de pasajeros',
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          const Text(
            'Documentos legales',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Solo JPG o PNG • Máximo 5 MB por archivo',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          _documentSlot('SOAT', _soatFile, () async {
            final f = await _pickDocument();
            if (f != null) setState(() => _soatFile = f);
          }),
          _documentSlot('Inspección técnica vehicular', _vehicleInspectionFile,
              () async {
            final f = await _pickDocument();
            if (f != null) setState(() => _vehicleInspectionFile = f);
          }),
          _documentSlot('Licencia de conducir', _driverLicenseFile, () async {
            final f = await _pickDocument();
            if (f != null) setState(() => _driverLicenseFile = f);
          }),
          _documentSlot(
              'Tarjeta de operación municipal', _municipalOperationCardFile,
              () async {
            final f = await _pickDocument();
            if (f != null) setState(() => _municipalOperationCardFile = f);
          }),
          _documentSlot('RUAT', _ruatFile, () async {
            final f = await _pickDocument();
            if (f != null) setState(() => _ruatFile = f);
          }),
          const SizedBox(height: 24),
          BlocBuilder<DriverBloc, DriverState>(
            builder: (context, state) {
              final isLoading = state is DriverLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amarillo,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'Enviar solicitud',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
