import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/user/domain/services/storage_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// Documento legal requerido, en el mismo orden que Figma "3.2 Verificar
/// Documentos". La clave coincide exactamente con
/// `VehicleEntity.legalDocumentation` / FIRESTORE_COLLECTIONS_GUIDE.md — no
/// se inventan campos nuevos.
class _RequiredDocument {
  final String key; // sin el sufijo `_url`
  final String label;
  final IconData icon;

  const _RequiredDocument(this.key, this.label, this.icon);
}

const _requiredDocuments = [
  _RequiredDocument('driver_license', 'Licencia de conducir', Icons.badge_outlined),
  _RequiredDocument('vehicle_inspection', 'Inspección técnica vehicular', Icons.fact_check_outlined),
  _RequiredDocument('soat', 'SOAT', Icons.shield_outlined),
  _RequiredDocument('ruat', 'RUAT', Icons.apartment_outlined),
  _RequiredDocument('municipal_operation_card', 'Tarjeta de operación municipal', Icons.description_outlined),
];

const _vehicleTypes = ['Bus', 'Micro', 'Taxitrufi', 'Otro'];

/// "Registrarme como chofer" (Figma 3.1/3.2): a diferencia del diálogo
/// anterior, aquí se registra la unidad (tipo, datos, documentos) *antes* de
/// que el dirigente apruebe — la solicitud y la unidad quedan vinculadas por
/// `owner_uid`, y ambas se revisan juntas en `DriverApprovalPage`. Una vez
/// aprobado, el chofer puede agregar más unidades desde su panel.
class SolicitudChoferPage extends StatefulWidget {
  final String uid;

  /// `true` cuando la usa un chofer ya aprobado para registrar una unidad
  /// adicional desde su panel — en ese caso no se vuelve a enviar
  /// `driver_request` (ya está aprobada, no hay nada que solicitar de nuevo).
  final bool isAdditionalUnit;

  const SolicitudChoferPage({
    super.key,
    required this.uid,
    this.isAdditionalUnit = false,
  });

  @override
  State<SolicitudChoferPage> createState() => _SolicitudChoferPageState();
}

class _SolicitudChoferPageState extends State<SolicitudChoferPage> {
  final _picker = ImagePicker();
  final _plateCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  final _internalNumberCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  String _vehicleType = _vehicleTypes.first;
  final Map<String, File> _documents = {};
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _lineCtrl.dispose();
    _internalNumberCtrl.dispose();
    _brandCtrl.dispose();
    _colorCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  bool get _formComplete =>
      _plateCtrl.text.trim().isNotEmpty &&
      _lineCtrl.text.trim().isNotEmpty &&
      _internalNumberCtrl.text.trim().isNotEmpty &&
      _brandCtrl.text.trim().isNotEmpty &&
      _colorCtrl.text.trim().isNotEmpty &&
      int.tryParse(_capacityCtrl.text.trim()) != null &&
      _documents.length == _requiredDocuments.length;

  Future<void> _pickDocument(String key) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() {
        _documents[key] = File(picked.path);
        _errorText = null;
      });
    } catch (e) {
      setState(() => _errorText = 'No se pudo capturar la foto: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formComplete) {
      setState(() => _errorText =
          'Completa todos los campos y sube los ${_requiredDocuments.length} documentos.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final plate = _plateCtrl.text.trim().toUpperCase();
      final storage = getIt<StorageService>();

      // Documentos primero: si alguno falla, no se crea una unidad a medias.
      final legalDocumentation = <String, String?>{};
      for (final doc in _requiredDocuments) {
        final file = _documents[doc.key]!;
        final url = await storage.uploadVehicleDocument(
          ownerUid: widget.uid,
          plate: plate,
          docKey: doc.key,
          imageFile: file,
        );
        legalDocumentation['${doc.key}_url'] = url;
      }

      await getIt<DriverService>().registerVehicle(
        ownerUid: widget.uid,
        vehicleType: _vehicleType.toLowerCase(),
        plate: plate,
        lineNumber: _lineCtrl.text.trim(),
        internalNumber: _internalNumberCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        passengerCapacity: int.parse(_capacityCtrl.text.trim()),
        legalDocumentation: legalDocumentation,
      );

      if (!widget.isAdditionalUnit) {
        // driver_request.status = 'pending' — no cambia el role todavía (ver
        // UserManagementDatasource.requestDriverRole). Un chofer ya aprobado
        // que agrega otra unidad no vuelve a pasar por aquí.
        await getIt<UserManagementService>().requestDriverRole(widget.uid);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAdditionalUnit
                ? 'Unidad registrada. Queda en revisión hasta que se apruebe.'
                : 'Solicitud enviada con tu unidad y documentos. '
                    'Te avisaremos cuando el dirigente la apruebe.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = 'No se pudo enviar la solicitud: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdditionalUnit ? 'Agregar unidad' : 'Registrarme como chofer',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registro de unidad',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isAdditionalUnit
                    ? 'Esta unidad queda en revisión del dirigente antes de poder operar con ella.'
                    : 'Se enviará al dirigente de tu línea junto con tu solicitud. '
                        'Tu cuenta sigue siendo de pasajero hasta que se apruebe.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Tipo de unidad'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vehicleTypes.map((type) {
                  final selected = _vehicleType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    selectedColor: _amarillo,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.black : null,
                    ),
                    onSelected: (_) => setState(() => _vehicleType = type),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              _SectionLabel('Datos de la unidad'),
              const SizedBox(height: 10),
              _LabeledField(label: 'Placa del vehículo', controller: _plateCtrl),
              const SizedBox(height: 12),
              _LabeledField(label: 'Línea', controller: _lineCtrl),
              const SizedBox(height: 12),
              _LabeledField(label: 'Número de unidad', controller: _internalNumberCtrl),
              const SizedBox(height: 12),
              _LabeledField(label: 'Marca', controller: _brandCtrl),
              const SizedBox(height: 12),
              _LabeledField(label: 'Color', controller: _colorCtrl),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Capacidad de pasajeros',
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              _SectionLabel('Validación de documentos'),
              const SizedBox(height: 4),
              Text(
                'Envía una foto de los siguientes documentos:',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 12),
              ..._requiredDocuments.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DocumentTile(
                    document: doc,
                    file: _documents[doc.key],
                    onTap: () => _pickDocument(doc.key),
                  ),
                ),
              ),
              Text(
                'Completados: ${_documents.length}/${_requiredDocuments.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amarillo,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          widget.isAdditionalUnit ? 'Registrar unidad' : 'Enviar solicitud',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final _RequiredDocument document;
  final File? file;
  final VoidCallback onTap;

  const _DocumentTile({required this.document, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uploaded = file != null;
    return Material(
      color: uploaded ? Colors.green.withValues(alpha: 0.15) : _amarillo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(document.icon, color: Colors.black87, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  document.label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                ),
              ),
              Icon(
                uploaded ? Icons.check_circle : Icons.camera_alt_outlined,
                color: uploaded ? Colors.green.shade700 : Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
