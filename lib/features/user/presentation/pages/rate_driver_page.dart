import 'package:flutter/material.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/user/domain/services/rating_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// El pasajero califica al chofer al finalizar su viaje — mismo flujo y
/// misma colección `ratings` que ya usa `RatePassengerPage` (chofer→
/// pasajero), reviewer/target son genéricos en `RatingDatasource` para no
/// crear una colección paralela para "el otro sentido" de la calificación.
///
/// 3 pantallas en un solo flujo (estrellas con opción de saltar → motivos
/// rápidos → agradecimiento), sin bloc propio: es un formulario de un solo
/// uso, sin estado que sobreviva la navegación.
class RateDriverPage extends StatefulWidget {
  final String tripId;
  final String driverUid;
  final String passengerUid;

  const RateDriverPage({
    super.key,
    required this.tripId,
    required this.driverUid,
    required this.passengerUid,
  });

  @override
  State<RateDriverPage> createState() => _RateDriverPageState();
}

enum _Step { stars, tags, thanks }

class _RateDriverPageState extends State<RateDriverPage> {
  static const _reasonOptions = [
    'Manejo brusco',
    'No se detiene en la parada',
    'Cobra de más',
    'Unidad en mal estado',
  ];

  _Step _step = _Step.stars;
  int _stars = 0;
  final Set<String> _selectedTags = {};
  bool _submitting = false;

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _step = _Step.thanks);
      return;
    }
    setState(() => _submitting = true);
    try {
      await getIt<RatingService>().submitRating(
        tripId: widget.tripId,
        reviewerUid: widget.passengerUid,
        targetUid: widget.driverUid,
        stars: _stars,
        selectedTags: _selectedTags.toList(),
      );
    } catch (_) {
      // Silencioso a propósito: es una calificación opcional post-viaje, no
      // debe bloquear ni alarmar al pasajero si la escritura falla.
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _step = _Step.thanks;
    });
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Calificar al chofer', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _skip,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.stars => _StarsStep(
                stars: _stars,
                onChanged: (v) => setState(() => _stars = v),
                onSkip: _skip,
                onNext: () => setState(() => _step = _Step.tags),
              ),
            _Step.tags => _TagsStep(
                options: _reasonOptions,
                selected: _selectedTags,
                submitting: _submitting,
                onToggle: (tag) => setState(() {
                  _selectedTags.contains(tag) ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                }),
                onSubmit: _submit,
              ),
            _Step.thanks => _ThanksStep(onDone: () => Navigator.of(context).pop()),
          },
        ),
      ),
    );
  }
}

class _StarsStep extends StatelessWidget {
  final int stars;
  final ValueChanged<int> onChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _StarsStep({
    required this.stars,
    required this.onChanged,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_emotions_outlined, size: 72, color: _amarillo),
        const SizedBox(height: 20),
        const Text(
          '¿Cómo estuvo el chofer en este viaje?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < stars;
            return IconButton(
              iconSize: 40,
              onPressed: () => onChanged(i + 1),
              icon: Icon(
                filled ? Icons.star : Icons.star_border,
                color: _amarillo,
              ),
            );
          }),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: stars == 0 ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amarillo,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onSkip, child: const Text('Saltar')),
      ],
    );
  }
}

class _TagsStep extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final bool submitting;
  final ValueChanged<String> onToggle;
  final VoidCallback onSubmit;

  const _TagsStep({
    required this.options,
    required this.selected,
    required this.submitting,
    required this.onToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reseña al chofer',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '¿Algo que quieras comentar? (opcional)',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 10),
        ...options.map((tag) {
          final isSelected = selected.contains(tag);
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(tag),
            value: isSelected,
            onChanged: (_) => onToggle(tag),
            activeColor: _amarillo,
            checkColor: Colors.black,
          );
        }),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: submitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amarillo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: submitting
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Enviar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _ThanksStep extends StatelessWidget {
  final VoidCallback onDone;

  const _ThanksStep({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.celebration_outlined, size: 80, color: _amarillo),
        const SizedBox(height: 20),
        const Text(
          '¡Gracias por calificar!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amarillo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Listo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
