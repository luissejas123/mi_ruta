import 'package:mi_ruta/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Pantalla vacía mostrada cuando el campo de búsqueda no tiene texto.
class SearchEmptyHint extends StatelessWidget {
  const SearchEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Color(0xFFDDDDDD)),
          SizedBox(height: 12),
          Text(
            'Escribe una dirección o lugar',
            style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
