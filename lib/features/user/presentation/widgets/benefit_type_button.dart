import 'package:flutter/material.dart';

/// Botón de selección de tipo de beneficio para [SolicitudBeneficioPage].
class BenefitTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BenefitTypeButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFF5C210)
              : Colors.grey.shade200,
          foregroundColor: Colors.black,
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: isSelected
                ? const BorderSide(color: Colors.black, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.black, size: 28),
          ],
        ),
      ),
    );
  }
}
