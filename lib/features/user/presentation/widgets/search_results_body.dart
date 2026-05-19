import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/widgets/place_prediction_tile.dart';
import 'package:mi_ruta/features/user/presentation/widgets/search_empty_hint.dart';

/// Cuerpo de la pantalla de búsqueda de lugares.
///
/// Muestra la lista de predicciones, una pista de búsqueda vacía, o
/// el mensaje "Sin resultados" según el estado actual.
class SearchResultsBody extends StatelessWidget {
  /// Lista de predicciones provenientes de Places API.
  final List<Map<String, dynamic>> predictions;

  /// Indica si hay una búsqueda en curso.
  final bool isLoading;

  /// Indica si el campo de búsqueda tiene texto escrito.
  final bool hasText;

  /// Callback al seleccionar una predicción.
  final void Function(Map<String, dynamic> prediction) onTap;

  const SearchResultsBody({
    super.key,
    required this.predictions,
    required this.isLoading,
    required this.hasText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty && !isLoading) {
      return hasText
          ? const Center(
              child: Text(
                'Sin resultados',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : const SearchEmptyHint();
    }
    return ListView.separated(
      itemCount: predictions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (_, i) => PlacePredictionTile(
        prediction: predictions[i],
        onTap: () => onTap(predictions[i]),
      ),
    );
  }
}
